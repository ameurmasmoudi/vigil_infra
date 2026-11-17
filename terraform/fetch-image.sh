#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
url=$(jq -r .url image.json)
sha=$(jq -r .sha256 image.json)
file="$HOME/.cache/vigil/images/$(jq -r '.name + "-" + .release + ".img"' image.json)"

mkdir -p "$(dirname "$file")"

if [[ -f "$file" ]] && echo "$sha  $file" | sha256sum --check --status; then
  echo "Image already cached and verified: $file"
  exit 0
fi

curl --fail --location --progress-bar --retry 10 --retry-all-errors --retry-delay 3 \
  --continue-at - --output "$file.part" "$url"
echo "$sha  $file.part" | sha256sum --check --quiet
mv "$file.part" "$file"
echo "Image downloaded and verified: $file"
