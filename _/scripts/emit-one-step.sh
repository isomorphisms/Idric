#!/bin/sh
set -eu

support_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
compiler="$support_root/build/exec/idris2"

usage() {
  printf 'usage: ./_/edric --emit-one-step SOURCE -o ARTIFACT\n' >&2
}

[ "$#" -eq 3 ] || { usage; exit 2; }
source=$1
[ "$2" = "-o" ] || { usage; exit 2; }
artifact=$3

[ -f "$source" ] || { printf 'source not found: %s\n' "$source" >&2; exit 1; }
[ -x "$compiler" ] || {
  printf 'compiler not found: %s (run ./_/edric bootstrap first)\n' "$compiler" >&2
  exit 1
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf 'need sha256sum or shasum for deterministic receipts\n' >&2
    exit 1
  fi
}

artifact_dir=$(dirname -- "$artifact")
artifact_base=$(basename -- "$artifact")
mkdir -p "$artifact_dir"
output_dir=$(CDPATH='' cd -- "$artifact_dir" && pwd)
artifact_path="$output_dir/$artifact_base"
work_dir="$output_dir/.${artifact_base}.work"
body_name="$artifact_base.body"
body="$output_dir/$body_name"
rm -rf "$work_dir"
mkdir -p "$work_dir"
rm -f "$artifact_path" "$body"

PATH="$support_root/.tools/bin:$PATH"
export PATH
IDRIS2_PREFIX="$support_root/build/env"
export IDRIS2_PREFIX
IDRIS2_PATH="$support_root/libs/prelude/build/ttc:$support_root/libs/base/build/ttc:$support_root/libs/network/build/ttc"
export IDRIS2_PATH

"$compiler" \
  --cg idric-one-step \
  --build-dir "$work_dir/build" \
  --output-dir "$output_dir" \
  -o "$body_name" \
  "$source"

first_line=$(sed -n '1p' "$body")
expected_body_header=$(printf 'EDRIC_ONE_STEP_BODY\t1')
[ "$first_line" = "$expected_body_header" ] || {
  printf 'unexpected one-step compiler body header: %s\n' "$first_line" >&2
  exit 1
}

source_sha256=$(sha256_file "$source")
body_sha256=$(sha256_file "$body")
compiler_head=$(git -C "$support_root" rev-parse HEAD)

{
  printf 'EDRIC_ONE_STEP\t1\n'
  printf 'source_sha256\t%s\n' "$source_sha256"
  printf 'compiler_head\tisomorphisms/Idric\t%s\n' "$compiler_head"
  printf 'core_typecheck\tPASS\n'
  printf 'representation\tidris2-anf-show-0.8.0\n'
  printf 'body_sha256\t%s\n' "$body_sha256"
  printf 'definitions_begin\n'
  sed '1d' "$body"
  printf 'definitions_end\n'
  printf 'end\n'
} > "$artifact_path"

rm -rf "$work_dir"
rm -f "$body"
