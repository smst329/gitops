#! /bin/bash
set -euo pipefail

read -s -p "Enter encryption pass: " ENC_PASS
echo ""
read -p "Enter Filename: " FILENAME

gpg --batch --passphrase $ENC_PASS --decrypt $FILENAME

unset FILENAME
unset ENC_PASS
