#!/bin/bash
set -euo pipefail

# curl --proto "https" -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent.s3.amazonaws.com/ecs-anywhere-install-latest.sh"  && bash /tmp/ecs-anywhere-install.sh --region "$REGION_GOES_HERE" --cluster "$CLUSTER_NAME_GOES_HERE" --activation-id "$ACTIVATION_ID_GOES_HERE" --activation-code "$ACTIVATION_CODE_GOES_HERE"

check-option-value() {
    if [ "${2:0:2}" == "--" ]; then
        echo "Option $1 was passed an invalid value: $2. Perhaps you passed in an empty env var?"
        fail
    fi
}

usage() {
    echo "$(basename "$0") [--help] --region REGION --activation-code CODE --activation-id ID [--cluster CLUSTER] [--docker-install-source all|docker|distro|none] [--ecs-version VERSION] [--ecs-endpoint ENDPOINT] [--skip-registration] [--no-start]

  --help
        (optional) display this help message.
  --region string
        (required) this must match the region of your ECS cluster and SSM activation.
  --activation-id string
        (required) activation id from the create activation command. Not required if --skip-registration is specified.
  --activation-code string
        (required) activation code from the create activation command. Not required if --skip-registration is specified.
  --cluster string
        (optional) pass the cluster name that ECS agent will connect too. By default its value is 'default'.
  --docker-install-source
        (optional) Source of docker installation. Possible values are 'all, docker, distro, none'. Defaults to 'all'.
  --ecs-version string
        (optional) Version of the ECS agent rpm/deb package to use. If not specified, default to latest.
  --skip-registration
        (optional) if this is enabled, SSM agent install and instance registration with SSM is skipped.
  --no-start
        (optional) if this flag is provided, SSM agent, docker and ECS agent will not be started by the script despite being installed."
}

# required:
REGION=""
ACTIVATION_CODE=""
ACTIVATION_ID=""
# optional:
SKIP_REGISTRATION=false
ECS_CLUSTER=""
DOCKER_SOURCE=""
ECS_VERSION=""
DEB_URL=""
RPM_URL=""
ECS_ENDPOINT=""
# Whether to check signature for the downloaded amazon-ecs-init package. true unless --skip-gpg-check
# specified. --skip-gpg-check is mostly for testing purpose (so that we can test a custom build of ecs init package
# without having to sign it).
CHECK_SIG=true
NO_START=false
while :; do
    case "$1" in
    --help)
        usage
        exit 0
        ;;
    --region)
        check-option-value "$1" "$2"
        REGION="$2"
        shift 2
        ;;
    --cluster)
        check-option-value "$1" "$2"
        ECS_CLUSTER="$2"
        shift 2
        ;;
    --activation-code)
        check-option-value "$1" "$2"
        ACTIVATION_CODE="$2"
        shift 2
        ;;
    --activation-id)
        check-option-value "$1" "$2"
        ACTIVATION_ID="$2"
        shift 2
        ;;
    --docker-install-source)
        check-option-value "$1" "$2"
        DOCKER_SOURCE="$2"
        shift 2
        ;;
    --ecs-version)
        check-option-value "$1" "$2"
        ECS_VERSION="$2"
        shift 2
        ;;
    --deb-url)
        check-option-value "$1" "$2"
        DEB_URL="$2"
        shift 2
        ;;
    --rpm-url)
        check-option-value "$1" "$2"
        RPM_URL="$2"
        shift 2
        ;;
    --ecs-endpoint)
        check-option-value "$1" "$2"
        ECS_ENDPOINT="$2"
        shift 2
        ;;
    --skip-registration)
        SKIP_REGISTRATION=true
        shift 1
        ;;
    --no-start)
        NO_START=true
        shift 1
        ;;
    --skip-gpg-check)
        CHECK_SIG=false
        shift 1
        ;;
    *)
        [ -z "$1" ] && break
        echo "invalid option: [$1]"
        fail
        ;;
    esac
done

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

SSM_SERVICE_NAME="amazon-ssm-agent"
SSM_BIN_NAME="amazon-ssm-agent"

SSM_MANAGED_INSTANCE_ID=""

if [ -z "$REGION" ]; then
    echo "--region is required"
    fail
fi

# If activation code is absent and skip activation flag is present, set flag to skip ssm registration
# if both activation code is present
if [[ -z $ACTIVATION_ID || -z $ACTIVATION_CODE ]]; then
    echo "Both --activation-id and --activation-code are required unless --skip-registration is specified."
    fail
fi

if [ -z "$ECS_CLUSTER" ]; then
    ECS_CLUSTER="default"
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

curl-helper() {
    if ! curl -o "$1" "$2" -fSs; then
        echo "Failed to download $2"
        fail
    fi
}

get-ssm-managed-instance-id() {
    SSM_REGISTRATION_FILE='/var/lib/amazon/ssm/Vault/Store/RegistrationKey'
    if [ -f ${SSM_REGISTRATION_FILE} ]; then
        SSM_MANAGED_INSTANCE_ID=$(jq -r ".instanceID" $SSM_REGISTRATION_FILE)
    fi
}

register-ssm-agent() {
    try "Register SSM agent"
    get-ssm-managed-instance-id
    if [ -z "$SSM_MANAGED_INSTANCE_ID" ]; then
        systemctl stop "$SSM_SERVICE_NAME" &>/dev/null
        $SSM_BIN_NAME -register -code "$ACTIVATION_CODE" -id "$ACTIVATION_ID" -region "$REGION"
        systemctl enable "$SSM_SERVICE_NAME"
        if ! $NO_START; then
            systemctl start "$SSM_SERVICE_NAME"
        else
            echo "Skip starting ssm agent because --no-start is specified."
        fi
        systemctl start "$SSM_SERVICE_NAME"
        echo "SSM agent has been registered."
    else
        echo "SSM agent is already registered. Managed instance ID: $SSM_MANAGED_INSTANCE_ID"
    fi
    ok
}

config-ecs-agent() {
    if [ ! -f "/etc/ecs/ecs.config" ]; then
        touch /etc/ecs/ecs.config
    echo "ECS_CLUSTER=$ECS_CLUSTER" >>/etc/ecs/ecs.config

    if [ ! -f "/var/lib/ecs/ecs.config" ]; then
        touch /var/lib/ecs/ecs.config
    else
        echo "/var/lib/ecs/ecs.config already exists, preserving existing config and appending ECS anywhere requirements."
    fi
    echo "AWS_DEFAULT_REGION=$REGION" >>/var/lib/ecs/ecs.config
    echo "ECS_EXTERNAL=true" >>/var/lib/ecs/ecs.config
    if [ -n "$ECS_ENDPOINT" ]; then
        echo "ECS_BACKEND_HOST=$ECS_ENDPOINT" >>/var/lib/ecs/ecs.config
    fi
    systemctl enable ecs
    if ! $NO_START; then
        systemctl start ecs
    else
        echo "Skip starting ecs agent because --no-start is specified."
    fi
    ok
}

register-ssm-agent
config-ecs-agent
