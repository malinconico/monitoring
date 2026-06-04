# `last_docs.py` — exécution

Petit utilitaire qui affiche les X derniers documents d'un index Elastic, triés par `@timestamp` décroissant.

## 1. Pré-requis

Python 3.8+ et la lib `requests`.

```bash
cd /Users/nicolas/Documents/GitHub/monitoring

# Optionnel mais recommandé : environnement virtuel isolé
python3 -m venv .venv
source .venv/bin/activate

pip install requests
```

## 2. Renseigner les paramètres

Éditer le haut du script (`last_docs.py`, lignes 11-13) :

```python
ES_URL = "https://elastic.internal:9200"        # URL réelle du cluster
ES_API_KEY = "PUT_YOUR_API_KEY_HERE"            # API key Elastic
ES_VERIFY_TLS = True                            # False si certificat self-signed
```

Format de l'API key : la chaîne **base64** retournée par Elastic (champ `encoded` de la réponse `POST /_security/api_key`), pas le couple `id:secret` brut.

Création de l'API key côté Elastic (à faire une fois par l'admin) :

```json
POST /_security/api_key
{
  "name": "monitoring-reader",
  "expiration": "90d",
  "role_descriptors": {
    "monitoring_reader": {
      "indices": [{
        "names": ["avaloq_db_monitoring*", ".ds-avaloq_db_monitoring*"],
        "privileges": ["read", "view_index_metadata"]
      }]
    }
  }
}
```

## 3. Lancer

```bash
# Defaults : index avaloq_db_monitoring*, 10 documents
./last_docs.py

# Index et nombre custom
./last_docs.py -i logs-app-prod -n 25

# Si le script n'est pas exécutable
python3 last_docs.py -i logs-app-prod -n 25

# Aide
./last_docs.py -h
```

## 4. Cas de figure courants

**Certificat auto-signé** (cluster interne sans CA reconnu) :

```bash
./last_docs.py --no-verify-tls
```

À éviter en prod. Le bon réflexe est d'ajouter le CA bundle au truststore système.

**Pas de champ `@timestamp`** dans l'index :

```bash
./last_docs.py -t event_time
```

## 5. Erreurs typiques

| Erreur | Cause | Solution |
|---|---|---|
| `ERREUR: renseigner ES_API_KEY` | Placeholder non remplacé | Éditer ligne 12 |
| `401 Unauthorized` | API key invalide ou révoquée | Régénérer côté Kibana |
| `403 forbidden` | API key sans droit `read` sur l'index | Élargir le `role_descriptors` |
| `SSLError CERTIFICATE_VERIFY_FAILED` | CA pas dans le truststore | `--no-verify-tls` ou ajouter le CA |
| `index_not_found_exception` | Mauvais nom d'index | Vérifier avec `GET _cat/indices` côté Kibana |

## 6. Test rapide sans Elastic réel

Pour vérifier le script avant de cibler le cluster de prod, lancer une instance Elastic locale :

```bash
docker run -d --name es-test \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  docker.elastic.co/elasticsearch/elasticsearch:8.13.0

# Injecte 3 documents
for i in 1 2 3; do
  curl -X POST "http://localhost:9200/test/_doc" \
    -H "Content-Type: application/json" \
    -d "{\"@timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"n\":$i}"
  sleep 1
done

# Configure ES_URL=http://localhost:9200, ES_API_KEY=dummy, ES_VERIFY_TLS=False
./last_docs.py -i test -n 3
```

Sur ce setup local sans sécurité, le script râle quand même au démarrage si l'API key vaut `PUT_YOUR_API_KEY_HERE` (garde-fou). Mettre une valeur quelconque pour passer.

## 7. Limites assumées

- Mono-shard search : pas de `search_after` ni de PIT. Pour un export massif, prévoir un autre outil (`elasticsearch-dump`, `esrally`).
- Aucune mise en cache du résultat : chaque appel = un aller-retour Elastic.
- L'API key est en clair dans le fichier `.py`. Acceptable pour un usage local ad-hoc ; à externaliser (variable d'environnement, Vault) dès qu'on industrialise.
