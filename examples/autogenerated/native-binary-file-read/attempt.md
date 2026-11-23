# Checked binary file-read witness

Take one pathname from the process argument list. Acquire a read-only file, borrow it for one bounded binary read, and release it before returning. A buffer capacity and the actual count returned by the read are distinct. Count zero denotes EOF, positive counts authorize only that prefix of the buffer, and a failed read authorizes no output bytes. Standard output is borrowed and remains open. The inherited close operation returns unit and cannot establish a successful close. The fixture exercises one chunk so that native runtime branch handling can be tested independently of loop lowering.

## Compiler and backend boundary

Compile this file with the compiler repository's `_/edric --emit-one-step` entry point. The focused regression in `_/scripts/test-one-step-emitter.sh` checks that generated definitions have unique names and that the pathname and byte-count branches call the selected Text and Int comparisons. It also requires the two file-buffer operations in the function that copies a prefix. The original Cat Food compiler package at `94dfd99bd3e376507fedc8611053b7173b2519f0` emitted two definitions each for compare, less-than and inequality, and three distinct implementations under the single equality spelling. Both Linux and NetBSD consumers at `e4018340efed6a2cdb296ea62caaca231fd97004` rejected that handoff at its first duplicate.

## Next implementation

Start from the checked fixture and its call graph. Preserve runtime control flow and distinguish a bounded byte buffer, an owned input file and a borrowed output handle in a versioned native-file action representation. Keep library-level decisions about EOF and how much to write. Translate only recognized action identities and argument/result types. The existing foreign close returns unit, so introduce an error-reporting close contract before claiming that a close succeeded. Lower the same operations to the native Linux and NetBSD backends, then extend this one-chunk witness to a loop with checked partial-write progress and EINTR handling.

For the one-chunk native test, compare exact output for an empty file, a short file containing NUL/0xff/CRLF, and a longer file with distinct bytes on both sides of byte 32. A nonexistent path must fail before output; a read error and a failed write must both fail. Separate descriptor lifetime, 64-bit seek and actual NetBSD execution need their own coverage. Keep the SDF mailbox outside this test.
