{
  "task": "analyse_monitoring_refonte",
  "mode": "analysis_only",
  "implementation": false,
  "output_file": "moni.md",
  "context": {
    "current_system": {
      "description": "Le monitoring actuel repose sur un script SQL monolithique nommé mini_monitoring.sql.",
      "execution": "Le script est exécuté en production via UC4 / Automic environ toutes les 15 minutes.",
      "volume": "Le script contient environ 150 à 200 checks.",
      "outputs": [
        "Envoi d'un e-mail dynamique en fin d'exécution",
        "Envoi des métriques vers Elastic"
      ],
      "constraints": [
        "Le script est critique pour la production",
        "Le script est volumineux et potentiellement complexe",
        "Aucune modification ne doit être faite pour le moment"
      ]
    },
    "target_idea": {
      "description": "Remplacer progressivement le script SQL monolithique par une architecture basée sur Logstash exécutant les requêtes SQL et alimentant Elastic.",
      "split_by_frequency": [
        {
          "frequency": "5 minutes",
          "purpose": "Checks critiques nécessitant une détection rapide"
        },
        {
          "frequency": "15 minutes",
          "purpose": "Checks standards équivalents au fonctionnement actuel"
        },
        {
          "frequency": "24 heures",
          "purpose": "Checks lourds, peu critiques ou nécessitant une seule exécution quotidienne"
        }
      ],
      "alerting": {
        "description": "Mettre en place un alerting Python basé sur l'index Elastic.",
        "goal": "Analyser les métriques indexées et produire des alertes exploitables."
      }
    }
  },
  "instructions": {
    "main_goal": "Analyser le fichier mini_monitoring.sql et produire un avis technique structuré dans moni.md.",
    "important": [
      "Ne rien implémenter.",
      "Ne pas modifier le SQL existant.",
      "Ne pas créer de pipeline Logstash.",
      "Ne pas créer de code Python d'alerting.",
      "Produire uniquement une analyse, des constats, des risques, des recommandations et une stratégie de migration."
    ],
    "files_to_analyze": [
      "mini_monitoring.sql"
    ],
    "expected_output": {
      "file": "moni.md",
      "format": "Markdown",
      "language": "French",
      "content_type": "technical_analysis"
    }
  },
  "analysis_requested": {
    "sql_script_audit": [
      "Comprendre la structure générale du script mini_monitoring.sql.",
      "Identifier les grandes sections fonctionnelles du script.",
      "Estimer le nombre de checks présents.",
      "Identifier les checks critiques, standards et peu critiques quand c'est possible.",
      "Repérer les requêtes potentiellement coûteuses.",
      "Repérer les fonctions, procédures ou blocs PL/SQL embarqués dans le script.",
      "Identifier le code mort potentiel : fonctions non utilisées, procédures non utilisées, variables inutiles, anciennes sections commentées.",
      "Identifier les dépendances entre checks si elles existent.",
      "Identifier les checks qui produisent uniquement de l'information et ceux qui produisent de vraies alertes."
    ],
    "split_strategy": [
      "Proposer une stratégie de découpage du monitoring par fréquence : 5 min, 15 min, 24h.",
      "Indiquer les critères permettant de classer un check dans une fréquence donnée.",
      "Lister les types de checks à mettre en 5 minutes.",
      "Lister les types de checks à garder en 15 minutes.",
      "Lister les types de checks à déplacer en 24 heures.",
      "Identifier les risques liés au découpage du script monolithique."
    ],
    "database_package_strategy": [
      "Donner un avis sur l'idée de sortir les fonctions/procédures du script SQL pour les installer dans la base Oracle sous forme de package.",
      "Identifier les avantages : mutualisation, lisibilité, maintenance, réutilisation.",
      "Identifier les risques : dépendance base, versioning, déploiement, rollback, droits Oracle.",
      "Proposer une stratégie prudente pour cette partie, sans implémentation."
    ],
    "logstash_target_architecture": [
      "Donner un avis sur l'utilisation de Logstash pour exécuter les requêtes SQL.",
      "Identifier les avantages par rapport au script SQL monolithique.",
      "Identifier les limites et points de vigilance du plugin JDBC Logstash.",
      "Proposer une organisation logique des pipelines Logstash par fréquence.",
      "Préciser les risques de charge sur la base si les requêtes sont mal réparties.",
      "Préciser les éléments à surveiller : durée d'exécution, timeout, erreurs SQL, volume indexé, retard d'exécution."
    ],
    "elastic_indexing": [
      "Analyser le besoin de normaliser les documents envoyés dans Elastic.",
      "Proposer les champs importants à avoir dans l'index : check_name, check_group, severity, status, value, threshold, message, execution_time, frequency, source, timestamp.",
      "Donner un avis sur la nécessité d'une nomenclature claire des checks.",
      "Identifier les risques si les documents Elastic sont trop hétérogènes."
    ],
    "python_alerting": [
      "Donner un avis sur la mise en place d'un alerting Python basé sur l'index Elastic.",
      "Préciser les responsabilités possibles du moteur Python.",
      "Identifier les règles importantes : seuils, nombre d'occurrences, anti-spam, déduplication, acquittement éventuel.",
      "Comparer brièvement avec une option Kibana Alerting si pertinent.",
      "Proposer une approche progressive pour éviter de recréer trop vite une usine à gaz."
    ],
    "risks_and_recommendations": [
      "Lister les principaux risques techniques.",
      "Lister les risques d'exploitation.",
      "Lister les risques de migration.",
      "Proposer une approche par étapes.",
      "Indiquer ce qu'il faut absolument mesurer avant toute implémentation.",
      "Donner un avis franc sur la faisabilité et la pertinence de la refonte."
    ]
  },
  "expected_moni_md_structure": [
    "# Analyse de refonte du monitoring",
    "## 1. Contexte actuel",
    "## 2. Constats sur mini_monitoring.sql",
    "## 3. Risques du fonctionnement actuel",
    "## 4. Opportunité de split du monitoring",
    "## 5. Proposition de découpage par fréquence",
    "## 6. Nettoyage SQL et code mort potentiel",
    "## 7. Fonctions et procédures à sortir en package Oracle",
    "## 8. Architecture cible Logstash",
    "## 9. Modèle de données Elastic recommandé",
    "## 10. Alerting Python sur Elastic",
    "## 11. Points de vigilance",
    "## 12. Plan de migration recommandé",
    "## 13. Questions ouvertes",
    "## 14. Avis final"
  ],
  "tone": {
    "style": "franc, technique, pragmatique",
    "avoid": [
      "discours trop théorique",
      "implémentation prématurée",
      "code non demandé",
      "optimisme excessif"
    ],
    "expected": [
      "avis critique",
      "recommandations concrètes",
      "risques clairement identifiés",
      "priorités réalistes"
    ]
  }
}
