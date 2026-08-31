# Constrained values in Idriç and Odriç

`isomorphisms/Idric-Net` is the first concrete systems-library dogfood target for compiler-visible constraints on values.

The requirement is stronger than giving a primitive value a new record name. The compiler must know the admissible domain, use it during type checking, derive consequences where possible, erase checking-only evidence when safe, and preserve the semantic range/cardinality into ANF, IR, and backends.

## Proposed source surface

The exact parser spelling can be adjusted during implementation, but the intended meaning is approximately:

```idris
DestinationPort : ℕ where
  1 ≤ number
  number ≤ 65535

HTTPStatusCode : ℕ where
  100 ≤ number
  number ≤ 599
```

`number` names the underlying scalar value. Use full semantic names in diagnostics and examples rather than single-letter placeholders.

A literal is checked while compiling:

```idris
https_port : DestinationPort
https_port = 443
```

is accepted, while `0` and `70000` are rejected as values of `DestinationPort`.

A runtime value does not become constrained by assertion. Parsing/checking must produce the constrained result explicitly:

```idris
parse_destination_port : String → Result PortError DestinationPort
```

After success, downstream code receives `DestinationPort`; it does not repeatedly re-check the same bounds.

## Semantic constants are library facts

The compiler understands constrained values and equality to constants, but protocol meanings live in libraries.

`Idric-Net` can declare:

```idris
not_found : HTTPStatusCode
not_found = 404
```

The compiler then knows that `not_found` inhabits `HTTPStatusCode` and has exact scalar value 404. It does not contain an HTTP-specific built-in saying that 404 means `not_found`.

This distinction matters for extensible protocols. An unregistered HTTP status such as 471 remains representable because it satisfies 100..599, while `Idric-Net` can still derive its 4xx `client_error` class.

## Finite choices are constrained by construction

A nullary choice already declares its exact semantic domain:

```idris
choice transport_result one_of
  transport_ok
  invalid_request
  invalid_endpoint
  tcp_connect_failed
  tls_connect_failed
  request_write_failed
  response_read_failed
  redirect_failed
```

The compiler knows:

```text
cardinality = 8
semantic tag domain = 0..7
minimum semantic tag width = 3 bits
```

No programmer-written numeric theorem is required. The external process encoding `0, 2, 3, ..., 8` is a separate ABI mapping introduced only at the process boundary.

## Derived relationships

Constraints can depend on other named values. Important systems examples include:

```text
body has byte length length
Content-Length = length

array has length
index < length

TLS connection is verified for host
request destination host = verified host
```

This is where the dependent type system should carry relationships that ordinary bounded integers cannot express.

If a relationship is used only to type-check code, its evidence should be erasable. Runtime representation should contain only information that execution actually requires.

## Range propagation

The compiler should propagate mechanically derivable ranges through ordinary operations.

If:

```text
left  : 0..7
right : 0..7
```

then ordinary widening addition has range `0..14`.

If the desired result must remain `0..7`, source code has to choose the arithmetic semantics explicitly: checked failure, modular arithmetic, saturation, or another declared operation. Machine overflow must not silently decide the language meaning.

Useful first propagation rules include:

- addition and subtraction with known bounds;
- multiplication where bounds are decidable cheaply;
- comparisons that become statically true or false;
- branch refinement after a successful comparison;
- finite-choice case refinement;
- equality to named constants;
- length/index relations.

## IR contract

The source constraint must not disappear into an unconstrained `Int` or `Word32` representation before backend selection.

IR should be able to record facts equivalent to:

```text
integer_range lower upper
finite_cardinality alternatives
exact_integer number
related_length value length
```

The precise internal representation is an implementation choice. The observable requirement is that backends can still query the semantic domain after lowering.

For the ARMv7/Thumb backend, a three-bit finite tag may occupy a full 32-bit core register while live because ARM registers are not independently allocatable bit slices. That does not justify changing the semantic type to an unconstrained 32-bit word. Spills may use byte storage, impossible tags remain impossible at the typed boundary, and dense finite choices may drive `TBB` — Table Branch Byte — lowering when appropriate.

## Odriç subset

Odriç should initially support a deliberately small, decidable constraint language rather than every proposition expressible in full Idris:

- lower and upper scalar bounds;
- finite choices/cardinality;
- equality to exact constants;
- equality and inequality between named values;
- lengths and `index < length`;
- simple arithmetic range propagation.

This is enough for destination ports, HTTP status codes, byte-sized values, bounded counters, array indexing, protocol discriminants, and many ABI boundaries.

The subset is a user-facing convenience and compiler contract. It can elaborate to the existing dependent-type machinery where appropriate rather than creating a second unrelated logic.

## Idric-Net acceptance matrix

The first language implementation should be exercised against real network types rather than only synthetic examples:

1. `443 : DestinationPort` compiles.
2. `0 : DestinationPort` and `70000 : DestinationPort` fail during compilation.
3. `404 : HTTPStatusCode` compiles and `99`/`600` do not.
4. `not_found` retains exact scalar value 404 through elaboration and lowering.
5. an unregistered value 471 remains a valid HTTP status and can be classified as 4xx by library code.
6. the eight-case `transport_result` retains cardinality 8 and a three-bit semantic tag domain through IR.
7. arithmetic on bounded values widens or refuses according to the declared operation rather than silently overflowing.
8. body/content-length relations can be represented without maintaining unrelated mutable numbers.
9. ICU consumes the same Idric-Net definitions in its integration path.
10. follower backends preserve the same semantic domain even when their physical register width is larger.

## Non-goal

The compiler is not expected to infer domain meaning from a primitive signature such as `String → Int → String`. Semantic domains must be declared. Once declared, however, the compiler is responsible for enforcing and carrying them rather than discarding them immediately.
