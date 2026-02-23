#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "[validate-delivery] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || fail "Required command not found: ${cmd}"
}

require_cmd jq
require_cmd rg

echo "[validate-delivery] Running delivery contract checks in ${ROOT_DIR}"

# 1) Secret / key material checks.
if rg -n --hidden --glob '!.git/**' --glob '!scripts/validate-delivery.sh' \
  -e 'BEGIN [^-[:cntrl:]]*PRIVATE KEY' \
  -e 'OPENSSH PRIVATE KEY' . >/dev/null; then
  fail "Detected private key material in repository content."
fi

# 2) Required path checks.
required_paths=(
  "install"
  "_headers"
  "update/stable.json"
  "update/stable.json.sig"
  "update/stable.json.sha256"
)
for path in "${required_paths[@]}"; do
  [[ -f "${path}" ]] || fail "Missing required file: ${path}"
done

# 3) stable.json validity and required field checks.
jq -e . update/stable.json >/dev/null || fail "update/stable.json is not valid JSON."
jq -e '.latest_version | type == "string" and length > 0' update/stable.json >/dev/null \
  || fail "update/stable.json must contain a non-empty string latest_version."
stable_version="$(jq -r '.latest_version // empty' update/stable.json)"
[[ "${stable_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "update/stable.json latest_version must be SemVer-like X.Y.Z."

expected_release_paths=(
  "update/${stable_version}.json"
  "update/${stable_version}.json.sig"
  "update/${stable_version}.json.sha256"
)
for path in "${expected_release_paths[@]}"; do
  [[ -f "${path}" ]] || fail "Missing required current-release file: ${path}"
done

# Delivery policy is current-release only: disallow historical versioned payload files.
shopt -s nullglob
for payload in update/*.json update/*.sig update/*.sha256; do
  base="$(basename "${payload}")"
  case "${base}" in
    stable.json|stable.json.sig|stable.json.sha256|"${stable_version}.json"|"${stable_version}.json.sig"|"${stable_version}.json.sha256")
      ;;
    *)
      fail "Unexpected historical release artefact present: ${payload}"
      ;;
  esac
done

# 4) Versioned manifest checks.
versioned_manifest_count=0
for manifest in update/*.json; do
  base="$(basename "${manifest}")"
  [[ "${base}" == "stable.json" ]] && continue
  ((versioned_manifest_count += 1))

  if [[ ! "${base}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.json$ ]]; then
    fail "Versioned manifest filename is not SemVer-like: ${manifest}"
  fi
  version="${BASH_REMATCH[1]}"

  jq -e . "${manifest}" >/dev/null || fail "${manifest} is not valid JSON."
  jq -e --arg version "${version}" '.latest_version == $version' "${manifest}" >/dev/null \
    || fail "${manifest} latest_version must match filename version ${version}."
done
[[ "${versioned_manifest_count}" -eq 1 ]] \
  || fail "Exactly one versioned update manifest must exist (found ${versioned_manifest_count})."

# 5) Placeholder detection (disallowed unless explicitly enabled).
if [[ "${ALLOW_PLACEHOLDERS:-false}" != "true" ]]; then
  if rg -n 'SIGNATURE_PLACEHOLDER' update/*.sig >/dev/null 2>&1; then
    fail "Signature placeholders found. Set ALLOW_PLACEHOLDERS=true only for explicit non-production scaffolding."
  fi
  if rg -n 'SHA256_PLACEHOLDER' update/*.sha256 >/dev/null 2>&1; then
    fail "SHA256 placeholders found. Set ALLOW_PLACEHOLDERS=true only for explicit non-production scaffolding."
  fi
fi

echo "[validate-delivery] All checks passed."
