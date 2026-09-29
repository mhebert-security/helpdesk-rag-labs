#!/usr/bin/env bash
set -euo pipefail

: "${RESOURCE_GROUP:?set RESOURCE_GROUP}"

az group delete --name "$RESOURCE_GROUP" --yes --no-wait
echo "resource group deletion queued; purge AOAI deployment manually if needed"
