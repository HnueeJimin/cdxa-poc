#!/usr/bin/env bash
set -euo pipefail
# Build clean binary, create hash, and generate CycloneDX BOM (requires cdxgen)
gcc hello.c -o hello-clean
sha256sum hello-clean | tee hello-clean.sha256
# generate bom (assumes cdxgen configured to produce spec 1.6)
npx cdxgen -t c -o bom.clean.json || echo "cdxgen failed - check version"
echo "Built hello-clean and created bom.clean.json"
