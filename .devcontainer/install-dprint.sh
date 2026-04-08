#!/usr/bin/env bash
# Installs dprint with architecture detection and checksum verification.
set -euo pipefail

DPRINT_VERSION="0.53.2"

ARCH=$(uname -m)
case "$ARCH" in
  aarch64) TRIPLE="aarch64-unknown-linux-gnu" HASH="490b620a386497b09ce25cc92c4cb784dfdb9d15448db972b164721d6f795ddd" ;;
  x86_64)  TRIPLE="x86_64-unknown-linux-gnu"  HASH="dcb73c6890c80dff15d5c91f7e01c09a5eb6e4c96373525765d08a60f02e4598" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

URL="https://github.com/dprint/dprint/releases/download/${DPRINT_VERSION}/dprint-${TRIPLE}.zip"

curl -fsSL -o /tmp/dprint.zip "$URL"
echo "$HASH /tmp/dprint.zip" | sha256sum -c -
mkdir -p ~/.dprint/bin
unzip -o /tmp/dprint.zip -d ~/.dprint/bin
chmod +x ~/.dprint/bin/dprint
rm /tmp/dprint.zip
echo 'export PATH="$HOME/.dprint/bin:$PATH"' >> ~/.bashrc
