# Idriç on 32-bit ARMv7 Termux

The phone bundle is a relocatable Idriç compiler installation for the 32-bit
Termux ABI (`armeabi-v7a`, Android API 24). It is built separately from an
Android application and does not require IB to carry the Idriç repository as a
Git submodule.

The bundle contains:

- the Idriç compiler image and the prelude, base, linear, and network packages;
- the Idriç C support library compiled for Android's 32-bit ARM ABI;
- a pinned Chez Scheme runtime compiled for its Android ARMv7 machine type;
- an installer and an end-to-end phone smoke test.

The Chez pin is commit
`45b39d5168fe8fe4adbc464786527217854f31bb`. This is deliberately newer than
Chez 10.4.1: it introduces the `tarm7le` machine type for Android's ARMv7 armel
calling convention. The older `tarm32le` target is ARMv6 hard-float and is not
the phone ABI.

## Build

Install Android NDK `29.0.14206865`, then run:

```sh
ANDROID_NDK_HOME=/absolute/path/to/android-ndk \
  ./scripts/build-termux-armv7-bundle.sh
```

The tarball and SHA-256 file are written under
`build/termux-armv7-dist/`. CI publishes the same files as the
`idric-termux-armv7` workflow artifact.

The build gate inspects the ELF class, ARM machine, EABI version, Android
dynamic linker, bundle-relative links, permissions, and build-path leakage.
That is structural cross-build evidence. Running `install.sh` in Termux adds the
decisive device check: it compiles a `.idric` program and executes the result
before switching the `idric` command to the new version.

## Install on the phone

Extract the artifact where Termux can read it. Shared Android storage is
normally mounted `noexec`, so invoke the installer through the shell:

```sh
sh idric-termux-armv7-*/install.sh
```

The installer copies the bundle into Termux's private `$PREFIX/opt`, runs the
phone smoke test there, then creates `$PREFIX/bin/idric`. It refuses to replace
an unrelated real file or directory. Each build is kept in a commit-versioned
directory, while `$PREFIX/opt/idric` points at the active build.

After installation:

```sh
idric --version
```

IB can call that command through the Termux bridge. The APK remains independent
and network-free; only the Termux-side tool installation owns this compiler and
its runtime.
