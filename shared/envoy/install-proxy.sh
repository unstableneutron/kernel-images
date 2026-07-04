#!/bin/bash
set -eux

# Install Envoy proxy (official apt.envoyproxy.io)
ENVOY_PACKAGE="${ENVOY_PACKAGE:-envoy-1.32}"

echo "Installing Envoy proxy package: ${ENVOY_PACKAGE}"
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gpg adduser
mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.envoyproxy.io/signing.key | gpg --dearmor -o /etc/apt/keyrings/envoy-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/envoy-keyring.gpg] https://apt.envoyproxy.io jammy main" > /etc/apt/sources.list.d/envoy.list
apt-get update
apt-get install -y --no-install-recommends "${ENVOY_PACKAGE}" || (apt-cache policy "${ENVOY_PACKAGE}" envoy && exit 1)
# nss tools used to add certificate to chrome
if apt-cache policy netcat | grep -Eq 'Candidate: [^()]'; then
    NETCAT_PACKAGE=netcat
else
    NETCAT_PACKAGE=netcat-openbsd
fi
apt-get install -y --no-install-recommends libnss3-tools curl "${NETCAT_PACKAGE}"
apt-mark hold "${ENVOY_PACKAGE}"
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/apt/

# Create directory structure for Envoy configuration
mkdir -p /etc/envoy/templates
