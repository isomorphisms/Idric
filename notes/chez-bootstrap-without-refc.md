# Chez bootstrap must not require RefC

The canonical `edric bootstrap` selects Chez code generation. Before this
repair its support target also built and installed inherited RefC support,
causing a clean Linux host without `gmp.h` to fail before compiling Idriç.

The support defaults now build and install the common C and Chez runtimes.
Legacy RefC targets remain explicit compatibility targets, outside the
maintained bootstrap. No consumer parser or language semantics change here.

Failure witness: English Major C assignment EMC-ARM-LONG-01, canonical
compiler 2734ac5a86610eddfab73b1644d72b4ac85a65ee, Ubuntu 24.04 x86_64,
2026-10-19: `_datatypes.h:3:10: fatal error: gmp.h: No such file or directory`
while building `support/refc/casts.o` during `edric bootstrap`.

Qualification must include a real Chez bootstrap and the focused Idriç syntax
smoke. An old compiler checkout may use this two-prerequisite build-only patch
for diagnosis, but must record the overlay separately from its compiler source
revision. That is not a pristine-source bootstrap receipt.
