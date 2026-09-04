#!/bin/sh
set -eu

support_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
source="$support_root/examples/compiler-one-step/PrintX.idric"
artifact_dir="$support_root/build/one-step-test"
artifact="$artifact_dir/PrintX.one-step"
artifact2="$artifact_dir/PrintX.second.one-step"
body="$artifact_dir/PrintX.body"
compiler_head=$(git -C "$support_root" rev-parse HEAD)

rm -rf "$artifact_dir"
mkdir -p "$artifact_dir"

sh "$support_root/scripts/emit-one-step.sh" "$source" -o "$artifact"
sh "$support_root/scripts/emit-one-step.sh" "$source" -o "$artifact2"

cmp "$artifact" "$artifact2"

expected_header=$(printf 'EDRIC_ONE_STEP\t1')
expected_source=$(printf 'source_sha256\t%s' "$(sha256sum "$source" | awk '{print $1}')")
expected_head=$(printf 'compiler_head\tisomorphisms/Idric\t%s' "$compiler_head")
expected_typecheck=$(printf 'core_typecheck\tPASS')
expected_representation=$(printf 'representation\tidris2-anf-show-0.8.0')
expected_definition=$(printf "PrintX.main = [0]: %%let v1 = ('X') in (Prelude.IO.prim__putChar(v1, v0))")

[ "$(sed -n '1p' "$artifact")" = "$expected_header" ]
[ "$(sed -n '2p' "$artifact")" = "$expected_source" ]
[ "$(sed -n '3p' "$artifact")" = "$expected_head" ]
[ "$(sed -n '4p' "$artifact")" = "$expected_typecheck" ]
[ "$(sed -n '5p' "$artifact")" = "$expected_representation" ]
grep -Fx 'definitions_begin' "$artifact" >/dev/null
grep -Fx "$expected_definition" "$artifact" >/dev/null
grep -Fx 'definitions_end' "$artifact" >/dev/null
[ "$(tail -n 1 "$artifact")" = end ]

{
  printf 'EDRIC_ONE_STEP_BODY\t1\n'
  awk '
    /^definitions_begin$/ { inside=1; next }
    /^definitions_end$/ { inside=0 }
    inside { print }
  ' "$artifact"
} > "$body"
body_hash=$(sha256sum "$body" | awk '{print $1}')
recorded_body_hash=$(awk -F '\t' '$1 == "body_sha256" { print $2 }' "$artifact")
[ "$body_hash" = "$recorded_body_hash" ]

printf 'one-step compiler handoff: PASS\n'
