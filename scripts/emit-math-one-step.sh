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

# First establish the ordinary compiler boundary.  The emitter body is an Idric
# value in the source module and is executed only after this check succeeds.
"$compiler" --check "$source"
body=$("$compiler" --no-banner --quiet --exec emit_math_one_step "$source")
[ -n "$body" ] || { echo "Idric math emitter: emit_math_one_step produced no artifact body" >&2; exit 1; }

set -- $(sha256sum "$source")
source_sha256=$1
compiler_head=$(git -C "$repo_root" rev-parse HEAD)
case "$compiler_head" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) echo "Idric math emitter: malformed git head: $compiler_head" >&2; exit 1 ;;
esac

mkdir -p "$(dirname -- "$output")"
tmp="$output.tmp.$$"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
{
  printf 'EDRIC_MATH_ONE_STEP\t1\n'
  printf 'source_sha256\t%s\n' "$source_sha256"
  printf 'compiler_head\tisomorphisms/Idric\t%s\n' "$compiler_head"
  printf 'core_typecheck\tPASS\n'
  printf '%s\n' "$body"
} > "$tmp"
mv "$tmp" "$output"
trap - EXIT HUP INT TERM
