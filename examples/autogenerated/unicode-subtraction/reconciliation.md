# ChordReader frontend reconciliation

The ChordReader managed DEX probe at b62c3b604f966bab8838c685a7b45505cc895eae used frontend 740bbf2b1d9e811fd00c719c3473eede17ceea3b. It refused the unchanged Music.idric Unicode subtraction at lines 106, 122 and 221 before DEX emission. The accompanying undefined-main diagnostic is not yet an independent backend result.

This branch retains the Unicode lexer and compatibility fixtures and incorporates the exact compiler-driver error-exit repair and its checked accepting/rejecting fixtures from 740bbf2. No musical source is rewritten. The combined tree must be bootstrapped and the original ChordReader consumer rerun before claiming managed parser support.

Qualification of this reconciliation: PENDING. Historical syntax execution in attempt.md remains scoped to its original tree. ART, application integration and TAB_P10 physical acceptance remain separate obligations.
