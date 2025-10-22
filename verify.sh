#!/usr/bin/env bash
set -euo pipefail
if [ $# -ne 3 ]; then echo "Usage: $0 artifact sbom_with_att.json signature"; exit 1; fi
ART=$1; SBOM=$2; SIG=$3; PUB=cosign.pub
echo "[+] verifying signature..."
cosign verify-blob --key "$PUB" --signature "$SIG" "$SBOM" || { echo "BAD SIGNATURE"; exit 2; }
echo "[+] signature OK"
HASH_ART=$(sha256sum "$ART" | awk '{print $1}')
HASH_SBOM=$(jq -r '.attestations[0].subject[0].hashes["SHA-256"]' "$SBOM")
if [ "$HASH_ART" != "$HASH_SBOM" ]; then echo "FAIL: artifact hash mismatch"; exit 3; else echo "[+] hash match"; fi
CMD=$(jq -r '.attestations[0].claims[] | select(.name=="build.command") | .value' "$SBOM")
if echo "$CMD" | grep -qE '(^|[ /])gcc(\s|$)'; then echo "[+] approved compiler in command: $CMD"; else echo "FAIL: unapproved command ($CMD)"; exit 4; fi
echo "PASS: all checks"
