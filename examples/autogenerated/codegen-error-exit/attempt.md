# Code-generator errors must fail the process

ICU's actual checked `Main.main : IO ()` is rejected by the current direct DEX
source ABI. The compiler printed that error but returned process status zero.
That lets build stages mistake an absent DEX for successful generation.

The compiler entrypoint receives command arguments and returns an IO action.
A selected generator may either emit an artifact or raise a checked compiler
error. The invariant is that a raised error exits unsuccessfully, independently
of whether elaboration recorded a source line. Version/help and successful
generation remain successful exits.

The bootstrap implementation stays in `Idris/Driver.idr`; no runtime fallback
or new backend is introduced. A deliberate rejecting code generator and an
accepting control exercise this branch through the real compiler driver.
This repairs build failure reporting; it does not implement ICU's IO lowering.
