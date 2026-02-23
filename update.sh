#!/usr/bin/env bash
set -euo pipefail

BLUE="$(tput setaf 4 2>/dev/null || true)"
GREEN="$(tput setaf 2 2>/dev/null || true)"
YELLOW="$(tput setaf 3 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

log() { echo "${BLUE}[ordersys-delivery-update]${RESET} $*"; }
ok() { echo "${GREEN}[ordersys-delivery-update]${RESET} $*"; }
warn() { echo "${YELLOW}[ordersys-delivery-update]${RESET} $*"; }
err() { echo "${RED}[ordersys-delivery-update]${RESET} $*" >&2; }

usage() {
  cat <<'USAGE'
Usage: curl -fsSL https://ordersys.stonewallmedia.co.uk/update.sh | bash

This hosted updater validates vendor metadata, then delegates update execution to the
installed local OrderSys CLI (`ordersys update`) on the host.

Any additional updater flags can be passed after `bash -s --`:
  curl -fsSL https://ordersys.stonewallmedia.co.uk/update.sh | bash -s -- --yes --skip-os-updates
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing required command: $1"
    exit 1
  fi
}

ensure_root() {
  if [[ "$EUID" -eq 0 ]]; then
    return
  fi
  if command -v sudo >/dev/null 2>&1; then
    exec sudo --preserve-env=ORDERSYS_INSTALL_DIR,ORDERSYS_UPDATE_ENV_FILE bash "$0" "$@"
  fi
  err "Updater must run as root (or via sudo)."
  exit 1
}

read_env_key() {
  local env_file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{ sub(/^[^=]*=/,"",$0); print; exit }' "$env_file" 2>/dev/null || true
}

upsert_env_key() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local tmp
  install -d -m 0755 "$(dirname "$env_file")"
  touch "$env_file"
  tmp="$(mktemp)"
  awk -F= -v k="$key" '$1!=k {print $0}' "$env_file" > "$tmp"
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$env_file"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
    return
  fi
  shasum -a 256 "$1" | awk '{print $1}'
}

is_host_allowed() {
  local host="$1"
  local csv="$2"
  local item
  IFS=',' read -ra allowlist <<< "$csv"
  for item in "${allowlist[@]}"; do
    item="${item## }"
    item="${item%% }"
    [[ -n "$item" ]] || continue
    if [[ "$host" == "$item" || "$host" == *".${item}" ]]; then
      return 0
    fi
  done
  return 1
}

validate_public_dns() {
  local host="$1"
  local ip
  require_cmd python3
  while IFS= read -r ip; do
    [[ -n "$ip" ]] || continue
    if ! python3 - "$ip" <<'PY'
import ipaddress
import sys
ip = ipaddress.ip_address(sys.argv[1])
if ip.is_global:
    raise SystemExit(0)
raise SystemExit(1)
PY
    then
      err "Update source host resolves to non-public IP: ${ip}"
      return 1
    fi
  done < <(getent ahosts "$host" | awk '{print $1}' | sort -u)
}

fetch_file() {
  local url="$1"
  local out_file="$2"
  curl -fsS --proto '=https' --tlsv1.2 --location --max-redirs 3 "$url" -o "$out_file"
}

extract_installer_embedded_public_key() {
  local installer_url="$1"
  local out_file="$2"
  local key_b64

  key_b64="$(
    curl -fsS --proto '=https' --tlsv1.2 --location --max-redirs 3 "$installer_url" \
      | sed -n 's/.*ORDERSYS_LICENSE_PUBLIC_KEY_PEM_B64:-\([^"}]*\).*/\1/p' \
      | head -n1
  )"
  [[ -n "$key_b64" && "$key_b64" != "__LICENSE_PUBLIC_KEY_PEM_B64__" ]] || return 1

  printf '%s' "$key_b64" | base64 -d > "$out_file"
  return 0
}

extract_installer_embedded_scripts() {
  local installer_url="$1"
  local out_file="$2"
  local scripts_b64

  scripts_b64="$(
    curl -fsS --proto '=https' --tlsv1.2 --location --max-redirs 3 "$installer_url" \
      | sed -n 's/.*ORDERSYS_SCRIPTS_TGZ_B64:-\([^"}]*\).*/\1/p' \
      | head -n1
  )"
  [[ -n "$scripts_b64" && "$scripts_b64" != "__ORDERSYS_SCRIPTS_TGZ_B64__" ]] || return 1

  printf '%s' "$scripts_b64" | base64 -d > "$out_file"
  return 0
}

install_ordersys_launcher() {
  cat > /usr/local/bin/ordersys <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

read_env_key() {
  local env_file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{ sub(/^[^=]*=/,"",$0); print; exit }' "$env_file" 2>/dev/null || true
}

env_file="/etc/ordersys/ordersys.env"
candidates=()

if [[ -n "${ORDERSYS_INSTALL_DIR:-}" ]]; then
  candidates+=("${ORDERSYS_INSTALL_DIR}")
fi
if [[ -f "$env_file" ]]; then
  env_install_dir="$(read_env_key "$env_file" ORDERSYS_INSTALL_DIR)"
  if [[ -n "$env_install_dir" ]]; then
    candidates+=("$env_install_dir")
  fi
fi
candidates+=("/opt/ordersys" "/srv/ordersys")

for install_dir in "${candidates[@]}"; do
  if [[ -x "${install_dir}/scripts/ordersys" ]]; then
    exec "${install_dir}/scripts/ordersys" "$@"
  fi
done

echo "[ordersys] ERROR: Local CLI not found under expected install paths." >&2
echo "[ordersys] ERROR: Run installer repair: curl -fsSL https://ordersys.stonewallmedia.co.uk/install | bash" >&2
exit 1
EOF
  chmod 755 /usr/local/bin/ordersys
}

recover_local_cli_from_installer() {
  local installer_url="$1"
  local install_dir="$2"
  local env_file="$3"
  local archive_tmp

  archive_tmp="$(mktemp)"
  if ! extract_installer_embedded_scripts "$installer_url" "$archive_tmp"; then
    rm -f "$archive_tmp"
    return 1
  fi

  install -d -m 0755 "$install_dir"
  tar -xzf "$archive_tmp" -C "$install_dir"
  rm -f "$archive_tmp"

  if [[ ! -x "${install_dir}/scripts/ordersys" ]]; then
    return 1
  fi

  chmod +x "${install_dir}/scripts/ordersys" "${install_dir}/scripts/ordersys-update.sh" 2>/dev/null || true
  install_ordersys_launcher
  upsert_env_key "$env_file" ORDERSYS_INSTALL_DIR "$install_dir"
  return 0
}

resolve_ordersys_cmd() {
  if command -v ordersys >/dev/null 2>&1; then
    printf '%s\n' "$(command -v ordersys)"
    return
  fi
  if [[ -x "${INSTALL_DIR}/scripts/ordersys" ]]; then
    printf '%s\n' "${INSTALL_DIR}/scripts/ordersys"
    return
  fi
  printf '%s\n' ""
}

ordersys_cmd_usable() {
  local cmd="$1"
  [[ -n "$cmd" && -x "$cmd" ]] || return 1
  "$cmd" help >/dev/null 2>&1
}

verify_manifest_signature() {
  local manifest_file="$1"
  local sig_meta_file="$2"
  local pubkey_file="$3"

  local schema_version algorithm expected_sha signature_b64 manifest_sha sig_tmp
  schema_version="$(jq -r '.schema_version // empty' "$sig_meta_file")"
  algorithm="$(jq -r '.algorithm // empty' "$sig_meta_file")"
  expected_sha="$(jq -r '.manifest_sha256 // empty' "$sig_meta_file")"
  signature_b64="$(jq -r '.signature // empty' "$sig_meta_file")"

  [[ "$schema_version" == "1" ]] || { err "Unsupported signature schema_version."; return 1; }
  [[ "$algorithm" == "RSA-SHA256" ]] || { err "Unsupported signature algorithm."; return 1; }
  [[ "$expected_sha" =~ ^[A-Fa-f0-9]{64}$ ]] || { err "Invalid manifest_sha256 format."; return 1; }
  [[ -n "$signature_b64" ]] || { err "Missing signature payload."; return 1; }

  manifest_sha="$(sha256_file "$manifest_file")"
  if [[ "${manifest_sha,,}" != "${expected_sha,,}" ]]; then
    err "Manifest SHA mismatch."
    return 1
  fi

  sig_tmp="$(mktemp)"
  trap 'rm -f "$sig_tmp"' RETURN
  printf '%s' "$signature_b64" | base64 -d > "$sig_tmp"
  openssl dgst -sha256 -verify "$pubkey_file" -signature "$sig_tmp" "$manifest_file" >/dev/null 2>&1 || {
    err "Manifest signature verification failed."
    return 1
  }
  rm -f "$sig_tmp"
  trap - RETURN
}

ensure_root "$@"

require_cmd curl
require_cmd jq
require_cmd openssl
require_cmd getent

ENV_FILE="${ORDERSYS_UPDATE_ENV_FILE:-/etc/ordersys/ordersys.env}"
[[ -f "$ENV_FILE" ]] || { err "OrderSys env file not found: ${ENV_FILE}"; exit 1; }
INSTALL_DIR="${ORDERSYS_INSTALL_DIR:-/opt/ordersys}"
env_install_dir="$(read_env_key "$ENV_FILE" ORDERSYS_INSTALL_DIR)"
if [[ -n "$env_install_dir" ]]; then
  INSTALL_DIR="$env_install_dir"
fi
[[ -d "$INSTALL_DIR" ]] || { err "OrderSys install directory not found: ${INSTALL_DIR}"; exit 1; }

source_url="$(read_env_key "$ENV_FILE" UPDATE_CHECK_URL)"
source_url="${source_url:-https://ordersys.stonewallmedia.co.uk/update/stable.json}"
allowed_hosts="$(read_env_key "$ENV_FILE" UPDATE_ALLOWED_HOSTS)"
allowed_hosts="${allowed_hosts:-ordersys.stonewallmedia.co.uk}"
pubkey_file="$(read_env_key "$ENV_FILE" UPDATE_MANIFEST_PUBLIC_KEY_PEM_FILE)"
if [[ -z "$pubkey_file" ]]; then
  pubkey_file="$(read_env_key "$ENV_FILE" LICENSE_PUBLIC_KEY_PEM_FILE)"
fi
pubkey_file="${pubkey_file:-/opt/ordersys/keys/license_public.pem}"

[[ -f "$pubkey_file" ]] || { err "Manifest public key not found: ${pubkey_file}"; exit 1; }
[[ "$source_url" == https://* ]] || { err "UPDATE_CHECK_URL must be HTTPS."; exit 1; }

host="$(printf '%s' "$source_url" | sed -E 's#^https://([^/]+)/?.*$#\1#')"
host="${host%%:*}"
[[ -n "$host" ]] || { err "Could not parse update source host from ${source_url}"; exit 1; }
installer_url="$(printf 'https://%s/install' "$host")"

is_host_allowed "$host" "$allowed_hosts" || {
  err "Update source host '${host}' is not in UPDATE_ALLOWED_HOSTS (${allowed_hosts})."
  exit 1
}
validate_public_dns "$host"

manifest_file="$(mktemp)"
sig_file="$(mktemp)"
trap 'rm -f "$manifest_file" "$sig_file"' EXIT

fetch_file "$source_url" "$manifest_file"
fetch_file "${source_url}.sig" "$sig_file"

if ! verify_manifest_signature "$manifest_file" "$sig_file" "$pubkey_file"; then
  warn "Manifest signature failed with local key: ${pubkey_file}"
  recovered_key_file="$(mktemp)"
  if extract_installer_embedded_public_key "$installer_url" "$recovered_key_file" \
    && verify_manifest_signature "$manifest_file" "$sig_file" "$recovered_key_file"; then
    install -d -m 0755 "$(dirname "$pubkey_file")"
    cp -f "$recovered_key_file" "$pubkey_file"
    chmod 600 "$pubkey_file"
    ok "Recovered manifest key from installer and updated ${pubkey_file}."
  else
    rm -f "$recovered_key_file"
    err "Manifest signature verification failed."
    err "Run installer repair to refresh key material: curl -fsSL https://ordersys.stonewallmedia.co.uk/install | bash"
    exit 1
  fi
  rm -f "$recovered_key_file"
fi
ok "Manifest signature verified for ${source_url}."

latest_version="$(jq -r '.latest_version // empty' "$manifest_file")"
current_version="$(read_env_key "$ENV_FILE" APP_VERSION)"
current_version="${current_version:-unknown}"

log "Installed version: ${current_version}"
if [[ -n "$latest_version" ]]; then
  log "Latest version available: ${latest_version}"
fi

changelog_url="$(printf '%s' "$source_url" | sed -E 's#/stable\.json$#/changelog.md#')"
if fetch_file "${changelog_url}?v=${latest_version}" "$manifest_file"; then
  log "Changelog preview:"
  awk 'NF{print; count++; if (count>=25) exit}' "$manifest_file" | sed 's/^/  /'
else
  warn "Changelog unavailable from ${changelog_url}"
fi

ordersys_cmd="$(resolve_ordersys_cmd)"
if ! ordersys_cmd_usable "$ordersys_cmd"; then
  warn "Local 'ordersys' CLI is missing or broken. Attempting recovery from installer payload."
  if recover_local_cli_from_installer "$installer_url" "$INSTALL_DIR" "$ENV_FILE"; then
    ok "Recovered local CLI payload under ${INSTALL_DIR}/scripts."
    ordersys_cmd="$(resolve_ordersys_cmd)"
  fi
fi

if ! ordersys_cmd_usable "$ordersys_cmd"; then
  err "Local 'ordersys' CLI not found or unusable after recovery."
  err "Run installer repair: curl -fsSL https://ordersys.stonewallmedia.co.uk/install | bash"
  exit 1
fi

ok "Delegating to local CLI: ${ordersys_cmd} update $*"
exec "$ordersys_cmd" update "$@"
