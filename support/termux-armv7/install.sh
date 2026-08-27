#!/bin/sh
set -eu

fail() {
    printf 'install-idric: %s\n' "$*" >&2
    exit 10
}

record() {
    printf '%s\n' "$*" | tee -a "$acceptance_log"
}

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
[ -n "${PREFIX:-}" ] || fail 'PREFIX is not set; run this inside Termux'

os=$(uname -o 2>/dev/null || true)
[ "$os" = Android ] || fail "expected Android, got ${os:-unknown}"

architecture=$(uname -m)
case "$architecture" in
    armv7l | armv8l) ;;
    *) fail "this bundle is for 32-bit ARMv7 Termux, not $architecture" ;;
esac

metadata="$script_dir/BUILD-METADATA"
[ -f "$metadata" ] || fail 'BUILD-METADATA is missing'
commit=$(sed -n 's/^idric_commit=//p' "$metadata")
[ -n "$commit" ] || fail 'idric_commit is missing from BUILD-METADATA'
short_commit=$(printf '%s' "$commit" | cut -c1-12)

acceptance_log=${IDRIC_ACCEPTANCE_LOG:-"$PREFIX/tmp/idric-armv7-accept-$short_commit.log"}
mkdir -p "$(dirname -- "$acceptance_log")"
: >"$acceptance_log"
record "IDRIC_PHONE_ACCEPT commit=$commit"
record "INSTALL environment=PASS os=$os architecture=$architecture prefix=$PREFIX"

install_dir=${IDRIC_INSTALL_DIR:-"$PREFIX/opt/idric-$short_commit"}
current_link="$PREFIX/opt/idric"
command_link="$PREFIX/bin/idric"

[ ! -e "$install_dir" ] || fail "installation already exists: $install_dir"
[ ! -e "$current_link" ] || [ -L "$current_link" ] || fail "will not replace non-link: $current_link"
[ ! -e "$command_link" ] || [ -L "$command_link" ] || fail "will not replace non-link: $command_link"

mkdir -p "$PREFIX/opt" "$PREFIX/bin"
if ! cp -R "$script_dir" "$install_dir"; then
    record "INSTALL copy=FAIL source=$script_dir destination=$install_dir"
    exit 10
fi
if ! chmod 755 \
    "$install_dir/bin/idric" \
    "$install_dir/chez/bin/scheme" \
    "$install_dir/install.sh" \
    "$install_dir/smoke-test.sh"; then
    record "INSTALL permissions=FAIL destination=$install_dir"
    exit 10
fi

record "INSTALL copy=PASS destination=$install_dir"

status=0
"$install_dir/smoke-test.sh" "$acceptance_log" || status=$?
if [ "$status" -ne 0 ]; then
    record "ACTIVATE skipped=YES reason=acceptance-failed"
    printf 'install-idric: phone acceptance failed (status %s); bundle retained at %s; evidence: %s\n' \
        "$status" "$install_dir" "$acceptance_log" >&2
    exit "$status"
fi

if ! ln -sfn "$install_dir" "$current_link" ||
   ! ln -sfn "$current_link/bin/idric" "$command_link"; then
    record 'ACTIVATE command=FAIL'
    exit 10
fi

record "ACTIVATE command=PASS path=$command_link"
record 'IDRIC_PHONE_ACCEPT result=PASS'
printf 'Idriç installed: %s\nEvidence: %s\n' "$command_link" "$acceptance_log"
