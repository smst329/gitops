#! /bin/bash
set -euo pipefail

read -s -p "Enter encryption pass: " ENC_PASS
echo ""
read -s -p "Enter Secret: " SECRET_VAR
echo ""
read -p "Enter Filename: " FILENAME

echo $SECRET_VAR|gpg --batch --output $FILENAME --passphrase $ENC_PASS --symmetric

unset SECRET_VAR
unset FILENAME
unset ENC_PASS
