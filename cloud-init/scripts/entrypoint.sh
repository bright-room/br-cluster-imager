#!/usr/bin/env bash

set -Eeuo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

GENERATE_BASE_DIR="/generated/${SERVER_ENV}"
TEMPLATE_BASE_DIR="/templates"
OP_BASE_URI="op://br-cluster-"

SERVER_LIST=(
  "br-gateway1"
  "br-external1"
  "br-node1"
  "br-node2"
  "br-node3"
  "br-node4"
  "br-node5"
  "br-node6"
)

function generate_dir() {
  server_name=$1
  if [ ! -e "${GENERATE_BASE_DIR}/${server_name}" ]; then
    mkdir -p "${GENERATE_BASE_DIR}/${server_name}"
  fi
}

function get_secret() {
    key=$1
    op read "${key}"
}

function generate_user_data() {
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

    jinja2 ${template_file_path} \
      -D "hostname=${hostname}" \
      -D "root_password=${hashed_root_password}" \
      -D "operator_username=${operator_username}" \
      -D "operator_password=${hashed_operator_password}" \
      -D "operator_pubkey=${operator_pubkey}" \
      > ${generate_file_path}
}

function generate_network_config() {
    server_name=$1

    template_file_path="${TEMPLATE_BASE_DIR}/network-config.j2"
    generate_file_path="${GENERATE_BASE_DIR}/${server_name}/network-config"

    internal_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/ip_address")
    external_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/${server_name}/admin_console/external_ip_address")
    gateway_ip=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/GatewayIP")

    ssid=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/network_name")
    passphrase=$(get_secret "${OP_BASE_URI}${SERVER_ENV}/home_wifi/wireless_password")
    wpa_passphrase "${ssid}" "${passphrase}" > /tmp/wpa_config.txt
    hashed_passphrase=$(cat /tmp/wpa_config.txt | sed -E 's/^[ \t]+//' | grep -E '^psk=' | cut -d'=' -f 2)

    jinja2 ${template_file_path} \
      -D internal_ip=${internal_ip} \
      -D ssid=${ssid} \
      -D passphrase=${hashed_passphrase} \
      -D external_ip=${external_ip} \
      -D gateway_ip=${gateway_ip} \
      > ${generate_file_path}
}

### main ###
mkdir -p ${GENERATE_BASE_DIR}

for server_name in ${SERVER_LIST[@]}; do
  generate_dir "${server_name}"
  generate_user_data "${server_name}"
  if [[ ${server_name} =~ ^.*gateway.+$ ]];then
    generate_network_config "${server_name}"
  fi
done
