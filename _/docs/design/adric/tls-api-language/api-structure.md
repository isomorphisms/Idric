# OpenSSL, LibreSSL, and libtls action structure

## Scope and terminology

This document maps actions that a programmer performs. An action can be a
high-level operation, an intermediate operation, or a low-level primitive; it
is not automatically an “algorithm.” The purpose is to expose layering for a
later Adriç discussion, not to redesign any API.

The concrete snapshots are OpenSSL 4.0.2 (with OpenSSL 3.6.4 retained where it
is useful to track a recent API change) and LibreSSL/OpenBSD 4.3.2. Exact
commits and source links are in [sources.md](sources.md). The current OpenSSL
blocking and nonblocking guide programs, public manuals, LibreSSL `libssl`
headers/manuals, OpenBSD `libtls` headers/manuals, and the implementation under
`lib/libtls` were inspected rather than inferring sequences from names.

The mapped jobs use stream TLS over TCP. DTLS, OpenSSL's QUIC-specific API,
provider internals, and exhaustive extension coverage are outside this pass;
the action inventory is deep for the selected ordinary jobs rather than a
flat list of every exported symbol.

## The comparison has three participants, not two

“LibreSSL versus OpenSSL” is too coarse for the API-depth dispute.

| Surface | Role | Programmer-visible character |
| --- | --- | --- |
| OpenSSL `libssl` | TLS protocol API, with BIO and X.509 support APIs | Fine-grained context, connection, transport, verification, handshake, error, and lifetime actions; also offers some composing BIO actions. |
| LibreSSL `libssl` | LibreSSL's low-level TLS protocol API | Retains the recognisable `SSL_CTX`/`SSL`/BIO-style surface and actions such as `SSL_CTX_new`, `SSL_new`, `SSL_connect`, `SSL_read`, and `SSL_shutdown`. It is not the intermediate API in the comparison. |
| OpenBSD `libtls` | A separate public API distributed with LibreSSL and implemented over `libssl`/`libcrypto` | Presents `tls_config`, `tls_client`/`tls_server`, `tls_connect`/`tls_accept_*`, `tls_read`/`tls_write`, and `tls_close`; it folds several lower-level actions into intent-sized ones and installs safer defaults. |

The distinction is visible in the OpenBSD source itself: `libtls` public
functions are declared in `tls.h`, while its implementation creates
`SSL_CTX`/`SSL` objects and calls `SSL_connect`, `SSL_accept`, `SSL_read`,
`SSL_write`, and `SSL_shutdown` internally
([L-HEADER](sources.md#l-header--libtls-public-api),
[L-CLIENT-SRC](sources.md#l-client-src--libtls-client-implementation),
[L-SERVER-SRC](sources.md#l-server-src--libtls-server-implementation),
[L-IO-SRC](sources.md#l-io-src--libtls-io-and-close-implementation)).

The official `tls_init(3)` history says that the API appeared in OpenBSD 5.6
in response to the unnecessary challenges other APIs presented for safe use.
Joel Sing's 2017 OpenBSD presentation describes `libtls` as a fourth LibreSSL
component with a clean, simple API, safe defaults, opaque objects, copied
inputs, and no public X.509 or ASN.1 objects
([H-LIBTLS](sources.md#h-libtls--official-libtls-design-presentation),
[L-INIT](sources.md#l-init--libtls-lifecycle-manual)). Those are authoritative
statements of intent; they are not evidence that every higher-level choice is
universally preferable.

### What the official design discussion says

The 2017 presentation gives a useful timeline: LibreSSL was forked in April
2014; `libtls` (then `ressl`) followed in July after a discussion about making
a better API. It says plainly that `libtls` was using `libssl` “under the hood”
while aiming to rethink the public TLS API. Its stated rules include safe
defaults, consistent return values, opaque structures, copying caller strings
and memory rather than retaining surprising pointers, avoiding public X.509
and ASN.1 objects, adding features in response to actual users, and keeping
client/server operations symmetrical where practical
([H-LIBTLS](sources.md#h-libtls--official-libtls-design-presentation)).

The presentation's comparisons are structural evidence and historical
snapshots. For example, its hostname discussion says the caller must retrieve
a certificate and call `X509_check_host`; modern OpenSSL instead lets the
caller configure a reference identity that is checked during the handshake.
The ALPN and server-SNI comparisons remain recognisable in the inspected
current sources.

Ingo Schwarze's 2018 OpenBSD API/documentation talk supplies broader project
context: minimise public functions and object types, avoid redundant accessors,
and recognise that callbacks make a program's call tree harder to understand.
That supports asking why ALPN or SNI selection machinery is public, but it is
not presented here as the sole or direct rationale for every `libtls` choice
([H-OPENBSD-API](sources.md#h-openbsd-api--broader-openbsd-api-design-discussion)).

The `tls_init(3)` HISTORY section is the closest compact provenance in the API
itself: first appearance in OpenBSD 5.6, followed by the `ressl_*` to `tls_*`
rename in 5.7. Together these sources support a dispute about public action
boundaries, not a claim that LibreSSL replaced its low-level API wholesale.

## Job 1: authenticated blocking client connection

The comparison below uses an ordinary TCP client that verifies a public DNS
server name, exchanges application data, and closes. It does not add ALPN,
client credentials, special cipher policy, session reuse, or an application
timeout.

### OpenSSL 4.0.2 `libssl`: guide-derived flow

The official blocking guide program performs these programmer-visible actions:

1. Create a reusable client context with
   `SSL_CTX_new(TLS_client_method())`.
2. Require peer verification with
   `SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL)`. `SSL_CTX_new(3)` states
   that peer credentials are not verified by default.
3. Load the default trust paths with `SSL_CTX_set_default_verify_paths(ctx)`.
4. Set the minimum protocol version with
   `SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION)`.
5. Create a per-connection object with `SSL_new(ctx)`.
6. Resolve the host with `BIO_lookup_ex`.
7. For candidate addresses, create and connect a socket with `BIO_socket` and
   `BIO_connect`, closing failed candidates and eventually freeing the address
   list.
8. Create a socket BIO with `BIO_new(BIO_s_socket())`, attach the descriptor
   with `BIO_set_fd(..., BIO_CLOSE)`, and attach the BIO to the `SSL` object
   with `SSL_set_bio`. The last action transfers BIO ownership to `SSL`.
9. Set SNI with `SSL_set_tlsext_host_name(ssl, hostname)`.
10. Set the DNS reference identity for certificate verification with
    `SSL_set1_dnsname(ssl, hostname)`.
11. Perform the TLS handshake with `SSL_connect` and, on relevant failure,
    inspect `SSL_get_verify_result`.
12. Send and receive application bytes with `SSL_write_ex` and `SSL_read_ex`.
13. Interpret a non-success I/O result using `SSL_get_error`; the guide uses it
    to distinguish a peer `close_notify` from an abnormal end.
14. Attempt orderly TLS shutdown with `SSL_shutdown`.
15. Free the connection with `SSL_free`—which also frees the attached BIO and
    its owned socket—and free the reusable context with `SSL_CTX_free`.

This is the sequence in the official example, not a claim that every OpenSSL
client must create its transport with BIO socket helpers. A caller can supply
an already-open descriptor or custom BIO. The guide deliberately shows the
transport actions because OpenSSL makes transport creation and association the
application's responsibility
([O-CLIENT](sources.md#o-client--openssl-blocking-client-guide-and-source),
[O-CTX](sources.md#o-ctx--openssl-context-defaults),
[O-NAME](sources.md#o-name--openssl-reference-identity),
[O-BIO-OWN](sources.md#o-bio-own--openssl-bio-association-and-ownership)).

The example's final order is simple, but the more general lifetime graph is
reference-counted: `SSL_new` retains the context, `SSL_CTX_free` releases a
reference, and the object is destroyed only when its last reference is gone.
The caller can therefore release its context reference after creating the last
needed `SSL`; keeping the reusable context longer is an application choice
([O-LIFETIME](sources.md#o-lifetime--openssl-context-and-connection-lifetimes)).

#### Recent name-verification API change

OpenSSL 3.6.4's version of the guide used `SSL_set1_host`; OpenSSL 4.0.2 uses
`SSL_set1_dnsname`, and 4.0 deprecates `SSL_set1_host` in favour of separate
DNS-name and IP-address actions. Both arrange for name checking during
certificate verification. This is already shallower and safer than the older
pattern of retrieving the peer X.509 certificate and separately calling
`X509_check_host`. SNI and reference-identity configuration nevertheless remain
two actions because they do different jobs
([O-NAME](sources.md#o-name--openssl-reference-identity),
[O-CLIENT-36](sources.md#o-client-36--openssl-36-comparison-point)).

### OpenSSL composing BIO alternative

`BIO_new_ssl_connect(ctx)` creates an SSL BIO followed by a connect BIO;
`BIO_set_host`/`BIO_set_conn_hostname` supplies the destination, and
`BIO_do_connect`/`BIO_do_handshake` can drive transport connection and TLS
handshake through the chain. `BIO_free_all` releases the chain. This collapses
some explicit transport wiring, but it does not choose an authentication
policy for the caller: the official example leaves placeholders for verify
mode and verify paths, and callers still need an `SSL *` when configuring SNI
and certificate reference identity. It is therefore an intermediate
composition mechanism, but not the same kind of secure-by-default,
goal-oriented client action as `tls_connect`
([O-BIO-SSL](sources.md#o-bio-ssl--openssl-ssl-bio-composition)).

### LibreSSL 4.3.2 `libssl`: same low-level shape

LibreSSL's current `libssl` exports the corresponding low-level actions,
including `TLS_client_method`, `SSL_CTX_new`, `SSL_CTX_set_verify`,
`SSL_CTX_set_default_verify_paths`, `SSL_new`, `SSL_set_bio`,
`SSL_set_tlsext_host_name`, `SSL_set1_host`, `SSL_connect`, `SSL_read_ex`,
`SSL_write_ex`, `SSL_get_error`, `SSL_shutdown`, `SSL_free`, and
`SSL_CTX_free`. Its exact API is not interchangeable with every OpenSSL 4.0
detail—for example, it has `SSL_set1_host`, not OpenSSL 4.0's new
`SSL_set1_dnsname`—but the resource and action layers are recognisably the
same. A direct LibreSSL `libssl` client still has to construct an `SSL_CTX`,
set verification/trust/name policy, construct an `SSL`, associate transport,
drive the handshake, interpret I/O results, and manage lifetimes. Its context
starts in `SSL_VERIFY_NONE`; the LibreSSL manual says a client may still check
the certificate and expose the result, but verification failure does not abort
the handshake unless the caller selects `SSL_VERIFY_PEER`
([LS-HEADER](sources.md#ls-header--libressl-libssl-public-header),
[LS-MANUALS](sources.md#ls-manuals--libressl-libssl-manuals)).

### OpenBSD `libtls`: documented flow

The public `libtls` lifecycle is:

1. Create a configuration with `tls_config_new`.
2. Optionally change the policy with `tls_config_set_*` actions.
3. Create a client context with `tls_client`.
4. Apply the configuration with `tls_configure`, after which the caller may
   `tls_config_free` the configuration if it will not configure another
   context.
5. Call `tls_connect(ctx, host, port)`. This action resolves the service,
   creates and connects a socket, prepares the TLS connection, and infers the
   verification name from `host`. In the inspected implementation it does not
   complete the handshake before returning.
6. Optionally call `tls_handshake` when the program must separate handshake
   completion from application I/O. Otherwise `tls_read` and `tls_write`
   perform it automatically when needed.
7. Exchange application data with `tls_write` and `tls_read`.
8. Close the TLS layer with `tls_close` and release the context with
   `tls_free`.

`tls_init` remains public but the manual says callers no longer need to call it
because it runs internally. The public lifecycle documentation says to create
and apply a configuration. Current source also gives every newly allocated TLS
context a reference to an internal default configuration in `tls_new`; that
implementation detail explains why the object begins with a policy, but it
does not erase the documented configuration phase
([L-INIT](sources.md#l-init--libtls-lifecycle-manual),
[L-CONNECT](sources.md#l-connect--libtls-client-connection-manual),
[L-READ](sources.md#l-read--libtls-handshake-io-and-close-manual),
[L-DEFAULT-SRC](sources.md#l-default-src--libtls-default-policy-source)).

The direct-connect action has useful alternatives at the same conceptual
level:

| Caller situation | `libtls` action | What remains with the caller |
| --- | --- | --- |
| Library may resolve and open TCP | `tls_connect` | host, service/port, policy |
| Route host differs from authenticated name | `tls_connect_servername` | route host/port and explicit server name |
| Caller already has one socket | `tls_connect_socket` | opening, nonblocking mode, and socket lifetime contract |
| Separate read/write descriptors | `tls_connect_fds` | descriptor creation and lifetime |
| Application supplies transport callbacks | `tls_connect_cbs` | callback behavior and backing transport |

### What `tls_connect` actually collapses

The implementation, not just the public manual, was traced. For the direct
path it:

- splits host/service, calls `getaddrinfo`, iterates addresses, creates a
  socket, and calls `connect`;
- creates an underlying `SSL_CTX` and applies protocol, cipher, trust,
  verification, curve, OCSP, keypair, and other configuration;
- creates an `SSL`, connects it to the supplied file descriptors or callbacks,
  requests OCSP status, and sends SNI for a DNS name but not an IP literal;
- calls `SSL_connect` when the handshake is driven;
- obtains the peer certificate and checks the configured server name;
- maps `SSL_read`/`SSL_write`/`SSL_shutdown` results to a small public return
  vocabulary and records one context error string.

Thus DNS, candidate-address iteration, socket creation, BIO-like attachment,
`SSL_CTX`, `SSL`, SNI setup, chain policy, certificate-name checking, and
error-translation actions did not cease to exist. They moved below an action
whose arguments correspond more closely to “connect to this named service.”
The socket/fd/callback variants preserve escape points when transport is part
of the caller's intent
([L-CLIENT-SRC](sources.md#l-client-src--libtls-client-implementation),
[L-VERIFY-SRC](sources.md#l-verify-src--libtls-name-verification-source),
[L-IO-SRC](sources.md#l-io-src--libtls-io-and-close-implementation)).

## Job 2: accept a server TLS connection

### OpenSSL 4.0.2 guide-derived server flow

The official blocking server guide performs these main actions:

1. Create `SSL_CTX` with `SSL_CTX_new(TLS_server_method())`.
2. Set minimum protocol and context options.
3. Load the certificate chain with `SSL_CTX_use_certificate_chain_file` and
   the private key with `SSL_CTX_use_PrivateKey_file`.
4. Configure session-ID context, session caching, cache size, and session
   timeout for the example's resumption policy.
5. Configure peer verification mode; the example does not require client
   certificates.
6. Create an accept BIO with `BIO_new_accept`, set bind/reuse mode, and call
   `BIO_do_accept` once to initialise/listen.
7. For each connection, call `BIO_do_accept` again and `BIO_pop` the connected
   socket BIO from the accept BIO.
8. Create `SSL` with `SSL_new`, transfer the connected BIO to it with
   `SSL_set_bio`, and perform the server handshake with `SSL_accept`.
9. Read and write with `SSL_read_ex`/`SSL_write_ex`, interpreting failures.
10. Free the per-connection `SSL`; later free the accept BIO and `SSL_CTX`.
    This particular guide server does not call `SSL_shutdown` and explicitly
    chooses to tolerate an EOF without TLS shutdown because its example
    application protocol supplies its own message framing. An orderly-close
    policy would add `SSL_shutdown` before `SSL_free`.

The session-cache choices in step 4 and the no-client-authentication choice in
step 5 are example policy, not irreducible server mechanics. The key structural
point is the separate reusable context, listener BIO, connected BIO, and
per-connection SSL lifetimes, plus separate credential loading and handshake
actions
([O-SERVER](sources.md#o-server--openssl-blocking-server-guide-and-source),
[O-CREDENTIALS](sources.md#o-credentials--openssl-certificate-and-key-actions)).

An application that already owns a listening and accepted socket can omit the
accept-BIO construction, but must still create/attach the per-connection
`SSL` and drive `SSL_accept`.

### `libtls` server flow

The documented `libtls` shape is:

1. `tls_config_new`.
2. Install the server certificate and key together with
   `tls_config_set_keypair_file` (or the memory/OCSP variants). Repeated
   `tls_config_add_keypair_file` actions add alternative keypairs for SNI.
3. Optionally set protocol, cipher, ALPN, client-verification, or session
   policy.
4. `tls_server`, then `tls_configure`; the configuration may be released after
   its final use.
5. The application accepts a transport socket.
6. `tls_accept_socket(server_ctx, &connection_ctx, socket)` creates the
   per-connection context. `tls_accept_fds` and `tls_accept_cbs` are
   alternatives.
7. Optionally complete `tls_handshake`, or let the first `tls_read`/`tls_write`
   drive it.
8. Exchange data, then `tls_close` and `tls_free` the per-connection context.
9. Eventually `tls_free` the server context.

Unlike `tls_connect`, `tls_accept_socket` does not accept the TCP connection;
it wraps an already established one. This asymmetry is intentional in the
documented surface and should not be obscured by calling both simply
“connect”
([L-ACCEPT](sources.md#l-accept--libtls-server-accept-manual),
[L-CONFIG](sources.md#l-config--libtls-policy-and-keypair-manuals)).

Internally, server configuration creates `SSL_CTX` objects, installs SNI and
ALPN callbacks, applies the base and alternate keypairs, configures optional
client verification, curves/DHE/ciphers, tickets, and sessions. Per accepted
connection it creates `SSL`, installs app data and
file-descriptor/callback BIO plumbing, then drives `SSL_accept`. The public
server actions therefore retain the distinct server-policy and
per-connection objects while hiding the callback and context-switching
machinery
([L-SERVER-SRC](sources.md#l-server-src--libtls-server-implementation)).

## Job 3: trust and hostname verification

### Default public-web client

| Surface | Programmer-visible actions | Defaults and hidden actions |
| --- | --- | --- |
| OpenSSL 4.0.2 `libssl` | `SSL_CTX_set_verify(...SSL_VERIFY_PEER...)`; `SSL_CTX_set_default_verify_paths`; `SSL_set_tlsext_host_name`; `SSL_set1_dnsname` (or `SSL_set1_ipaddr` for an IP identity); then `SSL_connect` | Chain validation happens during handshake once explicitly enabled. SNI and verification identity remain separate. |
| LibreSSL 4.3.2 `libssl` | Same low-level shape, with `SSL_set1_host` for the reference name | Direct callers still explicitly choose verify mode, roots, SNI, and name. |
| `libtls` | Default `tls_config`; `tls_connect(host, port)` | Default config verifies certificate, name, and time, uses `/etc/ssl/cert.pem` when no CA is supplied, infers verification name from host, and sends SNI for DNS names. |

This is one of the clearest shallow/deep contrasts. OpenSSL's separation is
not arbitrary: trust roots, SNI, and the authenticated reference identity can
legitimately differ. `libtls` collapses the common case while retaining
`tls_config_set_ca_file`/`_path`/`_mem` and
`tls_connect_servername`/`_socket`/`_fds`/`_cbs` for the less common cases.

The `libtls` opt-outs are explicitly named
`tls_config_insecure_noverifycert`,
`tls_config_insecure_noverifyname`, and
`tls_config_insecure_noverifytime`; `tls_config_verify` turns all three checks
back on. The naming makes policy weakening visible rather than making safe
verification an extra positive action
([L-VERIFY](sources.md#l-verify--libtls-verification-manual),
[L-DEFAULT-SRC](sources.md#l-default-src--libtls-default-policy-source)).

## Job 4: protocol and cipher restrictions

### Versions

OpenSSL exposes lower and upper bounds independently through
`SSL_CTX_set_min_proto_version` and `SSL_CTX_set_max_proto_version` (with
per-connection forms). `libtls` exposes an allowed-version bit mask through
`tls_config_set_protocols`; `tls_config_parse_protocols` parses names including
`tlsv1.2`, `tlsv1.3`, profiles such as `secure`/`default`, and `!` subtraction.
At the inspected snapshot, the `libtls` default mask is TLS 1.2 plus TLS 1.3.

These are different policy shapes: interval bounds naturally express “at
least,” while an allowed set naturally expresses holes or exact membership.
Neither representation by itself decides how Adriç should understand ordinary
English.

### Ciphers

OpenSSL 4.0 has separate actions and name spaces:

- `SSL_CTX_set_cipher_list` for TLS 1.2 and below, using the cipher-list rule
  language;
- `SSL_CTX_set_ciphersuites` for TLS 1.3, using a colon-separated suite list.

Calling the first does not constrain TLS 1.3 suites. This is a particularly
easy place for a request such as “use only these ciphers” to descend into
protocol-version-specific machinery
([O-CIPHERS](sources.md#o-ciphers--openssl-cipher-configuration)).

`libtls` offers one `tls_config_set_ciphers` action. Named profiles include
`secure`, `compat`, `legacy`, and `insecure`; the default expands to a policy
covering TLS 1.3 and AEAD plus ECDHE/DHE for TLS 1.2. It also accepts a raw
`libssl` cipher string. Thus the intermediate layer both supplies policy-sized
actions and deliberately retains a lower-level escape hatch
([L-PROTOCOLS](sources.md#l-protocols--libtls-protocol-and-cipher-policy),
[L-DEFAULT-SRC](sources.md#l-default-src--libtls-default-policy-source)).

## Job 5: ALPN

### OpenSSL

A client packs its ordered protocol names into the TLS wire format—nonempty
8-bit-length-prefixed byte strings—and passes the buffer to
`SSL_CTX_set_alpn_protos` or `SSL_set_alpn_protos`. These two setters return 0
on success, the reverse of the usual positive-success convention.

A server installs an application callback using
`SSL_CTX_set_alpn_select_cb`. The callback receives the client's wire-format
list, must select one entry, must satisfy pointer-lifetime rules, and returns a
TLS-extension status. `SSL_select_next_proto` is a helper for overlap
selection, but the caller still owns the callback. After handshake,
`SSL_get0_alpn_selected` returns a borrowed, non-NUL-terminated value
([O-ALPN](sources.md#o-alpn--openssl-alpn-manual)).

### `libtls`

Both roles call `tls_config_set_alpn(config, "h2,http/1.1")` with a
comma-separated list. The library encodes it, installs its own server callback,
and exposes the result as connection information. This intermediate action
collapses wire encoding, callback setup, overlap selection, and pointer
lifetime. It also chooses the library's selection behavior, so the reduction
is not control-free: a caller needing an unusual server selection algorithm
would use lower-level `libssl` or another escape point
([L-CONFIG](sources.md#l-config--libtls-policy-and-keypair-manuals),
[L-SERVER-SRC](sources.md#l-server-src--libtls-server-implementation),
[H-LIBTLS](sources.md#h-libtls--official-libtls-design-presentation)).

## Job 6: server credentials, SNI, and client authentication

### One server keypair

OpenSSL's file-oriented surface separates
`SSL_CTX_use_certificate_chain_file`, `SSL_CTX_use_PrivateKey_file`, and,
when the caller wants an explicit consistency check,
`SSL_CTX_check_private_key`. This exposes the certificate/key distinction and
supports many input representations. `SSL_CTX_use_cert_and_key` can combine
already parsed `X509`, `EVP_PKEY`, and chain objects, but is not a single
combined-file loading action.

`libtls` supplies `tls_config_set_keypair_file(config, cert_file, key_file)`
and memory equivalents, plus variants attaching an OCSP staple. The action
still accepts distinct certificate and key sources, but treats installation of
a usable identity as one operation and internally performs the lower-level
loads/checks. It also retains separate `tls_config_set_cert_file` and
`tls_config_set_key_file` actions. This is a useful within-one-library example:
the intermediate keypair action exists alongside its component actions rather
than deleting them.

### Multiple SNI keypairs

The classic OpenSSL pattern described in the official 2017 `libtls`
presentation creates/configures multiple `SSL_CTX` objects, installs a server
name callback, examines the requested name, and switches context with
`SSL_set_SSL_CTX`. Modern OpenSSL also offers ClientHello callbacks and other
certificate-selection facilities, but the caller still supplies selection
logic and observes callback/context lifetime.

With `libtls`, the caller sets a default keypair and repeatedly calls
`tls_config_add_keypair_file` for alternatives. Current source constructs the
underlying contexts and SNI callback and matches names internally. This is a
strong example of one intermediate “add this service identity” action
collapsing a deep callback subgraph
([O-SNI](sources.md#o-sni--openssl-server-name-selection),
[L-KEYPAIR-SRC](sources.md#l-keypair-src--libtls-keypair-and-sni-source),
[H-LIBTLS](sources.md#h-libtls--official-libtls-design-presentation)).

### Requiring client certificates

For a low-level OpenSSL server, the policy normally includes:

- load verification roots with `SSL_CTX_load_verify_locations` or related
  trust-store actions;
- call `SSL_CTX_set_verify` with `SSL_VERIFY_PEER |
  SSL_VERIFY_FAIL_IF_NO_PEER_CERT`;
- if the server wants to advertise acceptable issuer names, separately build
  a `STACK_OF(X509_NAME)`—commonly using `SSL_load_client_CA_file`—and transfer
  it with `SSL_CTX_set_client_CA_list`.

The OpenSSL manual explicitly says the acceptable-CA list sent to clients is
not derived from the verification CA file/path. Trusting an issuer and
advertising an issuer are distinct intentions, but the distinction produces a
notably deep action path for the common mutual-TLS server case
([O-VERIFY](sources.md#o-verify--openssl-verification-mode-and-trust),
[O-CLIENT-CA](sources.md#o-client-ca--openssl-advertised-client-ca-list)).

`libtls` uses its CA configuration plus
`tls_config_verify_client` (required) or
`tls_config_verify_client_optional` (requested but optional). Its server
implementation installs the lower-level trust store, verification callback,
and verify flags. It does **not** call `SSL_CTX_set_client_CA_list` or expose an
equivalent action for separately advertising acceptable issuer names. The
higher-level surface preserves the important required/optional distinction and
hides trust-store machinery, but E080 in the English corpus (“tell clients
which private issuing authorities are acceptable”) requires dropping to
`libssl` or using another surface at this snapshot. This is lost control, not
merely a default moved downward
([L-SERVER-SRC](sources.md#l-server-src--libtls-server-implementation)).

## Job 7: nonblocking operation, failure, and shutdown

### OpenSSL

For `SSL_connect`, `SSL_accept`, `SSL_read_ex`, `SSL_write_ex`, and
`SSL_shutdown` on a nonblocking transport, the caller examines an unsuccessful
result with `SSL_get_error`. `SSL_ERROR_WANT_READ` and
`SSL_ERROR_WANT_WRITE` mean retry when the corresponding readiness condition
holds; a read may need a write and a write may need a read because TLS is a
protocol, not a transparent syscall wrapper. The same operation must be
retried, and write-buffer/length rules apply unless a mode changes them.
Fatal error classification can also require the thread error queue and
`errno`. The official nonblocking guide supplies the external select loop; the
library does not own the application deadline
([O-NONBLOCK](sources.md#o-nonblock--openssl-nonblocking-guide),
[O-ERROR](sources.md#o-error--openssl-error-classification)).

`SSL_shutdown` returns 0 after sending `close_notify` when the peer notification
has not yet arrived, 1 when shutdown is complete, and a negative value for an
error or retry condition; nonblocking callers again use `SSL_get_error`.
Applications may choose a one-way or bidirectional shutdown depending on their
protocol and truncation requirements. The manual also says not to call
`SSL_shutdown` after a fatal error
([O-SHUTDOWN](sources.md#o-shutdown--openssl-orderly-shutdown)).

### `libtls`

`tls_handshake`, `tls_read`, `tls_write`, and `tls_close` return the same public
sentinels, `TLS_WANT_POLLIN` or `TLS_WANT_POLLOUT`, when progress needs socket
readiness. The caller retries the same action. Other failure is `-1`, with a
context-specific string from `tls_error`; successful reads/writes return byte
counts. This collapses `SSL_get_error`, error-queue handling, and several raw
return conventions into one result vocabulary across phases.

It does not provide an event loop or a timeout policy. OpenBSD `nc`, a real
`libtls` user, wraps handshake in its own poll/timeout logic. `tls_connect_socket`
and callback variants make it possible to retain application transport control
([L-READ](sources.md#l-read--libtls-handshake-io-and-close-manual),
[L-NC](sources.md#l-nc--openbsd-netcat-as-a-libtls-client-and-server)).

`tls_close` drives the underlying `SSL_shutdown`, translates WANT results, and
closes the socket when the context owns a socket created by `tls_connect`.
When the caller supplied descriptors/callbacks, transport ownership remains
outside. In the inspected source, a zero return from the single
`SSL_shutdown` call (local notification sent, peer notification not yet
received) is not exposed as an incomplete bidirectional shutdown; `tls_close`
continues to finish. An EOF previously observed without `close_notify` is
reported as an error. The simpler public action therefore embodies a
shutdown/truncation policy as well as resource convenience
([L-IO-SRC](sources.md#l-io-src--libtls-io-and-close-implementation)).

## Action depth comparisons

Counts here are descriptive, not scores. A “distinct action” is one named
programmer-visible operation family on the ordinary path; loop repetitions and
error checks do not add to the total. Resource release is shown separately.
Alternate transports and optional policy add actions. The exact count changes
with what an application already owns, which is itself part of the structural
finding.

| Programmer job | Surface and representative visible actions | Approximate action families | What the number says—and does not say |
| --- | --- | ---: | --- |
| Public-DNS blocking client through library-created TCP | OpenSSL guide: context; verify mode; roots; version; connection; resolve; socket; connect; socket BIO; descriptor attach; SSL/BIO attach; SNI; DNS identity; handshake; write; read; classify; shutdown; free connection/context/address resources | 19–21 | Many are sound escape points or resource boundaries; several expose transport and library object structure rather than the user's secure-connect goal. |
| Same client | Documented `libtls`: config; client; configure; connect; write; read; close; free (plus config free; explicit handshake only if desired) | 8–10 | DNS/socket/context/SNI/name/verification/error plumbing moves below `tls_connect`; policy and transport variants remain available. |
| Client over an already-open socket | OpenSSL: omit resolve/socket/connect but retain BIO creation/association, SSL object, SNI/name, handshake, I/O, errors, lifetimes | about 13–15 | Existing transport removes some depth, not authentication or object wiring. |
| Same existing-socket client | `libtls`: config/client/configure; `tls_connect_socket`; I/O; close/free | 7–9 | Direct connect is replaced by a sibling action; the caller retains socket setup and ownership. |
| Server around an accepted socket, one keypair | OpenSSL: context; separate chain/key load (and optional check); SSL; BIO/descriptor association; accept handshake; I/O/error; optional shutdown; frees | about 11–14 plus external accept | Low-level object and credential boundaries stay visible. |
| Same accepted-socket server | `libtls`: config; keypair; server; configure; `tls_accept_socket`; I/O; close/free, plus external accept | 9–11 | Server context and per-connection context remain; callback/BIO/SSL construction is hidden. |
| Server ALPN selection | OpenSSL: encode list; retain storage; write callback; install callback; select overlap; return extension status; later obtain borrowed selection | several actions plus callback path | Depth comes from protocol extension wire format and callback/lifetime rules. It preserves custom selection control. |
| Same ALPN policy | `libtls`: `tls_config_set_alpn` with comma list; later inspect connection result | 1 setup action | Encoding and the standard selection callback move below; unusual selection policy is no longer expressible at this layer. |
| Multiple SNI server certificates | Classic OpenSSL: build contexts/keypairs; callback; inspect SNI; select; switch context; manage all lifetimes | deep callback subgraph | The calls expose flexible dynamic policy and `SSL_CTX` structure. |
| Same common name-based selection | `libtls`: set default keypair; add alternative keypairs | one repeated action family | The common selection algorithm moves down; the lower-level API remains available for special cases. |
| Required client certificate with issuer hint | OpenSSL: configure verification roots; verify flags; independently build/load acceptable-name list; transfer ownership; handshake | two related configuration branches | The separate trust and advertised-authority concepts are real, but easy to conflate. |
| Same required-client-certificate policy | `libtls`: configure CA; `tls_config_verify_client` | 2 policy actions | It collapses trust-store loading and verify flags while retaining required versus optional client auth; it does not expose the separate acceptable-CA-list hint. |

## Where hierarchy becomes deepest

1. **A verified client from a bare hostname.** The goal crosses resolver,
   socket, BIO, `SSL`, `SSL_CTX`, X.509 trust, SNI, reference identity,
   handshake, error, and lifetime layers in the OpenSSL guide.
2. **Server ALPN.** A policy list becomes wire encoding, a callback with a
   special return vocabulary, overlap selection, and borrowed-pointer rules.
3. **Multiple server certificates.** The name-to-identity decision becomes a
   callback and a switch among separately configured reusable contexts.
4. **Mutual-TLS acceptable issuers.** Verification trust and the issuer-name
   hint sent to clients require separate object/configuration paths.
5. **Nonblocking shutdown.** A conceptual close action can require repeated
   protocol steps, readiness direction unrelated to the apparent action, raw
   error classification, and an application deadline.

These depths have mixed causes. Some express genuine policy distinctions; some
are necessary ownership boundaries; some expose the library's composition;
some expose TLS protocol machinery.

## What is preserved and what moves downward

| Concern | OpenSSL/LibreSSL `libssl` visibility | `libtls` treatment |
| --- | --- | --- |
| Reusable policy vs per-connection state | `SSL_CTX` and `SSL` | Preserved as `tls_config` and `tls`; server also returns a per-connection `tls`. |
| Transport ownership | BIO/fd association and ownership flags are explicit | Common client path owns its created socket; socket/fd/callback variants preserve caller ownership. |
| Verification opt-in | Explicit positive setup; off by default in OpenSSL | Certificate, name, and time checks are safe defaults; opt-outs are labelled insecure. |
| Route name vs authenticated name | Separate transport, SNI, and reference-name actions | Common case inferred by `tls_connect`; `tls_connect_servername` and existing-transport variants separate them. |
| Protocol/cipher policy | Version-specific setters and raw rule strings | Default named policy plus version mask/profiles; raw cipher string remains an escape. |
| Handshake boundary | Explicit `SSL_connect`/`SSL_accept` | Optional explicit `tls_handshake`; otherwise first I/O drives it. |
| Error machinery | Operation result plus `SSL_get_error`, ERR queue, `errno` | Uniform WANT sentinels or `-1`, one context error interface. |
| ALPN | Wire-format buffer; server callback; pointer lifetimes | Comma-separated policy action and built-in selection callback. |
| Acceptable client-CA advertisement | Separate name-list construction and ownership transfer | No corresponding public action in the inspected `libtls`; requiring a client certificate remains available. |
| X.509/ASN.1 objects | Public and richly controllable | Not exposed by the basic API; connection-info accessors provide selected facts. |

Collapsing actions can remove useful control, move a reasonable default down,
or both. `libtls` is not simply “the same API with fewer calls”: it selects
policy, encodes common selection behavior, narrows exposed object types, and
offers transport/configuration alternatives where its designers judged them
important.

## Corrections to the starting premise

1. The intermediate layer is **OpenBSD `libtls` over LibreSSL**, not “the
   LibreSSL API” as a synonym. Direct LibreSSL `libssl` remains low-level.
2. OpenSSL is not devoid of intermediate composition. SSL BIO chains can join
   connection, handshake, and I/O plumbing, and its high-level setters have
   evolved. They do not, however, install the same safe goal-level policy as
   `libtls`.
3. The most striking historical hostname-verification comparison has aged.
   The 2017 presentation contrasts `libtls` with a caller-managed
   `X509_check_host`; modern OpenSSL integrates reference-name checking into
   handshake verification through `SSL_set1_dnsname`/`SSL_set1_ipaddr`
   (formerly `SSL_set1_host`). The caller still separately enables peer
   verification, loads roots, configures SNI, and configures the reference
   identity.
4. “Fewer calls” is not a sufficient account. A direct `tls_connect` owns
   resolution and socket setup, while `tls_connect_socket`, `_fds`, and `_cbs`
   keep those concerns outside. The apparent depth depends on the transport
   boundary the programmer actually wants.
5. `libtls` does not collapse everything. It keeps configuration separate from
   a connection, server policy separate from accepted connections, optional
   from required client authentication, and explicit handshake available when
   application ordering requires it.
6. Some control is removed rather than defaulted: `libtls` can require client
   certificates but has no public action for the distinct acceptable-CA-name
   list that `libssl` can send in a certificate request.
7. Timeouts and event loops remain application concerns in both investigated
   surfaces. `libtls` simplifies readiness results but does not turn “finish in
   five seconds” into a library-owned action.

## Questions deliberately left open

This investigation does not decide:

- which of these levels should become Adriç actions;
- whether any English phrases are formal synonyms;
- how defaults, preferences, prohibitions, fallback, deadlines, or ownership
  should be represented;
- whether policy profiles should be stable names or evolving environment
  choices;
- how a later compiler chooses between `libtls`, OpenSSL, LibreSSL `libssl`, or
  another implementation;
- what types, facts, metadata, constraints, effects, or cost models attach to
  any action;
- whether loss of a particular low-level control is acceptable.

The trees and graphs in [trees.md](trees.md) and [graphs.md](graphs.md) retain
these layers so that those questions can be asked later from concrete evidence.
