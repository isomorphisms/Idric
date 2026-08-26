#!/bin/sh
set -eu

fail() {
    printf 'install-idric: %s\n' "$*" >&2
    exit 1
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

install_dir=${IDRIC_INSTALL_DIR:-"$PREFIX/opt/idric-$short_commit"}
current_link="$PREFIX/opt/idric"
command_link="$PREFIX/bin/idric"

[ ! -e "$install_dir" ] || fail "installation already exists: $install_dir"
[ ! -e "$current_link" ] || [ -L "$current_link" ] || fail "will not replace non-link: $current_link"
[ ! -e "$command_link" ] || [ -L "$command_link" ] || fail "will not replace non-link: $command_link"

mkdir -p "$PREFIX/opt" "$PREFIX/bin"
cp -R "$script_dir" "$install_dir"
chmod 755 \
    "$install_dir/bin/idric" \
    "$install_dir/chez/bin/scheme" \
    "$install_dir/install.sh" \
    "$install_dir/smoke-test.sh"

"$install_dir/smoke-test.sh" || fail "phone smoke test failed; retained for inspection at $install_dir"

ln -sfn "$install_dir" "$current_link"
ln -sfn "$current_link/bin/idric" "$command_link"

printf 'Idriç installed: %s\n' "$command_link"
