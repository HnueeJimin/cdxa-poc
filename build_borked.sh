#!/usr/bin/env bash
set -euo pipefail
./compromised-gcc hello.c -o hello-borked
sha256sum hello-borked | tee hello-borked.sha256
npx cdxgen -t c -o bom.borked.json || echo "cdxgen failed - check version"
echo "Built hello-borked and created bom.borked.json"
