# Koan by Example

Future learning material for IR, Idriç/Edric, and the koans should favor tiny runnable examples over long prose.

The model is the same basic idea behind Rust by Example, Go by Example, `tldr`, `bro`/bropages, and the koan style: show one useful thing, make it concrete, and let the reader run or change it immediately.

## What the existing examples teach

### Rust by Example

Rust by Example starts with a runnable hello-world program and then moves through primitives, custom data types, bindings and mutability, type conversion, expressions and control flow, functions, modules/crates/package tooling, generics, ownership/borrowing/lifetimes, traits, macros, error handling, standard-library types, files/threads, testing, unsafe operations, compatibility, documentation, and benchmarking.

Useful structural idea: one concept at a time, executable code, expected behavior, and small activities rather than a long chapter before the reader can do anything.

Reference: https://doc.rust-lang.org/rust-by-example/

### Go by Example

Go by Example follows the same short-example pattern but is especially good at showing ordinary tasks. It covers values and variables, control flow, arrays/slices/maps, functions and methods, structs/interfaces/generics, errors, goroutines and channels, timers and synchronization, strings/regex/templates, JSON/XML/time/random/hash/base64, files and directories, tests and benchmarks, command-line arguments and flags, environment variables and logging, HTTP/TCP, subprocesses, signals, and exit behavior.

Useful structural idea: examples progress from language syntax into things a programmer actually wants to do with the language.

Reference: https://gobyexample.com/

### Python

There are Python resources in the same spirit, including Python By Example and learnpython.org. They reinforce that the format is not language-specific.

References:

- https://www.pythonbyexample.dev/
- https://www.learnpython.org/

### Koans

RKoans approaches the same learning problem from the opposite direction: instead of only reading a working example, the learner edits a small failing test or blank until it passes. That makes a useful companion format to a by-example site.

## Proposed first twelve pages

Do not try to document the whole language at first. Start with about a dozen things a programmer can actually do:

1. Print `Hello, world` and run the program.
2. Create values: integers, floats, booleans, characters, and strings.
3. Bind names, change a value where mutation exists, and compare two values.
4. Choose with `if`/case-style control flow and repeat with a loop or iteration construct.
5. Define and call a function with arguments and a return value.
6. Define a small record/product type and a tagged/sum type, then inspect or pattern-match it.
7. Build a small collection and transform, filter, fold, or iterate over it.
8. Convert between useful types and show what happens when conversion can fail.
9. Represent and handle an error deliberately rather than crashing accidentally.
10. Read command-line arguments and read/write a small text file.
11. Parse or emit a small structured value such as JSON, or make one simple HTTP request when the runtime surface exists.
12. Show one concurrency/process/signal example when that capability exists; otherwise use the twelfth page for the most characteristic feature of the language.

The exact examples should follow what the implementation can really run. The site should never pretend a feature exists merely because Rust or Go has an example for it.

## Page shape

Each page should be short enough to scan in roughly a screen or two:

- one sentence saying what the program does;
- the smallest complete runnable program;
- the command to run it;
- expected output;
- two or three annotations explaining the non-obvious lines;
- one tiny modification for the reader to try;
- optionally a koan version with a blank or failing assertion.

The runnable example is the primary documentation. Prose is there only to make the example legible.

## Relationship between the three repositories

- **Idriç / Edric by Example**: source-language examples a person can type and run.
- **IR by Example**: examples that make the IR's semantics and execution model visible, preferably by showing a tiny source program beside the relevant IR when useful.
- **Koans**: short exercises derived from the same examples, with a blank, wrong value, or failing assertion for the learner to repair.

A later site can share the same example inventory while presenting each example in the form appropriate to the repository.