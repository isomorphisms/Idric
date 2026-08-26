#!/bin/sh
set -eu

fail() {
    printf 'build-termux-armv7: %s\n' "$*" >&2
    exit 1
}

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/.." && pwd)

chez_repository=https://github.com/cisco/ChezScheme.git
chez_commit=45b39d5168fe8fe4adbc464786527217854f31bb
chez_machine=tarm7le
android_api=24
ndk_version=${NDK_VERSION:-29.0.14206865}
jobs=${JOBS:-2}

android_ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
[ -n "$android_ndk" ] || fail 'set ANDROID_NDK_HOME or ANDROID_NDK_ROOT'
[ -d "$android_ndk/toolchains/llvm/prebuilt" ] || fail "invalid Android NDK: $android_ndk"

host_tag=linux-x86_64
[ "$(uname -s)" = Linux ] || fail 'the cross-build host must be Linux'
[ "$(uname -m)" = x86_64 ] || fail 'the cross-build host must be x86_64'
toolchain="$android_ndk/toolchains/llvm/prebuilt/$host_tag"
[ -d "$toolchain" ] || fail "missing NDK host toolchain: $toolchain"
target_clang="$toolchain/bin/armv7a-linux-androideabi${android_api}-clang"
target_ar="$toolchain/bin/llvm-ar"
target_ranlib="$toolchain/bin/llvm-ranlib"
target_strip="$toolchain/bin/llvm-strip"
for tool in "$target_clang" "$target_ar" "$target_ranlib" "$target_strip"; do
    [ -x "$tool" ] || fail "missing NDK tool: $tool"
done

if [ -n "${BUILD_ROOT:-}" ]; then
    build_root=$BUILD_ROOT
    [ ! -e "$build_root" ] || fail "BUILD_ROOT already exists: $build_root"
    mkdir -p "$build_root"
else
    build_root=$(mktemp -d "${TMPDIR:-/tmp}/idric-termux-armv7.XXXXXX")
fi

dist_dir=${DIST_DIR:-"$repo_root/build/termux-armv7-dist"}
mkdir -p "$dist_dir"

idric_commit=$(git -C "$repo_root" rev-parse HEAD)
short_commit=$(printf '%s' "$idric_commit" | cut -c1-12)
bundle_name="idric-termux-armv7-$short_commit"
bundle="$build_root/$bundle_name"
archive="$dist_dir/$bundle_name.tar.gz"
checksum="$archive.sha256"
[ ! -e "$archive" ] || fail "archive already exists: $archive"
[ ! -e "$checksum" ] || fail "checksum already exists: $checksum"

idric_source="$build_root/idric-source"
chez_source="$build_root/chez-source"
chez_stage="$build_root/chez-stage"
sanitized_scheme="$build_root/idris2-termux.ss"

git clone --quiet --no-hardlinks "$repo_root" "$idric_source"
git -C "$idric_source" checkout --quiet --detach "$idric_commit"

git clone --quiet --filter=blob:none --no-checkout "$chez_repository" "$chez_source"
git -C "$chez_source" checkout --quiet --detach "$chez_commit"
git -C "$chez_source" submodule update --init --recursive --depth 1

(
    cd "$chez_source"
    ./configure --threads --disable-x11 --disable-curses --as-is
    make -j"$jobs"
    make bootquick XM="$chez_machine"
)

host_scheme="$chez_source/ta6le/bin/ta6le/scheme"
xpatch="$chez_source/xc-$chez_machine/s/xpatch"
[ -x "$host_scheme" ] || fail "host Scheme was not built: $host_scheme"
[ -f "$xpatch" ] || fail "Chez cross compiler patch was not built: $xpatch"

(
    cd "$idric_source"
    PATH="$(dirname "$host_scheme"):$PATH" \
    CHEZ="$host_scheme" \
        make bootstrap \
        PREFIX=/idric-bootstrap \
        SCHEME="$host_scheme"
)

idris_version=$(awk -F= '
    /^MAJOR=/ { major=$2 }
    /^MINOR=/ { minor=$2 }
    /^PATCH=/ { patch=$2 }
    END { print major "." minor "." patch }
' "$idric_source/Makefile")
[ "$idris_version" != '..' ] || fail 'could not determine the Idriç version'

mkdir -p \
    "$bundle/bin" \
    "$bundle/chez" \
    "$bundle/idric" \
    "$bundle/libexec/idric" \
    "$bundle/smoke"

(
    cd "$idric_source"
    PATH="$(dirname "$host_scheme"):$PATH" \
    CHEZ="$host_scheme" \
        make install-bootstrap-libs \
        PREFIX="$bundle/idric" \
        IDRIS2_PREFIX="$bundle/idric" \
        SCHEME="$host_scheme"
)

sed '1c#!chezscheme' "$idric_source/build/exec/idris2_app/idris2.ss" >"$sanitized_scheme"
(
    cd "$build_root"
    "$host_scheme" --script "$idric_source/scripts/compile-chez-cross.ss" \
        "$xpatch" "$(basename "$sanitized_scheme")" "$bundle/libexec/idric/idris2.so"
)

(
    cd "$chez_source"
    ./configure \
        --cross \
        --force \
        --machine="$chez_machine" \
        --workarea=android-armv7 \
        --disable-x11 \
        --disable-curses \
        --disable-iconv \
        --disable-hard-links \
        --disable-auto-flags \
        --as-is \
        --installprefix=/chez \
        --temproot="$chez_stage" \
        CC="$target_clang" \
        LD="$target_clang" \
        AR="$target_ar" \
        RANLIB="$target_ranlib" \
        STRIP="$target_strip" \
        CC_FOR_BUILD=cc \
        CFLAGS='-O2 -fPIC -D_REENTRANT -pthread' \
        LDFLAGS='-Wl,--export-dynamic' \
        LIBS='-lm -ldl'
    make -j"$jobs"
    make install
)

chez_machine_dir=$(find "$chez_stage/chez/lib" -mindepth 2 -maxdepth 2 -type d -name "$chez_machine" -print -quit)
[ -n "$chez_machine_dir" ] || fail 'could not locate the installed target Chez runtime'
chez_version_dir=$(basename "$(dirname "$chez_machine_dir")")
mkdir -p "$bundle/chez/bin" "$bundle/chez/lib/$chez_version_dir"
cp -R "$chez_stage/chez/bin/." "$bundle/chez/bin/"
cp -R "$chez_machine_dir" "$bundle/chez/lib/$chez_version_dir/"
bundle_machine_dir="$bundle/chez/lib/$chez_version_dir/$chez_machine"
ln -sfn scheme "$bundle_machine_dir/petite"
ln -sfn scheme "$bundle_machine_dir/scheme-script"
ln -sfn scheme.boot "$bundle_machine_dir/scheme-script.boot"

(
    cd "$idric_source"
    make -C support/c clean
    make -C support/c build \
        CC="$target_clang" \
        CPP="$target_clang -E" \
        AR="$target_ar" \
        RANLIB="$target_ranlib" \
        CFLAGS='-O2 -fPIC' \
        LDFLAGS=''
)

idric_runtime="$bundle/idric/idris2-$idris_version"
mkdir -p "$idric_runtime/lib" "$idric_runtime/support/c" "$idric_runtime/support/chez"
cp "$idric_source/support/c/libidris2_support.so" "$idric_runtime/lib/"
cp "$idric_source/support/c/libidris2_support.a" "$idric_runtime/lib/"
cp "$idric_source"/support/c/*.h "$idric_runtime/support/c/"
cp "$idric_source"/support/chez/*.ss "$idric_runtime/support/chez/"

sed "s/@IDRIS2_VERSION@/$idris_version/g" \
    "$idric_source/support/termux-armv7/idric.in" >"$bundle/bin/idric"
cp "$idric_source/support/termux-armv7/install.sh" "$bundle/install.sh"
cp "$idric_source/support/termux-armv7/smoke-test.sh" "$bundle/smoke-test.sh"
cp "$idric_source/support/termux-armv7/smoke/Main.idric" "$bundle/smoke/Main.idric"

chmod 755 \
    "$bundle/bin/idric" \
    "$bundle/install.sh" \
    "$bundle/smoke-test.sh"
"$target_strip" "$bundle/chez/lib/$chez_version_dir/$chez_machine/scheme"
"$target_strip" "$idric_runtime/lib/libidris2_support.so"

if strings "$bundle/libexec/idric/idris2.so" | grep -F "$build_root" >/dev/null; then
    fail 'compiled Idriç image leaks its build root'
fi

{
    printf 'idric_commit=%s\n' "$idric_commit"
    printf 'idris_version=%s\n' "$idris_version"
    printf 'chez_commit=%s\n' "$chez_commit"
    printf 'chez_machine=%s\n' "$chez_machine"
    printf 'android_api=%s\n' "$android_api"
    printf 'abi=armeabi-v7a\n'
    printf 'ndk_version=%s\n' "$ndk_version"
} >"$bundle/BUILD-METADATA"

"$idric_source/scripts/verify-termux-armv7-bundle.sh" "$bundle"

source_date_epoch=${SOURCE_DATE_EPOCH:-$(git -C "$idric_source" show -s --format=%ct "$idric_commit")}
(
    cd "$build_root"
    tar \
        --sort=name \
        --mtime="@$source_date_epoch" \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        -cf - "$bundle_name" | gzip -n >"$archive"
)
(
    cd "$dist_dir"
    sha256sum "$(basename "$archive")" >"$(basename "$checksum")"
)

printf '%s\n' "$archive"
