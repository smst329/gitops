#! /bin/bash
set -euo pipefail

export GITHUB_URL="https://raw.githubusercontent.com/helm/helm"
export COMMIT_HASH="82195652495d757d87c1a01f640973f20ca141b0"

sha256sum -c get_helm.sh.sha256 || exit 1

echo '33e7db512e0d62ca2032078a41f687af50e654ffa04946ded29c28ddf85aceed  install.sh' >> get_helm.sh.sha256
curl -sfL $GITHUB_URL/$COMMIT_HASH/scripts/get-helm-3 > install.sh
sha256sum -c get_helm.sh.sha256 || exit 1

cat install.sh | bash - || exit 1

rm -f install.sh
sha256sum get_helm.sh > get_helm.sh.sha256
