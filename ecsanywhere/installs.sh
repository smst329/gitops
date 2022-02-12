#!/bin/bash
set -euo pipefail

fail() {
    echo ""
    echo -e "\033[0;31mInstallation Failed\033[0m" # print it in red
    exit 1
}

# required:
REGION="us-east-1"
ECS_VERSION="latest"
DEB_URL="https://s3.${REGION}.amazonaws.com${S3_URL_SUFFIX}/${S3_BUCKET}/$DEB_PKG_NAME"

# check if the script is run with root or sudo
if [ $(id -u) -ne 0 ]; then
    echo "Please run as root."
    fail
fi

# check if system is using systemd
# from https://www.freedesktop.org/software/systemd/man/sd_booted.html
if [ ! -d /run/systemd/system ]; then
    echo "The install script currently supports only systemd."
    fail
fi

if [ -f "/sys/fs/cgroup/cgroup.controllers" ]; then
    echo "Your system is using cgroups v2, which is not supported by ECS."
    echo "Please change your system to cgroups v1 and reboot. If your system has grubby, we suggest using the following command:"
    echo '    sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0" && sudo shutdown -r now'
    fail
fi

ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH_ALT="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH_ALT="arm64"
else
    echo "Unsupported architecture: $ARCH"
    fail
fi

S3_BUCKET="amazon-ecs-agent-$REGION"
DEB_PKG_NAME="amazon-ecs-init-$ECS_VERSION.$ARCH_ALT.deb"
S3_URL_SUFFIX=""

# source /etc/os-release to get the VERSION_ID and ID fields
source /etc/os-release
echo "###"
echo ""

ok() {
    echo ""
    echo "# ok"
    echo "##########################"
    echo ""
}

try() {
    local action=$*
    echo ""
    echo "##########################"
    echo "# Trying to $action ... "
    echo ""
}

apt update -y
apt-get install -y curl jq gpg

install-ssm-agent() {
    local dir
    dir="$(mktemp -d)"
    local SSM_DEB_URL="https://s3.$REGION.amazonaws.com${S3_URL_SUFFIX}/amazon-ssm-$REGION/latest/debian_$ARCH_ALT/amazon-ssm-agent.deb"
    local SSM_DEB_PKG_NAME="ssm-agent.deb"
    curl-helper "$dir/$SSM_DEB_PKG_NAME" "$SSM_DEB_URL"
    curl-helper "$dir/$SSM_DEB_PKG_NAME.sig" "$SSM_DEB_URL.sig"
    ssm-agent-signature-verify "$dir/$SSM_DEB_PKG_NAME.sig" "$dir/$SSM_DEB_PKG_NAME"
    chmod -R a+rX "$dir"
    dpkg -i "$dir/ssm-agent.deb"
    rm -rf "$dir"
    ok
}

ssm-agent-signature-verify() {
    try "verify the signature of amazon-ssm-agent package"
    if ! command -v gpg; then
        echo "WARNING: gpg command not available on this server, not able to verify amazon-ssm-agent package signature."
        ok
        return
    fi

    curl-helper "$dir/amazon-ssm-agent.gpg" "https://raw.githubusercontent.com/aws/amazon-ecs-init/master/scripts/amazon-ssm-agent.gpg"
    local fp
    fp=$(gpg --quiet --with-colons --with-fingerprint "$dir/amazon-ssm-agent.gpg" | awk -F: '$1 == "fpr" {print $10;}')
    echo "$fp"
    if [ "$fp" != "8108A07A9EBE248E3F1C63F254F4F56E693ECA21" ]; then
        echo "amazon-ssm-agent GPG public key fingerprint verification fail. Stop the installation of the amazon-ssm-agent. Please contact AWS Support."
        fail
    fi
    gpg --import "$dir/amazon-ssm-agent.gpg"

    if gpg --verify "$1" "$2"; then
        echo "amazon-ssm-agent GPG verification passed. Install the amazon-ssm-agent."
    else
        echo "amazon-ssm-agent GPG verification failed. Stop the installation of the amazon-ssm-agent. Please contact AWS Support."
        fail
    fi

    ok
}

install-ecs-agent() {
    local dir
    dir="$(mktemp -d)"
    curl-helper "$dir/$DEB_PKG_NAME" "$DEB_URL"
    curl-helper "$dir/$DEB_PKG_NAME.asc" "$DEB_URL.asc"
    ecs-init-signature-verify "$dir/$DEB_PKG_NAME.asc" "$dir/$DEB_PKG_NAME"
    chmod -R a+rX "$dir"
    apt install -y "$dir/$DEB_PKG_NAME"
    rm -rf "$dir"
    ok
}

ecs-init-signature-verify() {
    try "verify the signature of amazon-ecs-init package"
    if ! command -v gpg; then
        echo "WARNING: gpg command not available on this server, not able to verify amazon-ecs-init package signature."
        ok
        return
    elif ! command -v dirmngr; then
        echo "WARNING: dirmngr not installed on this server, not able to verify amazon-ecs-init package signature."
        ok
        return
    fi
    curl-helper "$dir/amazon-ecs-agent.gpg" "https://raw.githubusercontent.com/aws/amazon-ecs-init/master/scripts/amazon-ecs-agent.gpg"
    gpg --import "$dir/amazon-ecs-agent.gpg"
    if gpg --verify "$1" "$2"; then
        echo "amazon-ecs-init GPG verification passed. Install amazon-ecs-init."
    else
        echo "amazon-ecs-init GPG verification failed. Stop the installation of amazon-ecs-init. Please contact AWS Support."
        fail
    fi
    ok
}

install-ssm-agent

apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
    "deb [arch=$ARCH_ALT] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io

install-ecs-agent
