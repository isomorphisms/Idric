#!/bin/sh
set -eu

fail() {
    code=$1
    shift
    record "$stage result=FAIL status=$code detail=$*"
    printf 'idric-armv7-smoke: %s\n' "$*" >&2
    exit "$code"
}

[ "$#" -le 1 ] || {
    printf 'idric-armv7-smoke: expected optional EVIDENCE_LOG\n' >&2
    exit 2
}

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
evidence=${1:-"$script_dir/PHONE-ACCEPTANCE.log"}

record() {
    printf '%s\n' "$*" | tee -a "$evidence"
}

temporary_parent=${TMPDIR:-"${PREFIX:-/tmp}/tmp"}
mkdir -p "$temporary_parent"
work_dir=$(mktemp -d "$temporary_parent/idric-armv7-smoke.XXXXXX")
keep_work=yes
cleanup() {
    if [ "$keep_work" = no ]; then
        rm -rf -- "$work_dir"
    else
        record "ARTIFACTS retained=$work_dir"
    fi
}
trap cleanup EXIT HUP INT TERM

stage=RUNTIME
record "$stage start command=bin/idric--version"
if ! "$script_dir/bin/idric" --version >"$work_dir/version.stdout" 2>"$work_dir/version.stderr"; then
    cat "$work_dir/version.stdout" "$work_dir/version.stderr" >>"$evidence"
    fail 20 'compiler runtime did not start; see version.stdout and version.stderr'
fi
tr '\n' ' ' <"$work_dir/version.stdout" | sed 's/[[:space:]]*$//' |
    sed 's/^/RUNTIME version=/' | tee -a "$evidence"
record "$stage result=PASS"

stage=COMPILER
record "$stage start source=smoke/Main.idric output=build/exec/idric-armv7"
if ! (
    cd "$work_dir"
    "$script_dir/bin/idric" -o idric-armv7 "$script_dir/smoke/Main.idric"
) >"$work_dir/compiler.stdout" 2>"$work_dir/compiler.stderr"; then
    cat "$work_dir/compiler.stdout" "$work_dir/compiler.stderr" >>"$evidence"
    fail 30 'compiler rejected or failed to lower the included fixture; see compiler.stdout and compiler.stderr'
fi
[ -x "$work_dir/build/exec/idric-armv7" ] ||
    fail 30 'compiler returned success without an executable'
record "$stage result=PASS executable=$work_dir/build/exec/idric-armv7"

stage=FIXTURE
record "$stage start expected=Idriç_ARMv7_OK\\n"
if ! "$work_dir/build/exec/idric-armv7" >"$work_dir/fixture.stdout" 2>"$work_dir/fixture.stderr"; then
    cat "$work_dir/fixture.stderr" >>"$evidence"
    fail 40 'compiled fixture did not execute; see fixture.stdout and fixture.stderr'
fi
printf 'Idriç ARMv7 OK\n' >"$work_dir/expected.stdout"
if ! cmp -s "$work_dir/expected.stdout" "$work_dir/fixture.stdout"; then
    od -An -tx1 "$work_dir/fixture.stdout" | sed 's/^/FIXTURE actual_hex=/' | tee -a "$evidence"
    fail 41 'compiled fixture output did not match exactly; see fixture.stdout'
fi
record "$stage result=PASS stdout=Idriç_ARMv7_OK\\n"

keep_work=no
printf 'Idriç ARMv7 OK\n'
