#!/bin/sh
set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
compiler="$repo_root/build/exec/idris2"

usage() {
  echo "usage: ./edric --emit-math-one-step SOURCE -o ARTIFACT" >&2
  exit 2
}

[ "$#" -eq 3 ] || usage
source=$1
case "$2" in
  -o|--output) ;;
  *) usage ;;
esac
output=$3

[ -f "$source" ] || { echo "Idric math emitter: source not found: $source" >&2; exit 2; }
[ -x "$compiler" ] || {
  echo "Idric math emitter: compiler is not bootstrapped; run ./edric bootstrap" >&2
  exit 2
}

caller_pwd=$(pwd)
source_dir=$(CDPATH='' cd -- "$(dirname -- "$source")" && pwd)
source_name=$(basename -- "$source")
source_path="$source_dir/$source_name"
case "$output" in
  /*) output_path=$output ;;
  *) output_path="$caller_pwd/$output" ;;
esac
mkdir -p "$(dirname -- "$output_path")"
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

# `./edric bootstrap` builds the libraries in-tree. Use exactly those
# bootstrapped libraries for the checked source boundary and subsequent
# execution. Enter the source directory so a module named R128Pipeline is
# checked as R128Pipeline even though the repository fixture lives below an
# examples directory whose descriptive name is not an Idric namespace.
idric_library_path="$repo_root/libs/prelude/build/ttc:$repo_root/libs/base/build/ttc:$repo_root/libs/linear/build/ttc:$repo_root/libs/network/build/ttc:$repo_root/libs/contrib/build/ttc:$repo_root/libs/test/build/ttc:"
idric_bootstrap_prefix="$repo_root/bootstrap-build"

# First establish the ordinary compiler boundary. The emitter body is an Idric
# value in the source module and is executed only after this check succeeds.
(
  cd "$source_dir"
  IDRIS2_PREFIX="$idric_bootstrap_prefix" IDRIS2_PATH="$idric_library_path" \
    "$compiler" --build-dir "$temporary/check" --check "$source_name"
)
body=$(
  cd "$source_dir"
  IDRIS2_PREFIX="$idric_bootstrap_prefix" IDRIS2_PATH="$idric_library_path" \
    "$compiler" --build-dir "$temporary/execute" --no-banner --quiet \
      --exec emit_math_one_step "$source_name"
)
[ -n "$body" ] || { echo "Idric math emitter: emit_math_one_step produced no artifact body" >&2; exit 1; }

set -- $(sha256sum "$source_path")
source_sha256=$1
compiler_head=$(git -C "$repo_root" rev-parse HEAD)
case "$compiler_head" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) echo "Idric math emitter: malformed git head: $compiler_head" >&2; exit 1 ;;
esac

tmp="$temporary/artifact"
{
  printf 'EDRIC_MATH_ONE_STEP\t1\n'
  printf 'source_sha256\t%s\n' "$source_sha256"
  printf 'compiler_head\tisomorphisms/Idric\t%s\n' "$compiler_head"
  printf 'core_typecheck\tPASS\n'
  printf '%s\n' "$body"
} > "$tmp"
mv "$tmp" "$output_path"
trap - EXIT HUP INT TERM
