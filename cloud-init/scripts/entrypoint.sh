#!/usr/bin/env bash

set -Eeuo pipefail
_=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

: "${SERVER_ENV:?SERVER_ENV is not set}"

SERVER_LIST="/opt/${SERVER_ENV}-servers"
GENERATE_BASE_DIR="/generated/${SERVER_ENV}"
TEMPLATE_BASE_DIR="/templates"
OP_BASE_URI="op://br-cluster-"

function generate_dir() {
  local server_name
  server_name=$1

  if [ ! -e "${GENERATE_BASE_DIR}/${server_name}" ]; then
    mkdir -p "${GENERATE_BASE_DIR}/${server_name}"
  fi
}

function get_secret() {
  local key
  key=$1

  op read "${key}"
}

function generate_user_data() {
  local server_name
  local template_file_path
  local generate_file_path
  local hostname
  local root_password
  local hashed_root_password
  local operator_username
  local operator_password
  local hashed_operator_password
  local operator_pubkey

  server_name=$1

  template_file_path="${TEMPLATE_BASE_DIR}/user-data.j2"
  generate_file_path="${GENERATE_BASE_DIR}/${server_name}/user-data"

  hostname=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/hostname")

  root_password=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/admin_console/admin_password")
  hashed_root_password=$(openssl passwd -6 -salt=salt "${root_password}")

  operator_username=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/username")

  operator_password=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/password")
  hashed_operator_password=$(openssl passwd -6 -salt=salt "${operator_password}")

  operator_pubkey=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}_ssh/public key")

  GENERATE_TARGET="gateway"
  if [[ ${server_name} =~ ^.*node.+$ ]]; then
    GENERATE_TARGET="node"
  fi
  if [[ ${server_name} =~ ^.*external.+$ ]]; then
    GENERATE_TARGET="external"
  fi
  export GENERATE_TARGET

  jinja2 "${template_file_path}" \
    -D "hostname=${hostname}" \
    -D "root_password=${hashed_root_password}" \
    -D "operator_username=${operator_username}" \
    -D "operator_password=${hashed_operator_password}" \
    -D "operator_pubkey=${operator_pubkey}" \
    > "${generate_file_path}"
}

function generate_network_config() {
  local server_name
  local template_file_path
  local generate_file_path
  local internal_ip
  local external_ip
  local gateway_ip
  local ssid
  local passphrase
  local hashed_passphrase

  server_name=$1

  template_file_path="${TEMPLATE_BASE_DIR}/network-config.j2"
  generate_file_path="${GENERATE_BASE_DIR}/${server_name}/network-config"

  internal_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/ip_address")
  external_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/admin_console/external_ip_address")
  gateway_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/GatewayIP")

  ssid=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/network_name")
  passphrase=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/wireless_password")
  hashed_passphrase=$(wpa_passphrase "${ssid}" "${passphrase}" | awk '/^\s*psk=/ {gsub(/^\s*psk=/, ""); print}')

  jinja2 "${template_file_path}" \
    -D "internal_ip=${internal_ip}" \
    -D "ssid=${ssid}" \
    -D "passphrase=${hashed_passphrase}" \
    -D "external_ip=${external_ip}" \
    -D "gateway_ip=${gateway_ip}" \
    > "${generate_file_path}"
}

### main ###
mkdir -p "${GENERATE_BASE_DIR}"

if [[ ! -f ${SERVER_LIST} ]]; then
  echo "Error: server list file not found: ${SERVER_LIST}" >&2
  exit 1
fi

while IFS= read -r server <&3; do
  [[ -z "${server}" ]] && continue
  generate_dir "${server}"
  generate_user_data "${server}"
  if [[ ${server} =~ ^.*gateway.+$ ]]; then
    generate_network_config "${server}"
  fi
done 3< "${SERVER_LIST}"