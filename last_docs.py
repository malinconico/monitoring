#!/usr/bin/env python3
"""Affiche les X derniers documents d'un index Elastic, triés par @timestamp desc."""
import argparse
import json
import sys

import requests
import urllib3

# ---------------------------------------------------------------------------
# Paramètres à renseigner avant exécution
# ---------------------------------------------------------------------------
ES_URL = "https://elastic.internal:9200"
ES_API_KEY = "PUT_YOUR_API_KEY_HERE"
ES_VERIFY_TLS = True

DEFAULT_INDEX = "avaloq_db_monitoring*"
DEFAULT_COUNT = 10
DEFAULT_TIMESTAMP_FIELD = "@timestamp"
# ---------------------------------------------------------------------------


def fetch_last_docs(es_url, api_key, index, count, ts_field, verify_tls):
    url = f"{es_url.rstrip('/')}/{index}/_search"
    body = {
        "size": count,
        "sort": [{ts_field: {"order": "desc"}}],
    }
    headers = {
        "Authorization": f"ApiKey {api_key}",
        "Content-Type": "application/json",
    }
    resp = requests.post(url, headers=headers, json=body, verify=verify_tls, timeout=15)
    resp.raise_for_status()
    return resp.json().get("hits", {}).get("hits", [])


def main():
    parser = argparse.ArgumentParser(
        description="Affiche les X derniers documents d'un index Elastic."
    )
    parser.add_argument(
        "-i", "--index", default=DEFAULT_INDEX,
        help=f"Index ou pattern d'index (défaut: {DEFAULT_INDEX})",
    )
    parser.add_argument(
        "-n", "--count", type=int, default=DEFAULT_COUNT,
        help=f"Nombre de documents à afficher (défaut: {DEFAULT_COUNT})",
    )
    parser.add_argument(
        "-t", "--timestamp-field", default=DEFAULT_TIMESTAMP_FIELD,
        help=f"Champ de tri temporel (défaut: {DEFAULT_TIMESTAMP_FIELD})",
    )
    parser.add_argument(
        "--no-verify-tls", action="store_true",
        help="Désactive la vérification TLS (dev uniquement)",
    )
    args = parser.parse_args()

    if ES_API_KEY == "PUT_YOUR_API_KEY_HERE":
        sys.exit("ERREUR: renseigner ES_API_KEY en tête du script.")

    verify = ES_VERIFY_TLS and not args.no_verify_tls
    if not verify:
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    try:
        hits = fetch_last_docs(
            ES_URL, ES_API_KEY,
            args.index, args.count, args.timestamp_field, verify,
        )
    except requests.HTTPError as e:
        sys.exit(f"ERREUR Elastic ({e.response.status_code}): {e.response.text}")
    except requests.RequestException as e:
        sys.exit(f"ERREUR connexion: {e}")

    if not hits:
        print(f"Aucun document trouvé dans {args.index}")
        return

    for hit in hits:
        print(json.dumps(
            {
                "_id": hit.get("_id"),
                "_index": hit.get("_index"),
                "_source": hit.get("_source"),
            },
            indent=2, ensure_ascii=False, default=str,
        ))
        print()


if __name__ == "__main__":
    main()
