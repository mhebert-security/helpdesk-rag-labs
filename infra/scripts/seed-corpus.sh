#!/usr/bin/env bash
set -euo pipefail

# Seed the corpus into blob storage and index it with Azure AI Search.
# Required env: RESOURCE_GROUP, STORAGE_ACCOUNT, SEARCH_SERVICE.

: "${RESOURCE_GROUP:?set RESOURCE_GROUP}"
: "${STORAGE_ACCOUNT:?set STORAGE_ACCOUNT}"
: "${SEARCH_SERVICE:?set SEARCH_SERVICE}"

CONTAINER="corpus"
INDEX="helpdesk-corpus"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORPUS_DIR="$SCRIPT_DIR/../../corpus"

echo "==> uploading corpus to blob container '$CONTAINER'"
for file in "$CORPUS_DIR"/public/*.md "$CORPUS_DIR"/canaries/*.md; do
  [ -e "$file" ] || continue
  blob="$(basename "$file")"
  echo "    $blob"
  az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$CONTAINER" \
    --name "$blob" \
    --file "$file" \
    --overwrite --only-show-errors
done

echo "==> creating search index '$INDEX'"
az search index create \
  --service-name "$SEARCH_SERVICE" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$INDEX" \
  --fields '[
    {"name": "id", "type": "Edm.String", "key": true, "searchable": false},
    {"name": "content", "type": "Edm.String", "searchable": true},
    {"name": "source", "type": "Edm.String", "filterable": true, "sortable": true},
    {"name": "acl_scope", "type": "Edm.String", "filterable": true}
  ]'

echo "==> creating blob data source and indexer"
# v0 uses a naive blob indexer with no chunking skillset. The full chunking
# and vector-enrichment pipeline lands in lab 02 and lab 08.
CONN_STRING="$(az storage account show-connection-string \
  --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" \
  --query connectionString -o tsv)"

az search data-source create \
  --service-name "$SEARCH_SERVICE" \
  --resource-group "$RESOURCE_GROUP" \
  --name "corpus-blobs" \
  --type azureblob \
  --connection-string "$CONN_STRING" \
  --container "$CONTAINER" --only-show-errors

az search indexer create \
  --service-name "$SEARCH_SERVICE" \
  --resource-group "$RESOURCE_GROUP" \
  --name "corpus-indexer" \
  --data-source-name "corpus-blobs" \
  --target-index-name "$INDEX" --only-show-errors

echo "==> running indexer"
az search indexer run \
  --service-name "$SEARCH_SERVICE" \
  --resource-group "$RESOURCE_GROUP" \
  --indexer-name "corpus-indexer"

echo "seed complete."
