        #!/usr/bin/env bash
        set -euo pipefail
        # Usage: ./merge_and_sign.sh clean|borked
        MODE=${1:-clean}
        if [ "$MODE" = "clean" ]; then
          ART=hello-clean
          BOM=bom.clean.json
          ATT=att.clean.json
          OUT=sbom.clean.with-att.json
        else
          ART=hello-borked
          BOM=bom.borked.json
          ATT=att.borked.json
          OUT=sbom.borked.with-att.json
        fi
        if [ ! -f "$ART" ]; then echo "Artifact $ART not found"; exit 1; fi
        HASH=$(sha256sum "$ART" | awk '{print $1}')
        PWD=$(pwd)
        GCCV=$(gcc -dumpversion || echo "unknown")
        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        # fill attestation
        jq --arg h "$HASH" --arg p "$PWD" --arg v "$GCCV" --arg t "$ts" \
  '.attestations[0].subject[0].hashes["SHA-256"]=$h | .attestations[0].evidence.build.timestamp=$t | .attestations[0].evidence.build.tool.version=$v' \
  $ATT > temp.att.json
        # merge into BOM (simple merge: attach attestations array)
        jq -s '.[0] * {attestations: (.[1].attestations)}' "$BOM" temp.att.json > "$OUT"
        rm -f temp.att.json
        # sign with cosign (requires cosign.key present)
        if [ -f cosign.key ]; then
  cosign sign-blob --key cosign.key "$OUT" > "$OUT.sig"
  echo "Signed $OUT -> $OUT.sig"
else
  echo "cosign.key not found. Create one with 'cosign generate-key-pair' to sign.";
fi
