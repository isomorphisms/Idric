# TLS action dependency graphs

These graphs supplement [trees.md](trees.md). They name actual objects and
actions, while using grouping labels only to keep the diagrams readable. They
are plain text so that ordering, configuration, ownership, and optionality
remain inspectable without a graph renderer.

The public contracts and implementation traces behind each graph are cited in
[api-structure.md](api-structure.md); exact snapshots and source paths are in
[sources.md](sources.md).

## Notation

```text
A --order--> B          B happens after successful A on this path
A --config--> B         B consumes policy or state established by A
A --creates--> B        A creates B
A --owns--> B           A is responsible for B's lifetime
A --retains--> B        A takes or increments a reference to B
A --transfer--> B       ownership moves from A to B
A -.optional.-> B       B is conditional, diagnostic, or separable
A --retry:X--> A        retry the same action after readiness condition X
{ A | B }               choose one alternative on the ordinary path
```

An edge describes the inspected API contract or reference implementation; it
does not propose Adriç semantics.

## OpenSSL 4.0.2 blocking client

### Configuration, transport, and handshake

```text
SSL_CTX_new(TLS_client_method)
  --creates--> SSL_CTX

SSL_CTX_set_verify(SSL_VERIFY_PEER) ---------config--+
SSL_CTX_set_default_verify_paths -------------------+--> SSL_CTX
SSL_CTX_set_min_proto_version ----------------------+      |
optional context policy setters -.config.-----------+      |
                                                          config
                                                            v
SSL_CTX -------------------------------------------> SSL_new
                                                     --creates--> SSL

BIO_lookup_ex --order--> BIO_socket --order--> BIO_connect
                                         | failure: close and try next address
                                         v success
BIO_new(BIO_s_socket) --order--> BIO_set_fd(BIO_CLOSE) --order--> socket BIO
socket BIO --transfer--> SSL_set_bio ---------------------------> SSL owns BIO
                                                                  |
                                                                  +--owns--> socket

SSL_set_tlsext_host_name(SNI) ----------------config--+
SSL_set1_dnsname(reference identity) ----------config--+--> SSL_connect
SSL_CTX verification/trust/version policy -----config--+       |
attached transport ----------------------------config--+       |
                                                               order
                                                                 v
                                               authenticated TLS session
```

Configuration dependencies are deliberately separate: a transport destination
does not configure certificate identity, and SNI does not configure hostname
verification.

### I/O, error classification, shutdown, and lifetime

```text
SSL_connect --order--> { SSL_write_ex | SSL_read_ex }
                            |                 |
                            +--non-success----+
                                      |
                                      v
                         SSL_get_error(ssl, exact_result)
                         |       |       |       |
                         |       |       |       +--> fatal / syscall / TLS error
                         |       |       +----------> ZERO_RETURN (close_notify)
                         |       +------------------> WANT_WRITE
                         +--------------------------> WANT_READ

SSL_write_ex --retry:requested readiness--> same SSL_write_ex
SSL_read_ex  --retry:requested readiness--> same SSL_read_ex

last application action --order--> SSL_shutdown
SSL_shutdown --retry:WANT_READ/WRITE or result 0--> SSL_shutdown
fatal TLS/protocol error --order--> SSL_free            [skip SSL_shutdown]

SSL_set_bio --transfer--> SSL --owns--> BIO --owns(BIO_CLOSE)--> socket
SSL_free --releases--> { SSL, BIO, socket }

SSL_new --retains--> SSL_CTX reference
caller SSL_CTX_free --releases--> caller's SSL_CTX reference
SSL_free --releases--> SSL-held SSL_CTX reference
last context reference released --destroys--> SSL_CTX
```

The official blocking guide calls `SSL_shutdown` once; the public shutdown
contract permits another call to wait for the peer notification. The graph
shows the more general dependency, not a requirement that every application
wait bidirectionally.

## OpenSSL SSL-BIO composition path

```text
configured SSL_CTX --config--> BIO_new_ssl_connect
BIO_new_ssl_connect --creates--> SSL BIO --owns--> connect BIO
BIO_get_ssl --------------------observes----------------> SSL inside chain
BIO_set_host -------------------config-----------------> connect BIO
{ SNI setter, DNS identity setter } --config----------> SSL inside chain

BIO_do_connect / BIO_do_handshake
  --uses--> { connect BIO, SSL BIO, configured SSL }
  --order--> BIO_read_ex / BIO_write_ex

BIO_free_all --releases--> complete BIO chain
```

This removes explicit socket-BIO assembly from the application graph. It does
not remove the verification, trust, SNI, or reference-identity dependencies.

## OpenBSD `libtls` client

### Documented public lifecycle

```text
tls_config_new --creates--> tls_config
optional tls_config_set_* --config--> tls_config

tls_client --creates--> client tls context
tls_config ----------------------config----> tls_configure(client, config)
client tls context --------------target----> tls_configure(client, config)
tls_configure --retains--> tls_config
tls_configure --order--> tls_config_free(config)       [safe after final use]

configured client
  --order--> { tls_connect(host, port)
             | tls_connect_servername(route, port, name)
             | tls_connect_socket(fd, name)
             | tls_connect_fds(rfd, wfd, name)
             | tls_connect_cbs(read_cb, write_cb, arg, name) }

selected connect action --order--> optional tls_handshake
selected connect action --order--> { tls_read | tls_write } [auto-handshake]
tls_handshake --order--> { tls_read | tls_write }
{ tls_read | tls_write } --order--> tls_close --order--> tls_free
```

There are two valid edges into I/O: explicit handshake completion when the
application cares about the boundary, or automatic handshake on first I/O.

### Transport ownership alternatives

```text
tls_connect / tls_connect_servername
  --creates--> resolved-address list
  --creates--> connected socket
  --owns--> connected socket
  --config--> verification name (inferred or explicit)

tls_connect_socket / tls_connect_fds
  --borrows/uses--> caller descriptors
  --does-not-own--> caller transport lifetime

tls_connect_cbs
  --retains-for-use--> callback pointers + callback argument
  --does-not-own--> callback backing transport

tls_close after direct tls_connect --releases--> owned socket
tls_close after socket/fds/cbs ----leaves------> caller transport responsibility
```

### Hidden implementation dependencies of `tls_connect`

```text
tls_connect
  --internal-order--> getaddrinfo --> socket/connect candidate loop
  --internal-order--> tls_connect_fds

tls_connect_fds
  --internal-creates--> SSL_CTX
  --internal-config--> protocol + cipher + trust + verification + keypair + OCSP
  --internal-creates--> SSL
  --internal-attaches--> fd/callback BIO
  --internal-config--> SNI for a DNS name

tls_handshake_client
  --internal-order--> SSL_connect
  --internal-order--> SSL_get_peer_certificate
  --internal-order--> tls_check_name
  --produces--> authenticated libtls connection
```

The public one-node connection action therefore overlays a multi-object
low-level graph rather than deleting it.

### Uniform readiness and error graph

```text
                         +--> TLS_WANT_POLLIN  --wait readable--+
                         |                                    |
{ tls_handshake,         +--> TLS_WANT_POLLOUT --wait writable-+--> retry same action
  tls_read, tls_write,   |
  tls_close } -----------+--> -1 ---------------> tls_error(ctx)
                         |
                         +--> success / byte count
```

The readiness direction can differ from the apparent data direction. `libtls`
normalises how that fact is reported; it does not supply the poller or deadline.

## Server object and action dependencies

### OpenSSL 4.0.2 server with an accept BIO

```text
SSL_CTX_new(TLS_server_method) --creates--> server SSL_CTX
certificate-chain loader -------------config--+
private-key loader --------------------config--+--> server SSL_CTX
version/options/session policy --------config--+
optional client-auth policy -----------config--+

BIO_new_accept --creates--> listener BIO
BIO_set_bind_mode --config--> listener BIO
first BIO_do_accept --order--> listener ready
listener ready --order--> later BIO_do_accept --creates--> connected BIO
BIO_pop --transfer--> application owns connected BIO

server SSL_CTX --config--> SSL_new --creates--> per-connection SSL
connected BIO --transfer--> SSL_set_bio --owns--> per-connection SSL
per-connection SSL --order--> SSL_accept --order--> read/write
read/write -.optional orderly close.-> SSL_shutdown --order--> SSL_free
read/write --order--> SSL_free                         [guide example path]

listener BIO --owns--> listening socket
BIO_free_all(listener) --releases--> listener + listening socket
SSL_new --retains--> server SSL_CTX reference
caller SSL_CTX_free --releases--> caller's server-context reference
SSL_free --releases--> per-connection reference to server SSL_CTX
```

### `libtls` server around an application-accepted socket

```text
tls_config_new --creates--> server config
tls_config_set_keypair_file --------config--+
optional tls_config_add_keypair_file -------+
optional protocol/cipher/ALPN policy --------+--> server config
optional CA + verify-client policy ----------+

tls_server --creates--> server tls context
server config + server context --config--> tls_configure
tls_configure --retains--> server config

application listener --order--> application accept --creates--> connected socket
configured server + connected socket
  --inputs--> { tls_accept_socket | tls_accept_fds | tls_accept_cbs }
selected accept action --creates--> per-connection tls context

per-connection context --order--> optional tls_handshake
per-connection context --order--> read/write [auto-handshake alternative]
read/write --order--> tls_close --order--> tls_free(per-connection)

per-connection context --retains--> server configuration reference
per-connection SSL --retains--> underlying server SSL_CTX reference
server tls context --must-outlive--> handshakes using its SNI/ALPN callback args
normal server lifecycle --order--> tls_free(server context) after connections
application --owns--> accepted socket supplied to tls_accept_socket
```

The public `tls_accept_socket` action does not accept TCP; it depends on an
already accepted descriptor. It combines per-connection TLS allocation,
underlying `SSL` creation, and transport attachment. The “normal server
lifecycle” edge is the conservative application order shown by the public
flow, not a claim that every internal reference disappears only when the
connection context is freed.

## ALPN dependency comparison

### OpenSSL server ALPN

```text
human protocol preference list
  --application encodes--> length-prefixed wire buffer
  --application retains--> buffer/callback state

application selection function
  --may call--> SSL_select_next_proto
  --sets--> selected pointer + length
  --returns--> SSL_TLSEXT_ERR_* status

wire buffer + callback + callback argument
  --config--> SSL_CTX_set_alpn_select_cb
  --invoked-during--> SSL_accept handshake

successful handshake
  --order--> SSL_get0_alpn_selected
  --returns--> borrowed pointer + length
```

### `libtls` server ALPN

```text
comma-separated preference list
  --config--> tls_config_set_alpn
  --internal-encodes--> wire list
  --internal-installs--> tls_server_alpn_cb
  --internal-selects--> overlap during handshake

successful handshake
  --order--> tls_conn_alpn_selected
  --returns--> context-owned string
```

The public action graph is smaller because the encoding, callback, selection,
and lifetime subgraph is owned by `libtls`.

## Multiple server identities through SNI

### Classic low-level `libssl` structure

```text
default SSL_CTX --config--> default certificate + key
alternate SSL_CTX[1..n] --config--> certificate + key for each identity

server-name callback
  --observes--> requested SNI
  --selects--> matching SSL_CTX
  --calls--> SSL_set_SSL_CTX(connection, selected context)

all SSL_CTX objects --must-outlive--> callback uses + associated handshakes
```

### `libtls` structure

```text
tls_config_set_keypair_file --config--> default identity
tls_config_add_keypair_file [repeated] --config--> alternative identities
tls_configure(server, config)
  --internal-creates--> SSL_CTX per usable keypair
  --internal-installs--> SNI callback
  --internal-matches--> certificate names against requested SNI
```

This is a clear instance of a repeated intermediate action replacing a
callback/lifetime graph. It also moves the matching policy below the public
boundary.

## Required client-certificate authentication

### OpenSSL server

```text
verification CA file/path
  --config--> SSL_CTX_load_verify_locations
  --config--> X509_STORE used to authenticate client chain

SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT
  --config--> SSL_CTX_set_verify

client-CA names
  --load/build--> STACK_OF(X509_NAME)
  --transfer--> SSL_CTX_set_client_CA_list
  --config--> acceptable-authorities handshake hint

trust store --------------------+
verify mode --------------------+--> SSL_accept authenticates/requires client
acceptable-authority list ------+
```

The two CA branches are related but not identical: one verifies; one tells the
client which issuers are acceptable.

### `libtls` server

```text
tls_config_set_ca_file/path/mem --config--> client trust
tls_config_verify_client -------config--> certificate required
             or
tls_config_verify_client_optional --config--> certificate requested, not required

configured policy --internal-expands--> libssl trust store + verify mode
acceptable-CA-name advertisement ------> no public libtls action
```

The last line is an absent edge, not a hidden one: the inspected `libtls`
server source does not populate `libssl`'s separate client-CA list.

## Graph-level observations

- The OpenSSL/LibreSSL low-level surfaces expose multiple independently useful
  object lifetimes. They are not merely gratuitous calls.
- `libtls` retains reusable policy and per-connection objects, but moves BIO,
  X.509, callback, and raw error-queue nodes below its boundary.
- Direct `tls_connect` is shallow partly because it takes transport ownership;
  the `_socket`, `_fds`, and `_cbs` alternatives restore caller-controlled
  boundaries without restoring every underlying `SSL` action.
- Automatic handshake on first `tls_read`/`tls_write` removes a mandatory
  public ordering edge, while explicit `tls_handshake` preserves the boundary
  for “authenticate before application data.”
- Uniform WANT results make four public actions fit the same retry subgraph,
  but timeout and cancellation policy still belong to the surrounding event
  loop.
- None of these graphs determines an Adriç action hierarchy, grammar, type
  system, constraint model, or metadata scheme.
