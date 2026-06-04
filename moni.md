# Analyse de refonte du monitoring

> Document d'analyse exclusivement. Aucune modification du SQL existant, aucune implémentation Logstash ou Python. Le ton est volontairement direct.

---

## 1. Contexte actuel

Le monitoring repose sur un unique fichier `mini_monitoring.sql` exécuté en production environ toutes les 15 minutes via UC4 / Automic, sur les bases Oracle Avaloq (`AVALIV*`, `AVAPRE`, `AVAMICC`).

Le script est un **bloc PL/SQL anonyme** (~19 900 lignes) lancé via SQL*Plus avec spool vers `/sources/logs/avaloq_db_monitoring_${FDB_NAME}.log`. À chaque exécution :

- Il déclare des dizaines de variables d'état globales (CLOB HTML, listes de mails par équipe, compteurs).
- Il définit ~214 fonctions et procédures locales (utilitaires de dates, formatage HTML/JSON, envoi de mail, et l'ensemble des checks).
- Il exécute séquentiellement ~5 grandes sections (`Availability`, `Response Time`, `System`, `European Functional`, `Asian Functional`).
- Il produit **deux sorties** :
  1. Un **e-mail HTML dynamique** envoyé via `UTL_SMTP` (destinataires construits au fil des checks).
  2. Un **flux JSON** écrit dans le spool, ingéré ensuite par Elastic (index `avaloq_db_monitoring`).

Documentation embarquée minimale, presque exclusivement sous forme de commentaires d'en-tête `--Author / --Date`.

## 2. Constats sur `mini_monitoring.sql`

**Volume et structure**

- ~19 923 lignes, ~800 KB, un seul bloc `DECLARE ... BEGIN ... END;`
- 214 routines locales déclarées : ~67 fonctions `cond_<...>` (conditions d'activation des checks), ~150 procédures `check_<...>` et utilitaires (dates, mailing, HTML, JSON).
- 219 appels à `write_query(...)` (l'API standard d'enregistrement d'un résultat de check). C'est l'**ordre de grandeur réel** du nombre de checks effectifs, cohérent avec l'estimation "150 à 200" du brief.
- 5 sections principales (`Availability`, `Response Time`, `System`, `European Functional`, `Asian Functional`) et ~13 sous-sections (`Rates`, `Stock Exchange`, `Payment`, `Treasury settlement`, `Pillars`, `BGPs/PRCQs/messages`, `Security`, etc.).

**Patron d'un check**

Chaque check suit le même squelette :

```
FUNCTION cond_xxx RETURN BOOLEAN  -- décide si on exécute (plage horaire, jour ouvré, BU active…)
PROCEDURE check_xxx               -- exécute la/les requêtes SQL, compare au seuil
                                  -- pousse vers p_html_pool, ajoute des mails, appelle write_query
```

Puis dans le `BEGIN` final :

```
IF cond_xxx OR c_force_active THEN
    DBMS_APPLICATION_INFO.SET_ACTION('CHECK_XXX');
    check_xxx;
END IF;
```

**Sévérités** : 4 niveaux numériques (`c_none_p=0`, `c_major_p=1`, `c_blocking_p=2`, `c_sys_blocking_p=3`), portés ensuite via des placeholders remplacés en fin d'exécution (`replace_section_severity`). Mécanisme astucieux mais qui rend la lecture du code difficile.

**Sorties**

- `write_query_html` → CLOB `p_html_pool` (mail final).
- `write_query_json` → CLOB `l_json_temp`, dump dans le spool, ingéré par Elastic via Filebeat ou équivalent. Le schéma est déjà partiellement ECS (`@timestamp`, `event.outcome`, `event.severity`, `event.duration`, `service.environment`, `service.name`) + namespace propre `sebp.products.avaloq_db_monitoring.*`.

**Gestion d'exceptions** : chaque check encapsule son `EXCEPTION WHEN OTHERS` qui appelle `handle_check_exception`. Bon réflexe — un check qui plante ne tue pas le script. Mais ça masque potentiellement des erreurs récurrentes.

**Mail final** : un seul `UTL_SMTP` à la fin, avec destinataires accumulés. La logique métier "à qui s'adresse cette alerte" est dispersée dans le code de chaque check (`p_to := upsert_mails(p_to, ';', l_mail_xxx)`).

**Points préoccupants**

- `c_documentation_path` pointe vers un chemin **UNC Windows** (`\\bdl-lu.oi.bdl.lu\bludata\IT\Commun\Monitoring\Documentation_Files\`). Hard-codé.
- Adresses mail en dur (`relman@blu.bank`, `nicmal2@blu.bank`, `zabbix.errors@blu.bank`, `itsm@blu.bank`).
- `l_db_name LIKE 'AVALIV%'` / `'AVAPRE'` / `'AVAMICC'` dispersé pour décider du comportement.
- Beaucoup de variables `l_text`, `l_nr`, `l_nr2`…`l_nr5` réutilisées entre checks. État partagé non isolé.

## 3. Risques du fonctionnement actuel

1. **Mono-process, mono-fréquence** : 100 % des checks sont contraints à 15 min. Les checks qui devraient tourner à 5 min sont en retard ; ceux qui devraient tourner toutes les 24 h consomment des ressources 96 fois plus que nécessaire.
2. **Mono-transaction logique** : si le bloc plante avant la fin (timeout SMTP, erreur sur une session BU, manque de tablespace temporaire), **aucun JSON n'est spoolé** et donc aucune métrique pour le run.
3. **Couplage présentation / détection** : la logique de "qui prévenir" et de "comment formater" est mêlée à la détection. Toute évolution du destinataire impose de modifier le PL/SQL critique.
4. **Plages horaires dans le code** : exemples : `cond_check_timeout_bgp926` ne renvoie `TRUE` qu'entre 08:00 et 08:20. C'est piloté côté code, pas côté planification. Un décalage d'horloge ou un retard UC4 fait sauter le check sans aucune trace.
5. **Code mort visible** : grands blocs commentés (`cisg_mmkt_rates_t1/t2/t3`, `frs_tafrep_reverse`, `check_cisg_mmkt_rates_cdor_mor` "temporarily suspended : IOR-85872"). Le `/* ... */` se balade pendant des mois.
6. **Difficile à tester** : aucun moyen d'exécuter un check isolé en non-prod sans aussi déclencher l'envoi mail.
7. **Charge concentrée** : tout est exécuté en série, dans la même session, sur le schéma `k`. Un check lent (NPV, asset_eval, FRS TAFREP) pénalise tous les checks suivants.
8. **Visibilité de l'exécution** : `DBMS_APPLICATION_INFO.SET_ACTION` est posé partout (bonne pratique), mais c'est l'unique levier d'observabilité du script lui-même. Aucune métrique sur la durée individuelle des checks autre que `event.duration` dans le JSON — bien mais sous-exploitée.
9. **Risque humain** : 19 900 lignes en bloc anonyme, aucun versioning fonctionnel, modifications historiquement faites en édition directe. Un caractère mal collé peut casser la production.

## 4. Opportunité de split du monitoring

Le découpage par fréquence est **pertinent** et même nécessaire à terme. Aujourd'hui chaque exécution refait l'intégralité des checks, ce qui revient à payer le coût des checks longs (jusqu'à plusieurs minutes potentiellement, NPV, FRS, M2M) pour rien sur 95 % des fréquences.

Cependant le split sur Logstash **expose plusieurs effets de bord** :

- Les variables d'état (compteurs, listes de mails, `g_active_section`) disparaissent. Tout check doit devenir **autonome** : une requête → un document Elastic, sans contexte global.
- Les conditions `cond_xxx` (plages horaires, BU actives, jour ouvré, jour bancaire) doivent être **portées hors PL/SQL**. Soit côté Logstash (filter), soit côté Oracle dans la requête (`WHERE ... AND :now BETWEEN ...`), soit côté Python alerting.
- La logique d'envoi de mail "agrégé" disparaît. C'est une rupture culturelle pour les équipes destinataires qui sont habituées au mail unique.

L'opportunité réelle est donc **autant un projet de rationalisation qu'un projet technique**. Si on porte le mail tel quel à côté, on alourdit sans simplifier.

## 5. Proposition de découpage par fréquence

**Critères de classement** :

| Critère | 5 min | 15 min | 24 h |
|---|---|---|---|
| Impact business si détection retardée d'une heure | Critique (perte de transaction, blocage trading) | Important (alerte exploit, mais récupérable) | Faible (KPI, hygiène) |
| Coût d'exécution de la requête | Faible/moyen | Faible/moyen | Élevé (jointures lourdes, fenêtres longues) |
| Fenêtre de validité métier | Continue ou très courte | Heures ouvrées larges | Une fois par jour suffit |
| Volume d'alertes générées par jour | < 10 | < 100 | quelques unités |

**Candidats 5 minutes** (détection rapide indispensable) :
- `EOD Status`, `Bank date`, `Next today`, `session_level` (section *Availability*) — un dysfonctionnement = blocage total.
- Timeouts BGP (`check_timeout_bgp926`) et files PRCQ en erreur.
- Cotation FX en heures de trading (`check_fx_rates_15`, `check_fx_rates_msg`).
- Checks Singapour/Asie pendant leur fenêtre d'activité.

**Candidats 15 minutes** (équivalent au fonctionnement actuel) :
- Mises à jour de taux (Euribor, SOFR, SARON, STIBOR, SONIA, TONAR, HIBOR, HONIA, SORA, CDOR…).
- Vérifications de paiement (`check_pay_order_locked`, `check_pay_sas_ctrl`, `check_pay_settle_fail`).
- Wait for streaming, mailings, secevt.
- Stock Exchange (volumes, statuts ordres).

**Candidats 24 heures** (lourds, peu critiques, ou cycle quotidien naturel) :
- `check_asset_eval`, `check_frs_tafrep` (gros volumes, fenêtre de calcul = J-1).
- `check_npv_*` (bonds, swaption, fxoption, cf_fair, cf_dirty, cf_eval) — NPV reposent sur des évaluations close-of-business.
- `check_irs_dirty_fair`, `check_irs_fair`, `check_irs_fv_eval`, `check_gen_asset_stord`.
- Vérification cohérence référentiels (Issuer, BPs "Secured!", Message bundle).

**Risques du découpage**

- **Dépendances cachées** : certains checks reposent sur l'ordre d'exécution (`session#.open_session` est appelé dans un check et exploité par les suivants). Le split casse cette hypothèse silencieusement.
- **Variables partagées** : `fx_option_cisg_count`, `g_active_section`, `p_html_pool` — il faudra identifier toutes les utilisations transversales pour ne pas perdre d'information.
- **Régression silencieuse** : un check oublié ou mal classé peut ne plus jamais s'exécuter sans qu'on s'en aperçoive — il n'y aura plus de mail "rassurant" qui confirme que le run s'est passé. Prévoir un **heartbeat par fréquence**.
- **Charge concentrée à la même minute** : si toutes les requêtes 5 min partent au même instant, on se retrouve avec des pics de sessions Oracle. Étaler ou prioriser.

## 6. Nettoyage SQL et code mort potentiel

Le nettoyage est **un préalable, pas un bonus**. Avant tout port vers Logstash :

- **Blocs `/* ... */` à statut "suspendu"** : `check_cisg_mmkt_rates_cdor_mor` ("temporarily suspended at request : IOR-85872"), `cisg_mmkt_rates_t1/t2/t3`, `check_cisg_m2m_acu`. Soit on les remet, soit on les supprime. Le statut "temporaire" depuis X mois est un signal de dette.
- **Variables locales mortes** : `l_nr2..l_nr5`, `l_text2..l_text5`, `l_html_temp2` — manifestement des restes de refactos. À tracer et supprimer.
- **Fonctions utilitaires redondantes** : `get_previous_day`, `get_previous_day_b`, `get_next_day`, `is_friday/saturday/sunday/thursday/weekend` — beaucoup de variantes proches. Bonne candidat à mutualiser dans un package Oracle.
- **Commentaires d'en-tête datés** : on trouve des `--Date:11/02/2015` qui n'ont jamais bougé. Ils sont précieux pour l'historique mais devraient migrer vers Git.
- **Checks avec seuils en dur sans documentation** : `IF l_cnt_wait > 150 THEN ...` — pourquoi 150 ? Il faut extraire ces seuils dans une table de paramétrage ou un fichier de configuration.

À mesurer avant tout nettoyage : **fréquence réelle de déclenchement de chaque check** (`event.outcome=success/failure` par `check_name`) sur 30 jours d'index Elastic. Un check qui n'a jamais alerté en 1 an n'est pas forcément à supprimer (il peut couvrir un cas rare et grave), mais il mérite une revue explicite.

## 7. Fonctions et procédures à sortir en package Oracle

**Avis** : oui pour les utilitaires, **prudence** pour les checks eux-mêmes.

**Bons candidats package** (`PKG_MONITORING_UTIL`) :

- Fonctions de date / calendrier : `get_current_day`, `get_previous_day`, `get_next_day`, `is_day_off`, `is_holiday`, `is_bank_day_off`, `is_night`, `is_weekend`, `is_friday/saturday/sunday/thursday`, `is_day_switch_done`, `timestamp_diff`, `timestamp_diff_minutes`, `interval_to_seconds`.
- Helpers BU / mails : `getBuName`, `getOrderBu`, `getMailByBu`, `getMailOfUserWhoMadeLastAction`, `appendMails`, `upsert_mails`, `remove_mail`.
- Évaluation et conversion : `eval_check_result`, `decode_severity`, `current_timestamp_ms`, `parse_cur_xml_tag_value`, `parse_cur_xml_tag_multi_value`.

**Avantages**
- Mutualisation immédiate entre tous les pipelines Logstash (pas de duplication).
- Compilation + signature → erreurs détectées au déploiement, pas au runtime.
- Statistiques d'utilisation (`v$pgastat`, `dba_objects.last_ddl_time`) disponibles.
- Tests unitaires PL/SQL possibles (utPLSQL).

**Risques à anticiper**
- **Déploiement / rollback** : un package en prod nécessite un process change. Aujourd'hui le SQL est livré en monolithe.
- **Versioning** : `dba_source` vs Git ; il faut une discipline de release.
- **Droits Oracle** : grants à donner au user qui exécute Logstash JDBC (probablement différent de `k`). À cadrer avec DBA.
- **Dépendance dure** : si le package change de signature, tous les pipelines cassent. Plus contraignant qu'un script autonome.

**Avis sur les checks** : sortir aussi les `check_xxx` en package est tentant ("juste appeler `pkg_monitoring.check_euribor`"), mais c'est **un piège**. Cela revient à reproduire le monolithe dans la base. Préférer : la **requête SQL pure** dans le pipeline Logstash, les **utilitaires** dans le package. La logique de comparaison (seuil, eval_type) remonte côté Logstash/Elastic/Python.

## 8. Architecture cible Logstash

**Avis** : Logstash JDBC est un choix **raisonnable mais pas magique**. Il résout le problème de planification et d'ingestion, pas celui de la logique métier.

**Avantages vs script SQL monolithique**
- Planification native par pipeline (`schedule => "*/5 * * * *"`).
- Une requête = un document = un check, naturellement.
- Reload de pipeline sans redémarrage du service.
- Mort d'un pipeline = isolé, les autres continuent.
- Métriques d'exécution propres (`pipeline.duration`, `events.in/out`, `queue`).

**Limites et points de vigilance JDBC**
- **Une connexion par pipeline** par défaut → multiplier les pipelines = multiplier les sessions Oracle. Cap à fixer avec le DBA.
- `jdbc_paging_enabled` et `jdbc_fetch_size` à régler sur les requêtes qui ramènent du volume.
- `tracking_column` n'est pas utile ici (on ne fait pas du CDC, on fait du polling d'état) — risque de mauvaise configuration.
- Statement timeout : Logstash JDBC n'a pas de vrai timeout côté pipeline. Une requête bloquée bloque le worker. À cadrer via Oracle (`SESSION` `resource_limit` + profile + `IDLE_TIME`).
- Pas de "session avalq" (`session#.open_session(i_bu_id => X)`) côté JDBC simple. Si certains checks dépendent de cette ouverture, soit on l'ajoute en `statement` préfixe, soit on passe par une procédure stockée.
- Encodage des CLOB : attention si on ramène du texte long (messages d'erreur, queries).

**Organisation des pipelines**
- 1 répertoire par fréquence : `pipelines.d/5min/`, `pipelines.d/15min/`, `pipelines.d/daily/`.
- 1 fichier `.conf` par groupe fonctionnel (`availability.conf`, `rates_eur.conf`, `rates_asia.conf`, `payments.conf`, `frs.conf`…). Pas 1 pipeline par check (coût opérationnel énorme).
- Tag systématique : `check_group`, `frequency`, `severity` (cf. section 9).

**Charge sur la base**
- Risque réel : si on lance 50 checks toutes les 5 minutes en parallèle, c'est 50 sessions concurrentes contre 1 session séquentielle aujourd'hui. À l'inverse, des sessions courtes valent souvent mieux qu'une longue.
- Étaler les pipelines (offset cron) ou utiliser un pipeline coordinateur.
- Prévoir une supervision de `v$session` par `MODULE='AVALOQ_DB_MONITORING'`.

**Éléments à mesurer en continu**
- Durée d'exécution par check (déjà disponible via `event.duration`).
- Timeout / abandons.
- Erreurs SQL (compter `event.outcome:unknown`).
- Volume indexé (docs/min par fréquence).
- Retard d'exécution (`@timestamp` du document vs heure planifiée).
- Heartbeat : un check trivial `SELECT SYSDATE FROM dual` par pipeline pour distinguer "rien à signaler" de "pipeline mort".

## 9. Modèle de données Elastic recommandé

Le JSON actuel a déjà 80 % de ce qu'il faut. Il est cohérent avec ECS, ce qui est un atout. À conserver et compléter :

**Champs ECS standards à garder**
- `@timestamp`, `event.start`, `event.end`, `event.duration` (ns), `event.outcome` (`success|failure|unknown`), `event.severity` (numérique), `event.kind`, `event.action`.
- `service.name`, `service.environment` (`PRD|PRE|INT|DEV`).
- `data_stream.dataset`.

**Champs métier à standardiser sous un namespace propre** (`monitoring.*` ou conserver `sebp.products.avaloq_db_monitoring.*`)
- `check_name` (slug stable, ex: `fx_rates_15`)
- `check_title` (libellé lisible)
- `check_group` (`availability`, `response_time`, `system`, `rates_eur`, `rates_asia`, `payments`, `treasury`, `npv`, `frs`, `messaging`, `security`...)
- `severity` (texte : `none|major|blocking|sys_blocking`) + `severity_num`
- `status` (`ok|nok`)
- `value` (résultat numérique ou texte normalisé)
- `threshold` (seuil attendu)
- `eval_type` (`=`, `<=`, `>=`, `between`, etc.)
- `message` (libellé d'alerte humain)
- `frequency` (`5m|15m|1d`)
- `source` (`logstash|sqlplus_legacy` pendant la coexistence)
- `run_id` (déjà présent : `g_execution_id`)
- `bu_id`, `desk`, `team` (déjà partiellement présents)
- `database` (déjà présent)

**Nomenclature des checks**

Indispensable. Un check doit avoir un **identifiant stable** (`check_name`) jamais traduit, jamais changé. Le libellé peut bouger, l'ID non. Sinon l'historique des alertes devient inexploitable. Aujourd'hui le champ `i_check` mélange description et clé — à séparer.

**Risques si documents hétérogènes**
- Mapping conflicts à l'indexation (un champ `value` parfois numérique parfois texte → champ rejeté).
- Tableaux de bord cassés à la moindre évolution.
- Règles d'alerte difficiles à généraliser (chaque check = sa règle).
- Coût d'indexation × 10 si on multiplie les champs dynamiques.

Recommandation forte : **publier un mapping explicite**, valider avec `index template`, et casser le build d'un pipeline qui ne respecte pas le schéma.

## 10. Alerting Python sur Elastic

**Avis** : faisable et raisonnable **à condition** de ne pas reconstruire la complexité du script en Python.

**Responsabilités possibles du moteur Python**
- Lire l'index `avaloq_db_monitoring` (ou un alias de la dernière heure).
- Appliquer des règles : seuil, nombre d'occurrences consécutives, fenêtre temporelle.
- Router vers les destinataires en fonction de `check_group` / `bu` / `severity`.
- Déduplication / anti-spam (ne pas réémettre une alerte identique toutes les 5 min pendant 4 h).
- Acquittement éventuel (via un index `acks` ou via un système externe ITSM).
- Émettre un mail / Teams / ITSM / Slack.

**Règles à prévoir explicitement**
- Seuil : `severity >= major` (à calibrer).
- Persistance : "K occurrences sur N runs" (évite les flapping).
- Fenêtre de silence (`silence_until`).
- Regroupement : 50 checks en erreur du même groupe → 1 mail "groupe X en panne", pas 50 mails.
- Heartbeat : alerter si **aucun document** depuis X minutes pour un `check_name` donné. C'est l'alerte qu'on a tendance à oublier alors que c'est la plus importante.

**Kibana Alerting comme alternative**
- Avantages : pas de code, intégré à Elastic, règles configurables en UI, supporte les conditions composées et le threshold/EQL.
- Limites : routage fin (équipe par BU, par jour de semaine) est lourd à exprimer en règle Kibana ; intégration ITSM moins flexible ; observability layer commerciale.
- **Avis** : Kibana Alerting suffit pour les règles "génériques" (severity >= blocking et outcome=failure → mail ops). Le moteur Python ne devient pertinent que pour le **routage métier complexe** (mail à la bonne équipe, regroupement par desk, gestion des fenêtres d'activité par BU).

**Approche progressive recommandée**
1. Démarrer avec **Kibana Alerting** sur 5 à 10 règles couvrant 80 % des cas.
2. Identifier ce qui ne tient pas dans une règle Kibana (routage, anti-spam multi-niveaux).
3. Construire un service Python **uniquement** pour ces cas.
4. Ne pas reproduire la fonction `getMailByBu` en Python : la **table de routage** est de la **donnée de configuration**, pas du code.

## 11. Points de vigilance

- **Effet coexistence** : pendant la migration, le SQL et Logstash vont tourner en parallèle. Dédupliquer les alertes (par exemple en mettant le SQL en mode "JSON-only", sans mail) puis débrancher.
- **Dépendance à `session#.open_session`** : à clarifier avec un fonctionnel Avaloq avant tout port. Si certaines requêtes échouent sans contexte session ouvert, il faut soit l'inclure dans la requête, soit passer par une procédure stockée.
- **Heure de référence** : SYSDATE vs `@timestamp` Logstash. Les checks horaires comparent à la base ; Logstash devra utiliser la même horloge.
- **Variables d'agrégation** (`fx_option_cisg_count`) qui produisent un mail global : à porter en règle d'agrégation Elastic.
- **Mail comme source de vérité humaine** : aujourd'hui le mail est l'interface unique du métier. Couper cette interface sans alternative claire = rejet du projet.
- **Documentation embarquée** : les liens `c_documentation_path` vers le partage Windows doivent être portés ou archivés.
- **Identifiants stables** : tous les checks n'ont pas aujourd'hui un identifiant unique propre. À assigner avant le port (sinon dashboards et règles d'alerte ne tiennent pas dans le temps).
- **Comptes / droits** : un compte Logstash dédié avec droits minimaux par schéma. Pas d'utilisation du compte `k` actuel.

## 12. Plan de migration recommandé

**Phase 0 — Mesure (2 à 4 semaines, sans toucher au SQL)**
- Activer un dashboard "comportement actuel" sur l'index existant : durée par check, fréquence d'échec, taux d'erreur, distribution horaire.
- Extraire la liste exhaustive des 200 checks + leur `check_name` actuel + leur sévérité + leur destinataire.
- Identifier les "checks zombies" (jamais déclenchés) et les "checks bruyants" (failure systématique sans action).

**Phase 1 — Pré-requis (4 à 6 semaines)**
- Créer le package Oracle d'utilitaires (sections 7).
- Définir le mapping Elastic final + nomenclature des `check_name`.
- Installer une instance Logstash de référence (non-prod).
- Choisir le moteur d'alerte (Kibana ou Python — décision documentée).
- Définir 2 ou 3 "checks pilotes" représentatifs (1 simple, 1 avec session BU, 1 lourd).

**Phase 2 — Pilote (4 à 6 semaines)**
- Porter les 3 pilotes en Logstash, ingestion dans un index `monitoring-v2`.
- Faire tourner en parallèle du SQL existant pendant 1 mois minimum.
- Comparer les détections : faux positifs, faux négatifs, dérives de timing.
- Adapter le mapping et le moteur d'alerte sur la base du retour.

**Phase 3 — Migration progressive (3 à 6 mois)**
- Migrer par **groupe fonctionnel** (rates, payments, NPV…), pas par fréquence.
- Pour chaque groupe : porter, valider en parallèle 2 à 4 semaines, puis désactiver dans le SQL (commentaire + ticket).
- Maintenir une **revue mensuelle** des écarts SQL/Logstash.

**Phase 4 — Décommissionnement**
- Le SQL n'envoie plus de mail. Il continue à produire le JSON pendant 1 à 2 mois en filet de sécurité.
- Suppression définitive du script et du job UC4.
- Archivage Git du dernier état pour traçabilité historique.

**Critères Go / No-Go entre phases**
- Aucun faux négatif détecté sur la phase pilote.
- Taux de couverture des alertes ≥ 99 % vs SQL.
- Charge Oracle stable ou inférieure.
- Acceptation explicite des équipes destinataires.

## 13. Questions ouvertes

- Qui maintient le script aujourd'hui ? Combien de modifications par mois ? (Indicateur du coût caché.)
- L'index Elastic `avaloq_db_monitoring` est-il déjà exploité par d'autres consommateurs (dashboards, exports, BI) ? Tout changement de schéma cassera ces consommateurs.
- Existe-t-il déjà un standard Logstash / pipelines dans l'organisation ? Si oui, on s'aligne — pas la peine d'inventer.
- Quelle est la politique des DBAs sur l'ajout de packages dans le schéma `k` (schéma standard Avaloq) ? Souvent verrouillé. Peut-être un schéma `MONITORING` dédié.
- Le compte qui exécute le SQL aujourd'hui (probablement un compte privilégié) doit-il être conservé pour Logstash, ou un nouveau compte ?
- L'envoi de mail SMTP via `UTL_SMTP` côté Oracle est-il une obligation réglementaire / sécurité, ou un choix historique ?
- Qui valide les seuils ? Les chiffres en dur (150 timeouts, 15 min, etc.) doivent-ils être versionnés en table ou rester dans le code ?
- Quel est le SLA de détection attendu, par groupe de checks ? Aujourd'hui c'est implicite (15 min) ; après split, il faut le rendre explicite.

## 14. Avis final

La refonte est **pertinente** et même nécessaire à moyen terme. Le script actuel est arrivé au bout de ce qu'on peut raisonnablement maintenir dans un bloc PL/SQL anonyme : 20 000 lignes, 200 checks, mono-fréquence, état global partagé, code mort sédimenté.

**Mais** :

- Le risque principal n'est **pas technique**, il est **humain et opérationnel**. Le mail unique est devenu l'interface du métier. Le casser sans alternative claire revient à perdre la confiance des utilisateurs avant même d'avoir migré.
- Logstash + Elastic + Alerting est une bonne pile, mais elle ne supprime pas la complexité métier : elle la déplace. Sans rationalisation préalable (nomenclature, seuils, routage, code mort), on reproduit le monolithe en Python.
- L'estimation réaliste est de **9 à 15 mois** de bout en bout, avec une phase de coexistence longue. Tout planning sous 6 mois est optimiste.
- Le travail le plus utile à court terme **n'est pas du code** : c'est l'**inventaire** (les 200 checks, leur sévérité, leur destinataire, leur fréquence réellement utile), et la **mesure** (durée, taux d'erreur, occurrences par check). Ce travail est faisable sans toucher au SQL existant.

**Recommandation pragmatique** : ne pas démarrer par Logstash. Démarrer par 4 semaines de mesure sur l'index existant, puis 4 semaines d'inventaire et de nomenclature, puis 2 à 3 pilotes Logstash. Si à ce stade les écarts sont maîtrisés, alors la migration en masse peut être lancée. Si les écarts dérapent, on a investi 3 mois — pas 12 — avant de rebrousser.

L'idée de fond est **bonne**. Le danger est l'**emballement** : la décomposition en pipelines Logstash et la stack Python d'alerting sont des sujets séduisants techniquement, qui peuvent occulter le vrai travail — la connaissance fine des 200 checks et de qui en a besoin.
