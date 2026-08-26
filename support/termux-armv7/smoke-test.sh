#!/bin/sh
set -eu

fail() {
    printf 'idric-armv7-smoke: %s\n' "$*" >&2
    exit 1
}

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
temporary_parent=${TMPDIR:-"${PREFIX:-/tmp}/tmp"}
mkdir -p "$temporary_parent"
work_dir=$(mktemp -d "$temporary_parent/idric-armv7-smoke.XXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT HUP INT TERM

(
    cd "$work_dir"
    "$script_dir/bin/idric" -o idric-armv7 "$script_dir/smoke/Main.idric" >/dev/null
    actual=$(./build/exec/idric-armv7)
    [ "$actual" = 'Idriç ARMv7 OK' ] || fail "unexpected output: $actual"
)

printf 'Idriç ARMv7 OK\n'
