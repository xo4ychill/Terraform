#!/bin/bash

CACHE="$HOME/.terraform.d/plugin-cache"
MIRROR="$HOME/.terraform.d/providers"

echo "Syncing providers to local mirror..."

mkdir -p "$MIRROR"

rsync -av "$CACHE/" "$MIRROR/"

echo "Local registry updated."