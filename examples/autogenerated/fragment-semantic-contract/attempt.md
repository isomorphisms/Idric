# Exact 32-dimensional pairing

Control: https://github.com/isomorphisms/flexible-pipes/issues/116.

Values are the existing exact integer-coordinate samples of named real spaces.
The input types are ExactCovectorSample real32_space and ExactVectorSample
real32_space. The output is ±Number. contract evaluates the linear functional;
dot additionally requires EuclideanStructure. Dimension and named-space
identity remain distinct. The raw linked coordinate representation is explicitly
unsafe; it is neither a mathematical scalar field nor contiguous Array storage.

The attempt checks the final coordinate in dimension 32, scaling and addition,
and source refusal for vector-as-covector and another rank-equal named space.
It imports the canonical library instead of implementing another vector API.
Its Refl declarations establish only their stated exact equalities.

The shader repository separately lowers approximate coordinate packets and
must demonstrate its own numerical/backend acceptance. This program is not
shader or physical-device evidence.

Status: the actual Idriç source check passed all four stated equality
declarations and both expected role/space refusal declarations. Initially an
absolute source outside the compiler source directory was rejected; the Grease
check now stages exact canonical source copies with their hashes. The
wrong-space diagnostic was aligned with the observed namespace identities.
No fallback was selected. A complete executable real scalar field is outside
the existing sample contract and is not claimed by this attempt.
