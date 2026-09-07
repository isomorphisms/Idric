# Sources and reproduction notes

Accessed 2026-09-07. Primary source code and manuals were pinned before the
action maps were written. Web manuals are linked for readability; repository
links and commits identify the exact inspected text.

## Source snapshots

| Project snapshot | Exact revision | Commit date | Use in this investigation |
| --- | --- | --- | --- |
| OpenSSL `openssl-4.0.2` | `f089acdf4bc7ba94a79f4bf6eb7362c3e7d14aa9` | 2026-08-25 | Current concrete OpenSSL surface, official guide programs, public headers, and manuals. |
| OpenSSL `openssl-3.6.4` | `d3c1b1169b3569ff3069e5b399f47b2b28e03d79` | 2026-08-25 | Recent comparison point for the `SSL_set1_host` to `SSL_set1_dnsname` guide change. |
| LibreSSL portable `v4.3.2` | `05fc4bad4ea5211549cc8289e56b39f44022129f` | 2026-05-25 | Release identity and portable project context. |
| LibreSSL OpenBSD import `libressl-v4.3.2` | `cbcdd558e87dfc1c24eb6a47c1fb660d41c2a56f` | 2026-05-04 | Exact `libssl` and `libtls` headers, manuals, implementation, regressions, and OpenBSD `nc` user. This tag corresponds to OpenBSD 7.9 source. |

OpenSSL tags and LibreSSL portable tags are official project releases. The
`libressl/openbsd` repository is LibreSSL's OpenBSD source import; using the
matching release tag keeps its library source aligned with portable 4.3.2.

## OpenSSL primary sources

### O-CLIENT — OpenSSL blocking client guide and source

- [OpenSSL 4.0 blocking TLS client guide](https://docs.openssl.org/4.0/man7/ossl-guide-tls-client-block/)
- [`demos/guide/tls-client-block.c` at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/demos/guide/tls-client-block.c)

These establish the representative sequence for context configuration,
explicit peer verification, default roots, transport construction, BIO
association, SNI, DNS identity, handshake, I/O, error inspection, shutdown,
and release.

### O-SERVER — OpenSSL blocking server guide and source

- [OpenSSL 4.0 blocking TLS server guide](https://docs.openssl.org/4.0/man7/ossl-guide-tls-server-block/)
- [`demos/guide/tls-server-block.c` at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/demos/guide/tls-server-block.c)

These establish the representative server context, credential, accept BIO,
per-connection SSL, session policy, handshake, I/O, and lifetime actions.

### O-NONBLOCK — OpenSSL nonblocking guide

- [OpenSSL 4.0 nonblocking TLS client guide](https://docs.openssl.org/4.0/man7/ossl-guide-tls-client-non-block/)
- [`demos/guide/tls-client-non-block.c` at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/demos/guide/tls-client-non-block.c)

These establish the `SSL_get_error`, WANT_READ/WANT_WRITE, same-operation retry,
readiness-loop, and external-timeout responsibilities.

### O-CTX — OpenSSL context defaults

- [`SSL_CTX_new(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_new/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_new.pod)

The NOTES section states that peer-credential verification is not performed by
default and must be explicitly requested.

### O-NAME — OpenSSL reference identity

- [`SSL_set1_dnsname`, `SSL_set1_ipaddr`, and deprecated `SSL_set1_host`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_set1_host/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_set1_host.pod)
- [`SSL_set_tlsext_host_name(3)` on the OpenSSL 4.0 servername-actions page](https://docs.openssl.org/4.0/man3/SSL_CTX_set_tlsext_servername_callback/)

These distinguish certificate reference identifiers from SNI and document the
OpenSSL 4.0 deprecation of `SSL_set1_host` in favour of separate DNS/IP actions.

### O-CLIENT-36 — OpenSSL 3.6 comparison point

- [`tls-client-block.c` at `openssl-3.6.4`](https://github.com/openssl/openssl/blob/openssl-3.6.4/demos/guide/tls-client-block.c)
- [`SSL_set1_host(3)`, OpenSSL 3.6](https://docs.openssl.org/3.6/man3/SSL_set1_host/)

The 3.6 guide uses `SSL_set1_host`; it already integrates hostname matching
into handshake verification and does not require the application to retrieve a
certificate and call `X509_check_host` after the handshake.

### O-BIO-OWN — OpenSSL BIO association and ownership

- [`SSL_set_bio(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_set_bio/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_set_bio.pod)
- [`BIO_s_socket(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/BIO_s_socket/)

These establish BIO reference/ownership behavior and the `BIO_CLOSE` socket
lifetime choice.

### O-LIFETIME — OpenSSL context and connection lifetimes

- [`SSL_new(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_new/)
- [`SSL_CTX_free(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_free/)
- [Exact `SSL_new` manual source](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_new.pod)
- [Exact `SSL_CTX_free` manual source](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_free.pod)
- [`ssl/ssl_lib.c` reference-count implementation at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/ssl/ssl_lib.c)

These document inherited context settings and reference-counted release. The
implementation also shows `SSL` retaining and later releasing context
references.

### O-BIO-SSL — OpenSSL SSL BIO composition

- [`BIO_f_ssl(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/BIO_f_ssl/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/BIO_f_ssl.pod)

This documents `BIO_new_ssl_connect`, SSL/connect BIO chains,
`BIO_do_handshake`, retry behavior, `BIO_ssl_shutdown`, and `BIO_free_all`.
Its client example explicitly leaves verification mode and paths to the
application.

### O-VERIFY — OpenSSL verification mode and trust

- [`SSL_CTX_set_verify(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_set_verify/)
- [`SSL_CTX_load_verify_locations(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_load_verify_locations/)
- [Exact `SSL_CTX_set_verify` source](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_set_verify.pod)
- [Exact verify-locations source](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_load_verify_locations.pod)

These establish the client/server verify flags and verification certificate
store actions.

### O-CLIENT-CA — OpenSSL advertised client-CA list

- [`SSL_load_client_CA_file` and `SSL_CTX_set_client_CA_list`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_load_client_CA_file/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_load_client_CA_file.pod)

The manual states that the acceptable-CA list sent to a client is not derived
from the verification CA file/path. It also documents the list's ownership
transfer to `SSL_CTX`.

### O-CREDENTIALS — OpenSSL certificate and key actions

- [`SSL_CTX_use_certificate`, `SSL_CTX_use_certificate_chain_file`, `SSL_CTX_use_PrivateKey_file`, `SSL_CTX_check_private_key`, and `SSL_CTX_use_cert_and_key`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_use_certificate/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_use_certificate.pod)

These establish separate file loaders, parsed-object setters, chain behavior,
and explicit key consistency checking.

### O-ALPN — OpenSSL ALPN manual

- [`SSL_CTX_set_alpn_protos`, `SSL_CTX_set_alpn_select_cb`, `SSL_select_next_proto`, and `SSL_get0_alpn_selected`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_set_alpn_select_cb/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_set_alpn_select_cb.pod)

This documents wire-format lists, server callback and pointer-lifetime rules,
the selection helper, the borrowed result, and the client setters' reversed
return convention.

### O-CIPHERS — OpenSSL cipher configuration

- [`SSL_CTX_set_cipher_list` and `SSL_CTX_set_ciphersuites`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_set_cipher_list/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_set_cipher_list.pod)

This establishes the separate TLS-1.2-and-earlier and TLS-1.3 configuration
actions and string formats.

### O-ERROR — OpenSSL error classification

- [`SSL_get_error(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_get_error/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_get_error.pod)

This documents exact-result coupling, thread error-queue preconditions,
WANT_READ/WANT_WRITE, syscall errors, and retry expectations.

### O-SHUTDOWN — OpenSSL orderly shutdown

- [`SSL_shutdown(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_shutdown/)
- [Exact manual source at `openssl-4.0.2`](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_shutdown.pod)

This establishes the 0/1/negative result distinction, one-way versus
bidirectional shutdown, retry behavior, session implications, and truncation
considerations.

### O-SNI — OpenSSL server-name selection

- [`SSL_CTX_set_tlsext_servername_callback(3)` and `SSL_set_SSL_CTX(3)`, OpenSSL 4.0](https://docs.openssl.org/4.0/man3/SSL_CTX_set_tlsext_servername_callback/)
- [OpenSSL servername manual source](https://github.com/openssl/openssl/blob/openssl-4.0.2/doc/man3/SSL_CTX_set_tlsext_servername_callback.pod)

These are the classic callback/context-switch actions relevant to the
historical comparison. OpenSSL 4.0 marks the servername callback as deprecated
in favour of a ClientHello callback; that newer callback remains an
application-supplied selection action and does not invalidate the structural
point.

## LibreSSL `libssl` primary sources

### LS-HEADER — LibreSSL `libssl` public header

- [`src/lib/libssl/ssl.h` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/ssl.h)
- [`libssl` exported symbol list at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/Symbols.list)

These show that LibreSSL exports the low-level `SSL_CTX`/`SSL` action family,
including verification, BIO association, name, connect/accept, I/O, error,
shutdown, and lifetime actions.

### LS-MANUALS — LibreSSL `libssl` manuals

- [`SSL_CTX_new(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_CTX_new.3)
- [`SSL_CTX_set_verify(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_CTX_set_verify.3)
- [`SSL_set1_host(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_set1_host.3)
- [`SSL_set_bio(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_set_bio.3)
- [`SSL_get_error(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_get_error.3)
- [`SSL_shutdown(3)` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libssl/man/SSL_shutdown.3)

These confirm the resource, hostname, transport, error, and shutdown contracts
for direct LibreSSL `libssl` use.

## OpenBSD `libtls` primary sources

### L-HEADER — `libtls` public API

- [`src/lib/libtls/tls.h` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls.h)
- [`libtls` exported symbol list at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/Symbols.list)

These define the public configuration, client/server, connection, I/O,
inspection, error, and lifetime actions and the WANT result constants.

### L-INIT — `libtls` lifecycle manual

- [`tls_init(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_init.3)
- [Rendered current OpenBSD `tls_init(3)`](https://man.openbsd.org/tls_init.3)

This is the authoritative lifecycle overview. Its HISTORY section records the
safe-use motivation and the OpenBSD 5.6 appearance; its DESCRIPTION documents
configuration, client/server creation, connect/accept, automatic handshake on
I/O, close, and lifetime.

### L-CONNECT — `libtls` client connection manual

- [`tls_connect(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_connect.3)
- [Rendered current OpenBSD `tls_connect(3)`](https://man.openbsd.org/tls_connect.3)

This establishes direct, explicit-servername, socket, fd, and callback
connection alternatives and which one creates the TCP socket.

### L-ACCEPT — `libtls` server accept manual

- [`tls_accept_socket(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_accept_socket.3)
- [Rendered current OpenBSD `tls_accept_socket(3)`](https://man.openbsd.org/tls_accept_socket.3)

This establishes that the application supplies an already accepted transport
and that `libtls` creates a new per-connection context.

### L-READ — `libtls` handshake, I/O, and close manual

- [`tls_read(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_read.3)
- [Rendered current OpenBSD `tls_read(3)`](https://man.openbsd.org/tls_read.3)

This documents automatic handshake, explicit handshake, WANT_POLLIN/
WANT_POLLOUT retry, I/O return values, close, and context error reporting.

### L-CONFIG — `libtls` policy and keypair manuals

- [`tls_config_set_protocols(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_config_set_protocols.3)
- [`tls_config_verify(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_config_verify.3)
- [`tls_load_file(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_load_file.3)

The first manual groups protocol, cipher, curve, ALPN, CA, certificate, key,
keypair, DHE, CRL, and other setters. The verification manual documents safe
checks and explicitly named insecure opt-outs. The load manual describes
memory-based configuration support.

### L-VERIFY — `libtls` verification manual

- [`tls_config_verify(3)` at the pinned source tag](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/man/tls_config_verify.3)
- [Rendered current OpenBSD `tls_config_verify(3)`](https://man.openbsd.org/tls_config_verify.3)

This establishes certificate, name, and time verification defaults; the
explicitly insecure opt-out actions; verification depth; and required versus
optional client-certificate policy.

### L-PROTOCOLS — `libtls` protocol and cipher policy

- [`tls_config.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_config.c)
- [`tls_internal.h` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_internal.h)

These define protocol-name parsing, cipher profiles, the default cipher policy,
and default curve list.

### L-DEFAULT-SRC — `libtls` default policy source

- [`tls_config_new_internal` and verification setters in `tls_config.c`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_config.c)
- [`TLS_PROTOCOLS_DEFAULT` in `tls.h`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls.h)
- [`TLS_DEFAULT_CA_FILE` and default cipher profile in `tls_internal.h`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_internal.h)
- [`tls_new` and `tls_configure` in `tls.c`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls.c)

At this snapshot the default config selects TLS 1.2 and 1.3, the secure cipher
profile, default curves, certificate/name/time verification, and a default CA
file when none is supplied. `tls_new` attaches the internal default config to
a newly allocated context.

### L-CLIENT-SRC — `libtls` client implementation

- [`tls_client.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_client.c)

This is the source trace for name/service parsing, resolver and socket loop,
underlying `SSL_CTX` and `SSL` creation, verification setup, fd/callback
attachment, OCSP request, SNI, `SSL_connect`, and post-handshake name checking.

### L-SERVER-SRC — `libtls` server implementation

- [`tls_server.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_server.c)

This establishes underlying server `SSL_CTX` construction, SNI and ALPN
callbacks, alternate-keypair contexts, client verification, cipher/curve/DHE,
session/ticket/OCSP configuration, per-connection `SSL`, and `SSL_accept`. It
also permits checking the negative finding that `libtls` does not populate a
separate `SSL_CTX` client-CA advertisement list.

### L-IO-SRC — `libtls` I/O and close implementation

- [`tls.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls.c)

The implementations of `tls_read`, `tls_write`, `tls_close`, `tls_ssl_error`,
and ownership flags establish automatic handshake, raw `SSL_*` calls, WANT
translation, EOF handling, and direct-connect socket cleanup.

### L-VERIFY-SRC — `libtls` name verification source

- [`tls_verify.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_verify.c)

This contains the DNS/IP certificate-name matching reached by the client
handshake implementation.

### L-KEYPAIR-SRC — `libtls` keypair and SNI source

- [`tls_keypair.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_keypair.c)
- [`tls_server.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/lib/libtls/tls_server.c)

These establish keypair loading/checking and the construction/selection of
underlying contexts for alternate SNI identities.

### L-NC — OpenBSD netcat as a `libtls` client and server

- [`usr.bin/nc/netcat.c` at `libressl-v4.3.2`](https://github.com/libressl/openbsd/blob/libressl-v4.3.2/src/usr.bin/nc/netcat.c)

This real caller uses `tls_config_new`, client/server configuration,
`tls_connect_socket` or `tls_accept_socket`, an explicit handshake wrapped by
application timeout/poll logic, data I/O, close, and free.

## Authoritative historical and design sources

### H-LIBTLS — Official `libtls` design presentation

- Joel Sing, [“libtls: rethinking the TLS/SSL API,” linux.conf.au 2017](https://www.openbsd.org/papers/linuxconfau2017-libtls/), hosted by OpenBSD.

This is the most direct design source. It explicitly distinguishes `libtls`
from LibreSSL's `libssl`, says that `libtls` uses `libssl` under the hood,
states its safe-default and API-simplicity goals, and gives side-by-side client,
ALPN, SNI, and error-handling examples. Historical code fragments are treated
as historical evidence, not as descriptions of OpenSSL 4.0.

### H-OPENBSD-API — Broader OpenBSD API-design discussion

- Ingo Schwarze, [“OpenBSD and the modern documentation of its system call and C library APIs,” BSDCan 2018](https://www.openbsd.org/papers/bsdcan18-mandoc.pdf), especially slides/pages 23–28.

The relevant section argues for fewer public functions and objects, warns that
callbacks impede call-tree analysis, and uses configuration/initialisation and
error handling as API-design examples. This is broader OpenBSD project context,
not a claim about a single `libtls` design decision.

### H-LIBRESSL — Project origin and component context

- [LibreSSL project home](https://www.libressl.org/)
- [LibreSSL 4.3.2 release notes](https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.3.2-relnotes.txt)

The project site identifies LibreSSL as an OpenSSL fork and lists `libtls` as a
new API; the release notes pin the investigated release context.

## Useful external empirical context

- Martin Georgiev et al., [“The Most Dangerous Code in the World: Validating SSL Certificates in Non-Browser Software,” CCS 2012](https://crypto.stanford.edu/~dabo/pubs/abstracts/ssl-client-bugs.html).

This study predates `libtls` and examines certificate-validation failures in
real applications using several TLS APIs. It is relevant evidence for the
historical usability problem, not authority for the present OpenSSL or
LibreSSL call sequences.

## Reproducing the source inspection

The exact snapshots can be obtained with:

```sh
git clone --branch openssl-4.0.2 --depth 1 \
  https://github.com/openssl/openssl.git openssl-4.0.2
git clone --branch openssl-3.6.4 --depth 1 \
  https://github.com/openssl/openssl.git openssl-3.6.4
git clone --branch v4.3.2 --depth 1 \
  https://github.com/libressl/portable.git libressl-4.3.2
git clone --branch libressl-v4.3.2 --depth 1 \
  https://github.com/libressl/openbsd.git openbsd-libressl-4.3.2
```

Verify the revisions with `git rev-parse HEAD`. The action traces come from:

```text
openssl-4.0.2/
├── demos/guide/tls-client-block.c
├── demos/guide/tls-client-non-block.c
├── demos/guide/tls-server-block.c
├── doc/man3/
└── doc/man7/

openbsd-libressl-4.3.2/src/
├── lib/libssl/ssl.h
├── lib/libssl/man/
├── lib/libtls/tls.h
├── lib/libtls/man/
├── lib/libtls/tls_client.c
├── lib/libtls/tls_server.c
├── lib/libtls/tls_config.c
├── lib/libtls/tls_verify.c
├── lib/libtls/tls_keypair.c
├── lib/libtls/tls.c
└── usr.bin/nc/netcat.c
```

No behavior in the structural map relies solely on a search-result snippet or
on recollection. Claims about public contracts use the manuals/headers; claims
about collapsed lower-level work use the pinned implementation source.
