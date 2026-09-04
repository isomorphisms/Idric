#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/.." && pwd)

chez_version=10.4.1
archive_name="csv${chez_version}.tar.gz"
archive_url="https://github.com/cisco/ChezScheme/releases/download/v${chez_version}/${archive_name}"
archive_sha256="2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308"

toolchain_dir=${EDRIC_TOOLCHAIN_DIR:-"$repo_root/.tools"}
cache_dir="$toolchain_dir/cache"
source_dir="$toolchain_dir/src/ChezScheme-${chez_version}"
build_dir="$toolchain_dir/build/ChezScheme-${chez_version}"
prefix="$toolchain_dir/chez-${chez_version}"
bin_dir="$toolchain_dir/bin"
scheme_link="$bin_dir/scheme"
make_command=${MAKE:-make}

fail() {
    printf 'ensure-chez: %s\n' "$*" >&2
    exit 1
}

scheme_is_threaded() {
    candidate=$1
    [ -x "$candidate" ] || return 1
    result=$(printf '(display (threaded?))\n(newline)\n' | "$candidate" --quiet 2>/dev/null | tail -n 1) || return 1
    [ "$result" = '#t' ]
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        fail 'sha256sum or shasum is required'
    fi
}

fetch_archive() {
    destination=$1
    partial="${destination}.part"
    rm -f "$partial"

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --retry 3 --output "$partial" "$archive_url"
    elif command -v wget >/dev/null 2>&1; then
        wget --tries=3 --output-document="$partial" "$archive_url"
    else
        fail 'curl or wget is required to fetch Chez Scheme'
    fi

    mv "$partial" "$destination"
}

if scheme_is_threaded "$scheme_link"; then
    printf '%s\n' "$scheme_link"
    exit 0
fi

mkdir -p "$cache_dir" "$toolchain_dir/src" "$toolchain_dir/build" "$bin_dir"

if [ "${CHEZ_ARCHIVE:-}" != '' ]; then
    archive=$CHEZ_ARCHIVE
    [ -f "$archive" ] || fail "CHEZ_ARCHIVE does not exist: $archive"
else
    archive="$cache_dir/$archive_name"
    [ -f "$archive" ] || fetch_archive "$archive"
fi

actual_sha256=$(sha256_file "$archive")
[ "$actual_sha256" = "$archive_sha256" ] || fail "bad SHA-256 for $archive: expected $archive_sha256, got $actual_sha256"

rm -rf "$source_dir" "$build_dir" "$prefix"
unpack_dir="$toolchain_dir/src/.ChezScheme-${chez_version}.unpack"
rm -rf "$unpack_dir"
mkdir -p "$unpack_dir" "$build_dir"
tar --no-same-owner -xzf "$archive" -C "$unpack_dir"

extracted_source=''
for candidate in "$unpack_dir"/*; do
    if [ -f "$candidate/configure" ]; then
        extracted_source=$candidate
        break
    fi
done
[ "$extracted_source" != '' ] || fail "could not find configure in $archive"
mv "$extracted_source" "$source_dir"
rm -rf "$unpack_dir"

jobs=${JOBS:-}
if [ "$jobs" = '' ]; then
    jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)
fi
if [ "$jobs" = '' ] && command -v sysctl >/dev/null 2>&1; then
    jobs=$(sysctl -n hw.ncpu 2>/dev/null || true)
fi
[ "$jobs" != '' ] || jobs=2

(
    cd "$build_dir"
    "$source_dir/configure" \
        --threads \
        --disable-x11 \
        --disable-curses \
        --as-is \
        --installprefix="$prefix"
    "$make_command" -j"$jobs"
    "$make_command" install
)

installed_scheme="$prefix/bin/scheme"
scheme_is_threaded "$installed_scheme" || fail "built Scheme is missing or not threaded: $installed_scheme"
ln -sfn "../chez-${chez_version}/bin/scheme" "$scheme_link"

printf '%s\n' "$scheme_link"
