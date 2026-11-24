#!/usr/bin/env bash
set -euo pipefail

readonly BASE_URL="https://huggingface.co/SC117/Inkling-2-Mini-abliterated-Strata/resolve/ae324ac3676b97a3f67b475ffc2534c7521ff7c4"
readonly -a FILES=(
  "Inkling-2-Mini-SQ-15-abliterated.strata"
  "tokenizer.json"
  "chat_template.jinja"
)
readonly -a SHA256S=(
  "b52a4827f9fef6a1bb2fc58bf55a2eff376646a6382447020ed54bf0d047925d"
  "7f332727f9a3f093dd452a39cc978e6757627e5dad1b0673aa4e75174f236dd6"
  "53a9035f3255945704b5857657cfb00c1165090c0641c4f782a0cbf268cc16dc"
)
readonly MODEL_BYTES=14348316672

usage() {
  cat <<'EOF'
Usage: download-inkling-sq15.sh [--check|--help]

Download the pinned Inkling 2 Mini SQ-15 model, tokenizer, and chat template.
Files go to STRATA_INKLING_MODELS_DIR or the repository's
models/inkling-2-mini-sq15 directory. --check verifies all three files without
creating directories or downloading anything.
EOF
}

mode="${1:-download}"
if (($# > 1)); then
  usage >&2
  exit 2
fi
case "$mode" in
  download|--check) ;;
  --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/../.." && pwd -P)"
if [[ -n "${STRATA_INKLING_MODELS_DIR:-}" ]]; then
  model_dir="$STRATA_INKLING_MODELS_DIR"
  if [[ "$model_dir" != /* ]]; then
    model_dir="$repo_root/$model_dir"
  fi
else
  model_dir="$repo_root/models/inkling-2-mini-sq15"
fi

file_sha256() {
  local output
  output="$(sha256sum < "$1")" || return 1
  printf '%s\n' "${output%% *}"
}

verify_file() {
  local path="$1"
  local index="$2"
  local actual

  if [[ ! -f "$path" || -L "$path" ]]; then
    printf 'Missing regular file: %s\n' "$path" >&2
    return 1
  fi
  if ((index == 0)); then
    local size
    size="$(wc -c < "$path")"
    if [[ "$size" -ne "$MODEL_BYTES" ]]; then
      printf 'Wrong size for %s: expected %s bytes, found %s\n' \
        "$path" "$MODEL_BYTES" "$size" >&2
      return 1
    fi
  fi
  actual="$(file_sha256 "$path")" || return 1
  if [[ "$actual" != "${SHA256S[$index]}" ]]; then
    printf 'SHA-256 mismatch for %s\n  expected: %s\n  actual:   %s\n' \
      "$path" "${SHA256S[$index]}" "$actual" >&2
    return 1
  fi
  return 0
}

if [[ "$mode" == --check ]]; then
  failed=0
  for index in "${!FILES[@]}"; do
    if verify_file "$model_dir/${FILES[$index]}" "$index"; then
      printf 'OK %s\n' "${FILES[$index]}"
    else
      failed=1
    fi
  done
  if ((failed)); then
    printf 'Inkling SQ-15 files are incomplete or invalid in %s\n' "$model_dir" >&2
    exit 1
  fi
  exit 0
fi

command -v curl >/dev/null 2>&1 || { printf 'curl is required.\n' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { printf 'sha256sum is required.\n' >&2; exit 1; }
mkdir -p -- "$model_dir"
[[ -d "$model_dir" ]] || { printf 'Not a directory: %s\n' "$model_dir" >&2; exit 1; }

# Refuse every pre-existing invalid path before downloading or promoting files.
declare -a EXISTING_VALID=()
for index in "${!FILES[@]}"; do
  final="$model_dir/${FILES[$index]}"
  if [[ -e "$final" || -L "$final" ]]; then
    verify_file "$final" "$index" || {
      printf 'Refusing to replace the existing path: %s\n' "$final" >&2
      exit 1
    }
    EXISTING_VALID[$index]=1
  else
    EXISTING_VALID[$index]=0
  fi
done

declare -a TEMP_FILES=()
cleanup() {
  local temp
  for temp in "${TEMP_FILES[@]}"; do
    if [[ -n "$temp" ]]; then
      rm -f -- "$temp"
    fi
  done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Use unique temporary files and do not resume partial HTTP responses. An
# interrupted transfer can be retried from the beginning without exposing a
# partial final file or trusting an unverified server-side range response.
for index in "${!FILES[@]}"; do
  final="$model_dir/${FILES[$index]}"
  if [[ "${EXISTING_VALID[$index]}" == 1 ]]; then
    printf 'Reusing verified %s\n' "${FILES[$index]}"
    TEMP_FILES[$index]=""
    continue
  fi
  if [[ -e "$final" || -L "$final" ]]; then
    # A separate downloader may have promoted this file since the preflight.
    verify_file "$final" "$index"
    printf 'Reusing verified %s\n' "${FILES[$index]}"
    TEMP_FILES[$index]=""
    continue
  fi

  temp="$(mktemp "$model_dir/.${FILES[$index]}.part.XXXXXXXXXX")"
  TEMP_FILES[$index]="$temp"
  url="$BASE_URL/${FILES[$index]}"
  printf 'Downloading %s\n' "${FILES[$index]}"
  curl --fail --location --silent --show-error \
    --retry 3 --retry-all-errors --retry-delay 2 --connect-timeout 30 \
    --output "$temp" "$url"
done

# Verify every new download once before promoting any of them.
for index in "${!FILES[@]}"; do
  if [[ -n "${TEMP_FILES[$index]:-}" ]]; then
    verify_file "${TEMP_FILES[$index]}" "$index"
  fi
done

for index in "${!FILES[@]}"; do
  temp="${TEMP_FILES[$index]:-}"
  final="$model_dir/${FILES[$index]}"
  if [[ -z "$temp" ]]; then
    [[ -f "$final" && ! -L "$final" ]] || {
      printf 'Previously verified file disappeared: %s\n' "$final" >&2
      exit 1
    }
    continue
  fi
  if [[ -e "$final" || -L "$final" ]]; then
    # Another process may have promoted the same file while this one fetched it.
    verify_file "$final" "$index"
  else
    mv -n -- "$temp" "$final"
    if [[ -e "$temp" || -L "$temp" ]]; then
      # mv -n leaves the temp in place when another writer created the final.
      verify_file "$final" "$index"
    fi
  fi
  printf 'Verified %s\n' "${FILES[$index]}"
done

printf 'All Inkling SQ-15 files are verified in %s\n' "$model_dir"
