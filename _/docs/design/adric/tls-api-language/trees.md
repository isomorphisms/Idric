# TLS action trees

Trees are intentionally lossy: they show conceptual descent or action
containment, while [graphs.md](graphs.md) records cross-cutting order,
configuration, ownership, optionality, and retry edges.

The actual sequences are sourced in [api-structure.md](api-structure.md), with
exact primary-source revisions in [sources.md](sources.md).

The two kinds of tree below must not be confused:

- **conceptual action trees** group actions by the human job they contribute
  to; grouping nodes are not proposed APIs or Adriç syntax;
- **actual-call trees** name programmer-visible symbols, or (when explicitly
  labelled internal) symbols that a higher layer calls on the programmer's
  behalf.

## Conceptual action trees

### Client: common intent, independent of one API

This grouping is distilled from the concrete flows, not asserted as a final
hierarchy.

```text
establish authenticated TLS client connection
├── choose reusable connection policy
│   ├── choose trust roots
│   ├── require peer-certificate verification
│   ├── choose authenticated DNS name or IP address
│   ├── choose protocol-version policy
│   ├── choose cipher policy
│   ├── optionally choose ALPN offers
│   └── optionally choose client identity
├── establish or receive transport
│   ├── optionally resolve route name
│   ├── optionally try candidate addresses
│   ├── optionally create and connect socket
│   └── bind transport to TLS connection state
├── establish TLS session
│   ├── send SNI when appropriate
│   ├── perform protocol handshake
│   ├── validate certificate chain and time
│   ├── validate DNS name or IP identity
│   └── optionally inspect negotiated properties
├── exchange application data
│   ├── write, possibly in repeated progress steps
│   └── read, possibly in repeated progress steps
└── finish
    ├── attempt TLS close notification
    ├── optionally await peer close notification
    ├── release or return transport according to ownership
    └── release per-connection and reusable state
```

The many “optionally” labels do not mean the security property is optional.
They indicate that an action may be inherited from policy, performed by a
different layer, or unnecessary for a caller-supplied transport.

### Server: common intent, independent of one API

```text
accept authenticated TLS server connection
├── choose reusable server policy
│   ├── install default server certificate and private key
│   ├── optionally install alternative SNI identities
│   ├── choose protocol-version and cipher policy
│   ├── optionally choose ALPN selection policy
│   ├── optionally choose client-certificate trust roots
│   └── choose whether client authentication is required or optional
├── prepare or receive listening transport
├── obtain accepted transport connection
├── create per-connection TLS state
├── establish TLS session
│   ├── optionally select identity from SNI
│   ├── optionally select application protocol
│   ├── perform server handshake
│   └── optionally authenticate client certificate
├── exchange application data
└── close and release per-connection and reusable state
```

## Actual programmer-visible call trees

These trees show representative ordinary paths, not every API member. Sibling
actions marked “alternative” are not all invoked together.

### OpenSSL 4.0.2 `libssl`: blocking client from hostname

```text
client connection
├── reusable SSL configuration
│   ├── SSL_CTX_new(TLS_client_method())
│   ├── SSL_CTX_set_verify(..., SSL_VERIFY_PEER, ...)
│   ├── SSL_CTX_set_default_verify_paths(...)
│   ├── SSL_CTX_set_min_proto_version(..., TLS1_2_VERSION)
│   ├── optional policy setters
│   │   ├── SSL_CTX_set_max_proto_version(...)
│   │   ├── SSL_CTX_set_cipher_list(...)            [TLS <= 1.2]
│   │   ├── SSL_CTX_set_ciphersuites(...)           [TLS 1.3]
│   │   ├── SSL_CTX_set_alpn_protos(... wire bytes ...)
│   │   └── SSL_CTX_use_certificate_chain_file(...) +
│   │       SSL_CTX_use_PrivateKey_file(...)         [client identity]
│   └── SSL_CTX_free(...)                            [release caller reference]
├── per-connection TLS state
│   ├── SSL_new(ctx)
│   ├── SSL_set_tlsext_host_name(ssl, dnsname)       [SNI]
│   ├── SSL_set1_dnsname(ssl, dnsname)               [certificate identity]
│   └── SSL_free(ssl)
├── transport created by official guide helper
│   ├── BIO_lookup_ex(host, port, ...)
│   ├── for each BIO_ADDRINFO candidate
│   │   ├── BIO_socket(...)
│   │   ├── BIO_connect(...)
│   │   └── BIO_closesocket(...)                     [failed candidate]
│   ├── BIO_new(BIO_s_socket())
│   ├── BIO_set_fd(bio, socket, BIO_CLOSE)
│   ├── SSL_set_bio(ssl, bio, bio)                   [ownership to SSL]
│   └── BIO_ADDRINFO_free(...)
├── establish TLS
│   ├── SSL_connect(ssl)
│   └── optional SSL_get_verify_result(ssl)           [diagnosis]
├── exchange data
│   ├── SSL_write_ex(ssl, ...)
│   ├── SSL_read_ex(ssl, ...)
│   └── SSL_get_error(ssl, operation_result)          [on non-success]
└── finish
    ├── SSL_shutdown(ssl)
    └── SSL_free(ssl)                                 [also BIO + owned socket]
```

`SSL_CTX_free` is drawn under configuration and `SSL_free` under both state and
finish to show the lifetime end; it is one call, not two.

### OpenSSL 4.0.2: composing SSL BIO alternative

```text
client connection through SSL BIO chain
├── SSL_CTX_new(TLS_client_method())
├── configure verification, trust, versions, and other policy on SSL_CTX
├── BIO_new_ssl_connect(ctx)
│   ├── creates SSL BIO
│   └── chains connect BIO below it
├── BIO_get_ssl(chain, &ssl)
│   ├── SSL_set_tlsext_host_name(ssl, dnsname)
│   └── SSL_set1_dnsname(ssl, dnsname)
├── BIO_set_host(chain, host_and_service)
├── BIO_do_connect(chain) / BIO_do_handshake(chain)
├── BIO_write_ex(chain, ...) / BIO_read_ex(chain, ...)
├── optional BIO_ssl_shutdown(chain)
└── BIO_free_all(chain)
```

This tree is shallower in transport composition than the guide's explicit
socket/BIO path, but verification policy is not supplied by
`BIO_new_ssl_connect`.

### LibreSSL 4.3.2 `libssl`: direct low-level client shape

```text
client connection
├── SSL_CTX_new(TLS_client_method())
│   ├── SSL_CTX_set_verify(..., SSL_VERIFY_PEER, ...)
│   ├── SSL_CTX_set_default_verify_paths(...)
│   └── optional SSL_CTX policy setters
├── SSL_new(ctx)
├── associate caller-created BIO or descriptor
│   └── SSL_set_bio(ssl, read_bio, write_bio)
├── SSL_set_tlsext_host_name(ssl, dnsname)             [SNI]
├── SSL_set1_host(ssl, hostname)                       [certificate identity]
├── SSL_connect(ssl)
├── SSL_write_ex(ssl, ...) / SSL_read_ex(ssl, ...)
│   └── SSL_get_error(ssl, operation_result)           [on non-success]
├── SSL_shutdown(ssl)
├── SSL_free(ssl)
└── SSL_CTX_free(ctx)
```

This tree establishes that direct LibreSSL `libssl` is in the low-level
family. It is not meant to claim byte-for-byte compatibility with OpenSSL 4.0.

### OpenBSD `libtls`: client from hostname

```text
client connection
├── reusable policy
│   ├── tls_config_new()
│   ├── optional tls_config_set_* actions
│   │   ├── tls_config_set_ca_file/path/mem(...)
│   │   ├── tls_config_set_protocols(...)
│   │   ├── tls_config_set_ciphers(...)
│   │   ├── tls_config_set_alpn(... comma list ...)
│   │   └── tls_config_set_keypair_file/mem(...)      [client identity]
│   ├── tls_configure(client_ctx, config)
│   └── tls_config_free(config)                       [after final configure]
├── connection object
│   └── tls_client()
├── establish route and TLS                           [choose one alternative]
│   ├── tls_connect(ctx, host, port)                  [opens socket]
│   ├── tls_connect_servername(ctx, host, port, name) [route/name differ]
│   ├── tls_connect_socket(ctx, fd, name)             [existing socket]
│   ├── tls_connect_fds(ctx, rfd, wfd, name)          [existing descriptors]
│   └── tls_connect_cbs(ctx, read_cb, write_cb, arg, name)
├── optional tls_handshake(ctx)                       [read/write can drive it]
├── exchange data
│   ├── tls_write(ctx, ...)
│   └── tls_read(ctx, ...)
├── tls_close(ctx)
└── tls_free(ctx)
```

### OpenSSL 4.0.2 `libssl`: server using accept BIO

```text
TLS server
├── reusable SSL configuration
│   ├── SSL_CTX_new(TLS_server_method())
│   ├── SSL_CTX_set_min_proto_version(...)
│   ├── SSL_CTX_set_options(...)
│   ├── SSL_CTX_use_certificate_chain_file(...)
│   ├── SSL_CTX_use_PrivateKey_file(...)
│   ├── optional session-cache actions
│   │   ├── SSL_CTX_set_session_id_context(...)
│   │   ├── SSL_CTX_set_session_cache_mode(...)
│   │   ├── SSL_CTX_sess_set_cache_size(...)
│   │   └── SSL_CTX_set_timeout(...)
│   ├── optional client-auth actions
│   │   ├── SSL_CTX_load_verify_locations(...)
│   │   ├── SSL_CTX_set_verify(...)
│   │   ├── SSL_load_client_CA_file(...)
│   │   └── SSL_CTX_set_client_CA_list(...)
│   └── SSL_CTX_free(...)                            [release caller reference]
├── listener
│   ├── BIO_new_accept(address)
│   ├── BIO_set_bind_mode(...)
│   ├── BIO_do_accept(listener)                       [initialise/listen]
│   └── for each transport connection
│       ├── BIO_do_accept(listener)                   [accept]
│       └── BIO_pop(listener)                         [connected BIO]
├── per-connection TLS state
│   ├── SSL_new(ctx)
│   ├── SSL_set_bio(ssl, connected_bio, connected_bio)
│   ├── SSL_accept(ssl)
│   ├── SSL_read_ex(...) / SSL_write_ex(...)
│   │   └── SSL_get_error(...)                       [on non-success]
│   ├── optional SSL_shutdown(ssl)                    [not in guide server]
│   └── SSL_free(ssl)                                [also connected BIO]
└── BIO_free_all(listener)
```

### OpenBSD `libtls`: server around application-accepted socket

```text
TLS server
├── reusable policy
│   ├── tls_config_new()
│   ├── tls_config_set_keypair_file(config, cert, key)
│   ├── optional tls_config_add_keypair_file(...)     [alternative SNI IDs]
│   ├── optional tls_config_set_protocols/ciphers/alpn(...)
│   ├── optional client-auth policy
│   │   ├── tls_config_set_ca_file/path/mem(...)
│   │   └── tls_config_verify_client(config) or
│   │       tls_config_verify_client_optional(config)
│   ├── tls_configure(server_ctx, config)
│   └── tls_config_free(config)                       [after final configure]
├── server context
│   └── tls_server()
├── application listener and accept actions          [outside libtls]
└── for each accepted transport
    ├── create connection context                    [choose one alternative]
    │   ├── tls_accept_socket(server_ctx, &conn_ctx, fd)
    │   ├── tls_accept_fds(server_ctx, &conn_ctx, rfd, wfd)
    │   └── tls_accept_cbs(server_ctx, &conn_ctx, callbacks, arg)
    └── use returned connection context
        ├── optional tls_handshake(conn_ctx)
        ├── tls_read(conn_ctx, ...) / tls_write(conn_ctx, ...)
        ├── tls_close(conn_ctx)
        └── tls_free(conn_ctx)
```

The connection actions are children of each accepted transport, not of
`tls_server()` in call syntax. The nesting records the lifecycle relationship.

## Actual lower-level work hidden by selected `libtls` actions

The following are implementation call trees in LibreSSL/OpenBSD 4.3.2. They
show what “disappeared” from the public surface. They are not calls a `libtls`
user makes.

### `tls_connect` and client handshake (internal)

```text
tls_connect(ctx, host, port)                          [public]
├── tls_connect_servername(...)
│   ├── getaddrinfo(...)
│   ├── socket(...) + connect(...) over candidates
│   └── tls_connect_socket/fds(...)
│       ├── SSL_CTX_new(SSLv23_client_method())
│       ├── apply protocol/cipher/trust/verify/curve/keypair policy
│       ├── SSL_new(ssl_ctx)
│       ├── attach fd/callback BIO plumbing
│       ├── request OCSP status
│       └── SSL_set_tlsext_host_name(...)             [DNS names only]
└── tls_handshake(ctx)                                [explicit or first I/O]
    └── tls_handshake_client(ctx)
        ├── SSL_connect(ssl)
        ├── SSL_get_peer_certificate(ssl)
        └── tls_check_name(certificate, servername)
```

### `tls_server` configuration and per-connection handshake (internal)

```text
tls_configure(server_ctx, config)                     [public]
└── tls_configure_server(...)
    ├── SSL_CTX_new(SSLv23_server_method())
    ├── SSL_CTX_set_tlsext_servername_callback(...)
    ├── apply default keypair and policy
    ├── construct SSL_CTX for each alternative keypair
    ├── optionally SSL_CTX_set_alpn_select_cb(...)
    ├── optionally configure client-certificate verification
    └── configure curves/DHE/cipher preference/tickets/sessions/OCSP

tls_accept_socket(server_ctx, &conn_ctx, fd)          [public]
└── tls_accept_fds(...)
    ├── allocate per-connection tls context
    ├── SSL_new(server_ssl_ctx)
    ├── attach fd/callback BIO plumbing
    └── tls_handshake(conn_ctx)                       [explicit or first I/O]
        └── SSL_accept(ssl)
```

### I/O and close (internal)

```text
tls_read(ctx, ...)                                    [public]
├── tls_handshake(ctx)                                [if incomplete]
├── SSL_read(ssl, ...)
└── tls_ssl_error(...)                                [maps WANT/error]

tls_write(ctx, ...)                                   [public]
├── tls_handshake(ctx)                                [if incomplete]
├── SSL_write(ssl, ...)
└── tls_ssl_error(...)                                [maps WANT/error]

tls_close(ctx)                                        [public]
├── SSL_shutdown(ssl)
├── tls_ssl_error(...)                                [maps WANT/error]
└── shutdown/close owned socket                       [direct-connect path]
```

## Tree-reading cautions

- A deeper tree is not automatically worse. It may expose a distinction the
  application genuinely needs.
- A shallow public tree can contain a deep implementation tree. The useful
  question is whether its boundary matches programmer intent and preserves the
  needed escape points.
- Tree parenthood is not enough to infer ordering or ownership. For example,
  `SSL_CTX` can outlive many sibling `SSL` objects, and `tls_config` can be
  freed after configuration because `libtls` retains it. Those relationships
  are recorded explicitly in [graphs.md](graphs.md).
- The trees describe APIs, not proposed Adriç grammar, types, constraints, or
  action metadata.
