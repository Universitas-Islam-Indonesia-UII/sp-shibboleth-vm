#!/usr/bin/env bash
# ==========================================================
# Shibboleth SP + Nginx install script (Ubuntu)
# Steps based exactly on your provided list.
# ==========================================================

export HOSTNAME=""
export IDP_HOSTNAME=""
export NGINX_VERSION="1.28.0"

set -euo pipefail

# ====== Check for root ======
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root." >&2
  exit 1
fi

# ====== Required Local Files ======
REQUIRED_FILES=(
  "attribute-map.xml"
  "nginx-default.conf"
  "nginx-ssl.conf"
  "shib_clear_headers"
  "shib_fastcgi_params"
  "shibboleth.conf"
  "shibboleth2.xml.template"
  "index.php"
)

# ====== Check required files ======
echo "==> Performing sanity checks..."
for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Missing required file: $f"
    echo "Make sure it exists in the current directory: $(pwd)"
    exit 1
  fi
done
echo "✅ All required files are present."

# ====== Begin Installation ======
echo "==> Change repository"
sed -i 's|cdn.repo.cloudeka.id/ubuntu/|mirror.nevacloud.com/ubuntu/ubuntu-archive/|' /etc/apt/sources.list.d/ubuntu.sources

echo "==> Installing base packages"
apt update
apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring libparse-recdescent-perl

echo "==> Adding Nginx GPG key"
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "==> Adding Nginx repository"
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
  | tee /etc/apt/sources.list.d/nginx.list

echo "==> Installing Nginx, Supervisor, Shibboleth SP, PHP packages"
apt update
apt install -y nginx=${NGINX_VERSION}-1~noble supervisor shibboleth-sp-common shibboleth-sp-utils php php-fpm

echo "==> Removing Apache if present"
apt purge -y 'apache2*' || true
apt autoremove -y

echo "==> Downloading Nginx module build script"
wget https://raw.githubusercontent.com/nginx/pkg-oss/refs/heads/master/build_module.sh
chmod +x build_module.sh

echo "==> Building headers-more module for Nginx ${NGINX_VERSION}"
set +e
yes "" | ./build_module.sh -v ${NGINX_VERSION} https://github.com/openresty/headers-more-nginx-module.git
set -e

echo "==> Installing headers-more deb package"
dpkg -i ./build-module-artifacts/nginx-module-headersmore_${NGINX_VERSION}+1.0-1~noble_amd64.deb

echo "==> Building Shibboleth Nginx module for Nginx ${NGINX_VERSION}"
set +e
yes "" | ./build_module.sh -v ${NGINX_VERSION} https://github.com/nginx-shib/nginx-http-shibboleth.git
set -e

echo "==> Installing Shibboleth Nginx module deb package"
dpkg -i ./build-module-artifacts/nginx-module-shibboleth_${NGINX_VERSION}+1.0-1~noble_amd64.deb

echo "==> Copying Nginx Shibboleth helper files"
cp shib_fastcgi_params /etc/nginx/shib_fastcgi_params
cp shib_clear_headers /etc/nginx/shib_clear_headers

echo "==> Generating self-signed TLS cert for Nginx"
openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/nginx/nginx-selfsigned.key \
  -out /etc/nginx/nginx-selfsigned.crt \
  -days 365 -nodes \
  -subj "/C=ID/ST=State/L=City/O=Organization/OU=Unit/CN=${HOSTNAME}/emailAddress=sp@${HOSTNAME}"

echo "==> Installing Nginx configs"
sed -i 's/^user[[:space:]]\+nginx;/user www-data;/' /etc/nginx/nginx.conf
sed -i '1iload_module modules/ngx_http_headers_more_filter_module.so;' /etc/nginx/nginx.conf
sed -i '2iload_module modules/ngx_http_shibboleth_module.so;' /etc/nginx/nginx.conf
cat nginx-default.conf > /etc/nginx/conf.d/default.conf
cp nginx-ssl.conf /etc/nginx/conf.d/ssl.conf
sed -i "s|HOSTNAME|${HOSTNAME}|" /etc/nginx/conf.d/ssl.conf
cp index.php /usr/share/nginx/html/index.php

echo "==> Installing Supervisor config for Shibboleth"
cp shibboleth.conf /etc/supervisor/conf.d/shibboleth.conf

echo "==> Generating Shibboleth key/cert"
shib-keygen -h "${HOSTNAME}"

echo "==> Downloading IdP metadata"
wget --no-check-certificate "https://${IDP_HOSTNAME}/idp/shibboleth" \
  -O /etc/shibboleth/idp-metadata.xml

echo "==> Installing Shibboleth configs"
cp /etc/shibboleth/attribute-map.xml /etc/shibboleth/attribute-map.xml.bak
envsubst < shibboleth2.xml.template > /etc/shibboleth/shibboleth2.xml
cat attribute-map.xml > /etc/shibboleth/attribute-map.xml

echo "==> Reloading services"
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload || true
  systemctl restart nginx || true
  systemctl restart supervisor || true
  systemctl restart shibd || true
fi

echo "==> ✅ Installation complete!"