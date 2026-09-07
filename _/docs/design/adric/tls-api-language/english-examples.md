# Ordinary-English TLS request corpus

This is empirical input for the Adriç experiment.  It is deliberately not a
grammar, a catalogue of formal operators, or a proposed type or constraint
system.  The items below are things a person might reasonably say when asking
software to use TLS.  They range from broad goals to requests that expose
substantial policy.

Each numbered line is one corpus example.  Families collect requests with a
similar rough human goal so that later work can study different phrasings.
Membership in a family does **not** assert exact semantic equivalence.  The
notes call out important differences and ambiguities instead of normalising
them away.

## 1. Establish a client TLS connection

Rough intent: make an authenticated, confidential client connection to a
remote service while saying little about mechanism.

- E001 — Connect securely to `example.com`.
- E002 — Connect to `example.com` using TLS.
- E003 — Establish a secure connection with `example.com`.
- E004 — Open a TLS connection to `example.com` on port 443.
- E005 — Make sure my connection to `example.com` is encrypted and authenticated.
- E006 — Reach `example.com` securely, using the usual safe settings.
- E007 — Connect to `example.com` with TLS, leaving protocol and cipher selection to the secure defaults.
- E008 — Securely connect to `example.com`; choose the ordinary implementation details for me.

Variation notes: E001 and E003 leave the service or port implicit. E005 says
both encryption and authentication, whereas “securely” may be interpreted less
consistently by people. E006–E008 affirmatively delegate some choices rather
than merely omitting them.

## 2. Accept a server TLS connection

Rough intent: accept an incoming connection and act as the authenticated TLS
server.

- E009 — Accept secure connections on port 443.
- E010 — Listen on port 443 and accept clients using TLS.
- E011 — Serve TLS connections with this certificate and private key.
- E012 — Accept an incoming TLS connection, requiring clients to authenticate the server before sending requests.
- E013 — Listen for TLS clients with the service's normal certificate.
- E014 — Accept only encrypted application connections; they must not fall back to plaintext.
- E015 — Serve HTTPS on the existing listening socket.
- E016 — After the application accepts a TCP socket, turn it into a server-side TLS connection.

Variation notes: E009 does not identify server credentials. E011 assumes that
“this” resolves to concrete credential material. E012 expresses a desired
client property that a server cannot itself prove merely by configuring TLS.
E015–E016 differ over who owns transport establishment.

## 3. Authenticate the remote peer before trusting the channel

Rough intent: do not treat a TLS channel as usable until the intended peer has
been authenticated.

- E017 — Authenticate the remote peer before sending any application data.
- E018 — Establish TLS, but do not send the request until the server certificate has been verified.
- E019 — Make sure the peer is authenticated before the connection becomes available to the application.
- E020 — Connect with certificate verification and abort if verification fails.
- E021 — Do not accept an invalid, expired, or not-yet-valid server certificate.
- E022 — Require a valid certificate chain from the remote peer.
- E023 — Exchange application data only after a successful authenticated handshake.
- E024 — If the peer cannot be authenticated, fail the connection without sending credentials.

Variation notes: a valid chain (E022) does not by itself say that the
certificate names the intended host. E021 names time and validity failures but
leaves “invalid” partly open. E017 and E019 can apply to either role; E018,
E020, and E024 read most naturally as client requests.

## 4. Select or constrain protocol versions

Rough intent: control which TLS protocol versions may be negotiated.

- E025 — Connect using TLS 1.3.
- E026 — Connect securely, restricted to TLS 1.3.
- E027 — Require TLS 1.3 for this connection.
- E028 — Connect while forbidding TLS 1.2 and all earlier protocols.
- E029 — Prefer TLS 1.3, but allow TLS 1.2 if the server cannot use 1.3.
- E030 — Use TLS 1.3 if possible; otherwise use TLS 1.2.
- E031 — Require at least TLS 1.2 and allow newer versions.
- E032 — Use the library's secure protocol defaults without enabling obsolete versions.

Variation notes: E025 is conventionally ambiguous between exact, minimum, and
preferred version. E026–E028 intend an exact currently named set. E029–E030
allow fallback. E031 states a lower bound, not an upper bound. E032 delegates
the concrete version set and may therefore change as policy evolves.

## 5. Restrict cipher and cryptographic mechanism choices

Rough intent: constrain handshake mechanisms without necessarily selecting a
single cipher suite.

- E033 — Connect using only the library's secure cipher choices.
- E034 — Restrict the connection to AEAD cipher suites.
- E035 — Allow only cipher suites that provide forward secrecy.
- E036 — Connect without using CBC-mode cipher suites.
- E037 — Forbid RSA key exchange while allowing RSA certificates.
- E038 — Connect while avoiding AES if possible; prefer ChaCha20 when both peers support it.
- E039 — Prefer AES-GCM on hosts with hardware acceleration, otherwise use a secure default.
- E040 — Use TLS 1.3 ciphers only, and do not silently relax that restriction.

Variation notes: E035 depends on the negotiated version and how mechanisms are
classified. E037 deliberately distinguishes certificate authentication from
key exchange. E038–E039 express preferences rather than simple allow lists.
E040 may duplicate a TLS-version restriction or may merely constrain the
TLS-1.3 cipher-suite namespace; the speaker's intent is unclear.

## 6. Choose trust roots

Rough intent: say which authorities are trusted to authenticate the peer.

- E041 — Connect using the system trust store.
- E042 — Verify the server with this CA certificate.
- E043 — Trust only certificates chaining to this private CA.
- E044 — Use this CA bundle in addition to the system trust store.
- E045 — Connect without using the system trust store.
- E046 — Require the server certificate to chain to one of these trust roots.
- E047 — Use the application's bundled trust roots rather than machine-local configuration.
- E048 — Use the ordinary trusted roots unless this connection specifies its own CA bundle.

Variation notes: E042 does not state whether the supplied CA augments or
replaces system roots. E043, E045, and E047 express exclusivity more clearly.
“System trust store” may name different concrete stores in different runtime
environments. E048 establishes an override rule.

## 7. Verify the intended hostname and choose the TLS server name

Rough intent: authenticate the service identity, including cases where network
routing and certificate identity use different names.

- E049 — Make sure the server certificate is valid for `example.com`.
- E050 — Connect to `example.com` with hostname verification.
- E051 — Do not accept a certificate issued for a different host.
- E052 — Connect to `192.0.2.10`, but authenticate the server as `example.com`.
- E053 — Use `example.com` as the TLS server name while connecting through this pre-opened socket.
- E054 — Route the connection through `proxy.internal`, but verify the TLS peer as `api.example.com`.
- E055 — Send the server name `api.example.com` and require a certificate valid for that same name.
- E056 — Verify the IP address itself; do not treat it as the DNS name of a service.

Variation notes: E049–E051 concern certificate identity but do not explicitly
say whether Server Name Indication (SNI) must also be sent. E052–E054 separate
transport destination, SNI, and verification identity, although E054 does not
say whether the proxy terminates TLS. E055 intentionally requests both common
uses of a server name. E056 invokes IP-address rather than DNS-name matching.

## 8. Present a client certificate

Rough intent: authenticate the TLS client with selected credentials.

- E057 — Connect using this client certificate and private key.
- E058 — Present the `billing-agent` certificate when the server requests client authentication.
- E059 — Require mutual TLS and authenticate as `device-17`.
- E060 — Connect with a client certificate, but do not send it unless the server asks for one.
- E061 — Use the certificate and key from this PKCS #12 file for client authentication.
- E062 — Select the client identity issued by `Example Internal CA` if the server accepts it.
- E063 — Do not present a client certificate to servers outside `corp.example`.
- E064 — Load the client key through the hardware-backed key provider without exporting it.

Variation notes: E057 does not say whether the server requires the certificate
or merely permits it. E058 and E060 constrain disclosure timing. E059 also
requires server authentication even though it names the client identity. E061
leaves password acquisition unstated. E062 may require a choice among several
identities. E063 describes a policy whose host boundary must be defined. E064
constrains key handling, not the rest of the connection.

## 9. Load and select server credentials

Rough intent: supply certificates and private keys for one or more server
identities.

- E065 — Serve TLS using the certificate chain in `server.pem` and the key in `server.key`.
- E066 — Load this certificate and private key, and make sure they match before listening.
- E067 — Use the combined certificate-and-key file for incoming TLS connections.
- E068 — Serve `example.com` and `www.example.com` with their respective certificates.
- E069 — Choose the server certificate from the client's requested server name.
- E070 — Use the default certificate unless a more specific SNI certificate matches.
- E071 — Reload renewed server credentials for new connections without interrupting established ones.
- E072 — Require the server's private key to remain inside the configured key provider.

Variation notes: E066 requests an eager consistency check. E067 assumes a file
format capable of carrying both kinds of material. E068–E070 concern
multi-certificate selection and differ on fallback. E071 introduces a
long-running configuration-lifetime requirement. E072 constrains key custody
rather than certificate choice.

## 10. Authenticate TLS clients at a server

Rough intent: decide whether and how an accepting server authenticates the
connecting client.

- E073 — Require every TLS client to present a valid certificate.
- E074 — Accept clients only if their certificate chains to the corporate client CA.
- E075 — Request a client certificate, but allow clients that do not have one.
- E076 — Verify presented client certificates without making them mandatory.
- E077 — Do not accept a client certificate merely because it chains to a public web PKI root.
- E078 — Require mutual TLS for `/admin`, while allowing server-only TLS elsewhere.
- E079 — Authenticate clients with certificates and reject an expired client identity.
- E080 — Tell clients which private issuing authorities are acceptable for this service.

Variation notes: E075–E076 make authentication optional and need application
policy for unauthenticated clients. E078 spans TLS and higher-level routing;
whether separate connections or post-handshake authentication are intended is
unstated. E080 concerns the advertised acceptable-authority list, which is not
the same thing as the server's verification trust store.

## 11. Negotiate an application protocol with ALPN

Rough intent: negotiate the protocol carried inside TLS.

- E081 — Connect while offering `h2` and `http/1.1` through ALPN, in that order.
- E082 — Prefer HTTP/2, but allow HTTP/1.1 if the peer does not support it.
- E083 — Require the connection to negotiate `h2`.
- E084 — Accept a TLS client only if it selects one of `h2` or `http/1.1`.
- E085 — Advertise `acme-tls/1` and no other application protocol.
- E086 — Use the server's preferred protocol from the overlap with this list.
- E087 — After the handshake, report the negotiated ALPN protocol before sending data.
- E088 — Connect without ALPN because the application protocol is fixed out of band.

Variation notes: E081–E082 state client preference order. E084 and E086 need a
server-side selection policy. E083 says lack of `h2` is fatal; simply offering
only `h2` may not guarantee that. E085 might mean “offer only” or “fail unless
selected.” E087 requests inspection and ordering, not a selection policy.

## 12. Send and receive application data

Rough intent: exchange application bytes over an established TLS channel.

- E089 — Send this request over the authenticated TLS connection.
- E090 — Read the response after the request has been written completely.
- E091 — Write all of this message unless the connection fails.
- E092 — Read up to 16 KiB of decrypted application data.
- E093 — Keep reading until the complete length-prefixed message arrives.
- E094 — Allow reads and writes to alternate on the same TLS connection.
- E095 — Do not replay application data merely because a TLS write must be retried.
- E096 — Send early data only when it is safe to repeat; otherwise wait for the handshake.

Variation notes: TLS read and write actions need not align with application
message boundaries. E091 and E093 request application-level completion loops.
E095 is especially relevant to nonblocking retry rules. E096 introduces TLS
early data and requires the application to define replay safety.

## 13. Close gracefully and detect truncation

Rough intent: finish the TLS session without silently treating a truncated
stream as a clean end.

- E097 — Close the TLS connection gracefully after sending the response.
- E098 — Send a TLS close notification before closing the socket.
- E099 — Wait for the peer's close notification before declaring the session complete.
- E100 — Shut down TLS, then release the underlying transport.
- E101 — Close our sending side after the final message, but continue reading until the peer closes.
- E102 — Do not report an unexpected TCP EOF as a clean TLS shutdown.
- E103 — If graceful shutdown would block, finish it when the socket becomes ready.
- E104 — Abort immediately on a fatal protocol error; do not attempt a graceful TLS close.

Variation notes: “gracefully” in E097 is ambiguous between sending one
`close_notify` and completing the bidirectional shutdown exchange. E099 and
E101 explicitly request the latter behavior. E100 establishes resource order.
E102 asks for truncation detection. E104 distinguishes fatal failure from an
orderly close.

## 14. Handle connection and authentication failure

Rough intent: define safe behavior when transport setup, handshake, or peer
authentication fails.

- E105 — If the TLS handshake fails, report the failure and leave the connection unusable.
- E106 — Do not retry in plaintext after a TLS failure.
- E107 — If certificate verification fails, stop without sending application data.
- E108 — Try the next resolved address after a transport failure, but not after an authentication failure.
- E109 — Retry a transient connection failure once, using a fresh TLS connection.
- E110 — Prefer TLS 1.3, but if version negotiation fails, retry only with TLS 1.2.
- E111 — Preserve enough error information to distinguish name mismatch, untrusted issuer, timeout, and peer rejection.
- E112 — On failure, release any socket and TLS state created by this attempt.

Variation notes: E108 distinguishes failures that may justify trying another
address. E109 needs “transient” and retry timing to be defined by a lower
policy. E110 deliberately requests a downgrade retry and may have security and
interoperability consequences. E111 asks for error categories without
requiring exposure of a particular library's error queue.

## 15. Bound time and waiting

Rough intent: prevent TLS work from waiting indefinitely.

- E113 — Give up if the secure connection is not established within five seconds.
- E114 — Use a two-second TCP connect timeout and a five-second TLS handshake timeout.
- E115 — Require each read to make progress within thirty seconds.
- E116 — Close the connection if it remains idle for ten minutes.
- E117 — Finish graceful shutdown within one second; otherwise close the transport.
- E118 — Try each address without exceeding the overall ten-second connection deadline.
- E119 — Use the caller's existing deadline for connect, handshake, reads, and writes.
- E120 — Wait as long as necessary for application data, but not for peer authentication.

Variation notes: E113 may or may not include DNS and TCP setup. E114 separates
two phases. E115 is an inactivity/progress bound, not necessarily a total
operation duration. E118 states an overall deadline rather than a per-address
timeout. E119 delegates deadline value and cancellation behavior to the
caller. E120 intentionally treats handshake and data differently.

## 16. Use nonblocking or event-driven transport

Rough intent: integrate TLS actions into an application-controlled readiness
loop without changing their security policy.

- E121 — Perform the TLS handshake without blocking the event loop.
- E122 — Use this nonblocking socket and tell me whether to wait for reading or writing.
- E123 — Connect with TLS using the application's readiness callbacks.
- E124 — Resume the same handshake action after the requested I/O becomes ready.
- E125 — Read application data when possible; otherwise return control without busy-waiting.
- E126 — Queue this write and continue it after the TLS layer can make progress.
- E127 — Handle connect, handshake, data exchange, and shutdown through the existing poll loop.
- E128 — Use blocking TLS unless an event loop is supplied; if it is, preserve the same verification policy.

Variation notes: E121 alone does not select readiness, callbacks, futures, or
threads. E122 asks for readiness direction. E123 could mean callback-based
transport I/O or merely readiness notification. E124 captures the common
requirement to retry the same logical action. E126 says “queue,” which might
assign buffering and lifetime responsibilities to either caller or lower
layer. E128 makes concurrency style conditional while keeping authentication
policy stable.

## Cross-family near-equivalence samples

These smaller groups make paraphrase relationships easy to inspect.  They are
labels for human comparison, not parse results.

### Require TLS 1.3 exactly

- E026 — “restricted to TLS 1.3”
- E027 — “require TLS 1.3”
- E028 — “forbidding TLS 1.2 and all earlier protocols”

These appear close under today's protocol-version universe, but E028 would not
necessarily forbid a future version. E025 (“using TLS 1.3”) is intentionally
excluded because it may express preference rather than exclusivity.

### Authenticate before application data

- E017 — authenticate before sending any data
- E018 — do not send the request until certificate verification
- E023 — exchange data only after an authenticated handshake
- E107 — stop without sending data if verification fails

E017 and E023 cover both sending and receiving more naturally than E018 and
E107. None necessarily says whether replayable TLS early data is allowed; E096
addresses that separately.

### Use a private trust anchor exclusively

- E043 — trust only a private CA
- E045 — do not use the system store
- E047 — use bundled roots rather than machine-local configuration

E045 alone does not identify replacement roots, and E047 may name several
roots rather than one. E042 is not in this group because “with this CA” may
mean either replacement or augmentation.

### Verify the service name

- E049 — certificate valid for `example.com`
- E050 — connect with hostname verification
- E051 — reject a certificate for a different host
- E055 — send and verify the same named service

E055 adds SNI. The others request certificate-name checking without clearly
requesting or forbidding SNI.

### Require a client certificate

- E059 — mutual TLS as `device-17`
- E073 — every client must present a valid certificate
- E074 — only clients chaining to a named CA
- E079 — certificate authentication including validity time

E059 is spoken from the client side; E073–E079 are server policies. E074 adds a
trust restriction and E079 highlights time validity.

### Negotiate HTTP/2 when available

- E081 — offer `h2` before `http/1.1`
- E082 — prefer HTTP/2 but allow HTTP/1.1

They are close if list order determines preference, but E081 only literally
specifies an offer order. E083 is stronger because it makes any other result a
failure.

### Complete an event-driven action

- E103 — resume graceful shutdown when ready
- E124 — resume the same handshake action when ready
- E125 — return control when a read cannot progress
- E127 — put all TLS phases in the poll loop

These share an execution setting, not one underlying TLS goal. They are useful
examples of a constraint that cuts across otherwise different actions.

## Ambiguity catalogue

The following ambiguities occur in ordinary usage and should remain visible in
the corpus.

| Wording | Important unresolved readings | Examples |
| --- | --- | --- |
| “securely” | authenticated TLS with safe policy; encryption only; an application-specific security standard | E001, E003, E006 |
| “using TLS 1.3” | exactly 1.3; at least 1.3; prefer 1.3; expect 1.3 but permit fallback | E025 |
| “forbid TLS 1.2” | forbid only 1.2; forbid 1.2 and all older protocols | E028 avoids this shorthand |
| “with this CA” | replace normal roots; add a root; pin an exact certificate | E042 |
| “invalid certificate” | failed chain, name, time, usage, revocation, or local policy | E020–E022 |
| “connect to a host” | transport destination, SNI value, verification identity, or all three | E049–E056 |
| “require `h2`” | offer only `h2`; fail unless `h2` is selected | E083, E085 |
| “write this message” | make one TLS call; consume the whole buffer; deliver it to the peer application | E091 |
| “connection timeout” | DNS, TCP, TLS handshake, whole attempt, or inactivity | E113–E120 |
| “graceful shutdown” | send `close_notify`; also wait for peer `close_notify`; close application protocol first | E097–E101 |
| “nonblocking” | readiness API; callback transport; background thread; future/promise facade | E121–E128 |
| “defaults” | library-build defaults; OS policy; application policy; a stable named profile | E006–E008, E032 |

## Conservative follow-up questions

A follow-up is warranted when different answers materially change the user's
stated goal or trust boundary. It is not warranted merely because a low-level
API has a setting.

| Requests | Why the intent is incomplete | Plausible follow-up |
| --- | --- | --- |
| E001, E003 | No service or port is inferable from the request alone. | “Which service or port should be contacted?” |
| E011, E057, E065, E067 | “this” credential material must resolve to an actual source. | “Which certificate and private-key source should be used?” |
| E025 | Exact-only and preferred-with-fallback policies are observably different. | “Must TLS 1.3 be negotiated, or is it preferred with an allowed fallback?” |
| E042 | Replacing and augmenting system roots create different trust boundaries. | “Should this CA replace the normal trust roots or be added to them?” |
| E045 | Verification cannot proceed without some stated or inherited roots. | “Which trust roots should replace the system store?” |
| E052–E054 | Destination, SNI, and authenticated identity have been partly separated. | “Which name should be sent as SNI, and which name must the certificate match?” |
| E058, E060, E062 | More than one usable client identity may exist. | “Which client identity may be disclosed to this server?” |
| E061 | An encrypted PKCS #12 source needs a credential-unlocking policy. | “How should the key password be obtained?” |
| E068–E070 | Multi-name selection needs behavior when no name matches. | “Should an unmatched SNI use a default certificate or fail the handshake?” |
| E071 | Reload semantics can include partial failure. | “If renewed credentials are invalid, should new connections keep using the previous valid credentials?” |
| E075–E076 | An unauthenticated connection is allowed, but its application authority is not stated. | “What may a client do when it presents no valid certificate?” |
| E078 | A path is known only after some application traffic, usually after the initial handshake. | “May `/admin` use a separate connection or endpoint, or is post-handshake authentication required?” |
| E084, E086 | A server selection rule is not fully specified by an allowed set. | “When several offered protocols are allowed, should client order or server order win?” |
| E085 | Offering only one protocol does not necessarily say what to do if none is selected. | “Must the handshake fail unless `acme-tls/1` is negotiated?” |
| E096 | Only the application knows whether a particular operation is replay-safe. | “Which application messages, if any, may be sent as replayable early data?” |
| E097 | One-way and bidirectional TLS shutdown have different waiting behavior. | “Must we wait for the peer's close notification, or is sending ours sufficient?” |
| E108–E110 | Retry boundaries affect downgrade, identity, and duplicate work. | “Which failure classes permit a new attempt, and must all attempts use the same security policy?” |
| E113 | The named deadline has no phase boundary. | “Does five seconds cover DNS and TCP setup as well as the TLS handshake?” |
| E115 | A progress deadline and an overall read deadline behave differently. | “Should thirty seconds bound total duration or only periods with no progress?” |
| E121 | No event-loop interface is available in the request or surrounding context. | “Which existing event-loop interface should receive TLS readiness?” |
| E126 | “Queue” leaves ownership and cancellation observable to the caller. | “May the lower layer retain the buffer, or must it copy the data before returning?” |

## What should not automatically become a follow-up

The following distinctions keep omission from being mistaken for ignorance.

### Information genuinely needed to know what the person wants

- the remote service when it is not implied by surrounding context;
- the identity to authenticate when it differs from the transport destination;
- whether a version or ALPN item is required or merely preferred;
- whether supplied trust roots replace or augment an inherited trust policy;
- which client identity may be disclosed when several are available;
- what application data is safe to replay;
- observable failure, retry, deadline, and shutdown behavior when the request
  makes those matters significant.

### Choices a lower layer can often make

- how sockets, BIOs, TLS session objects, and certificate-store objects are
  allocated and connected;
- how a DNS result list is represented or iterated;
- how an ALPN preference list is encoded on the wire;
- which readiness primitive implements a caller's stated event-loop contract;
- how error queues are drained and translated into the requested error
  categories;
- when internal buffers are sized, flushed, or reused;
- which lower-level calls realise a named safe policy.

These choices can become user intent in a specialised request, but the mere
existence of a corresponding API action is not a reason to ask about it.

### Facts that can normally inherit a safe policy

- verify the peer certificate, intended name, and validity time for an ordinary
  public client connection;
- do not fall back from TLS to plaintext after failure;
- exclude obsolete protocol versions and known-insecure cipher choices;
- use suitable system roots when no different trust boundary is stated;
- avoid application data before authentication unless the request explicitly
  permits replayable early data;
- release partially created resources after failure;
- preserve the same authentication policy in blocking and event-driven forms.

These are observations about plausible defaulting, not decisions about
Adriç's eventual policy or formal semantics.
