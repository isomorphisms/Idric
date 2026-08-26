#!/bin/sh
set -eu

fail() {
    printf 'verify-termux-armv7: %s\n' "$*" >&2
    exit 1
}

[ "$#" -eq 1 ] || fail 'expected BUNDLE_DIRECTORY'
bundle=$1
[ -d "$bundle" ] || fail "not a directory: $bundle"

metadata="$bundle/BUILD-METADATA"
scheme="$bundle/chez/bin/scheme"
support=$(find "$bundle/idric" -type f -name libidris2_support.so -print -quit)
compiler="$bundle/libexec/idric/idris2.so"

[ -f "$metadata" ] || fail 'BUILD-METADATA is missing'
[ -x "$bundle/bin/idric" ] || fail 'bin/idric is not executable'
[ -x "$scheme" ] || fail 'bundled Chez Scheme is not executable'
[ -n "$support" ] || fail 'libidris2_support.so is missing'
[ -f "$compiler" ] || fail 'compiled Idriç image is missing'
[ -x "$bundle/install.sh" ] || fail 'install.sh is not executable'
[ -x "$bundle/smoke-test.sh" ] || fail 'smoke-test.sh is not executable'
[ -f "$bundle/smoke/Main.idric" ] || fail 'phone smoke fixture is missing'

grep -qx 'abi=armeabi-v7a' "$metadata" || fail 'wrong ABI metadata'
grep -qx 'chez_machine=tarm7le' "$metadata" || fail 'wrong Chez machine metadata'
grep -qx 'android_api=24' "$metadata" || fail 'wrong Android API metadata'

scheme_kind=$(file -Lb "$scheme")
support_kind=$(file -b "$support")
case "$scheme_kind" in
    *'ELF 32-bit LSB'*ARM*EABI5*) ;;
    *) fail "wrong Scheme ELF: $scheme_kind" ;;
esac
case "$support_kind" in
    *'ELF 32-bit LSB shared object'*ARM*EABI5*) ;;
    *) fail "wrong support ELF: $support_kind" ;;
esac

readelf -l "$scheme" | grep -q '/system/bin/linker' || fail 'Scheme does not use the 32-bit Android linker'
readelf -h "$support" | grep -Eq 'Class:[[:space:]]+ELF32' || fail 'support library is not ELF32'
readelf -h "$support" | grep -Eq 'Machine:[[:space:]]+ARM' || fail 'support library is not ARM'

if find "$bundle" -type l -exec sh -c '
    for link do
        case $(readlink "$link") in /*) exit 1 ;; esac
    done
' sh {} +; then
    :
else
    fail 'bundle contains an absolute symbolic link'
fi

if find "$bundle" -type f -perm /002 -print -quit | grep -q .; then
    fail 'bundle contains a world-writable file'
fi

if strings "$compiler" | grep -Eq '/home/runner|/workspace/|/tmp/'; then
    fail 'compiled Idriç image leaks a build-machine path'
fi

printf 'Termux ARMv7 bundle structure OK\n'
