# Syllabus emotion classifier reuse

Canonical labeled corpus: `bl4ckb4ll/syllabus/poetry/emotions/`.

The corpus encodes emotion classification as a many-to-many relation: each work has one canonical file and emotion directories contain symbolic links asserting membership. Initial labels are Anger; Anxiety & Insecurity; Blame & Guilt; Boredom; Disappointment; Gratitude; Grief; Humor; Joy & Contentment; Melancholy & Despair; Optimism; Passion.

## Planned Idriç use

Idriç should eventually be able to consume this representation as a typed multi-label classification problem and emit predicted label memberships in a form that can be checked before any filesystem changes are made.

A future path may include:

- reading canonical items and symlink-derived reference memberships;
- representing the label vocabulary explicitly rather than as unvalidated arbitrary strings;
- running or hosting learned classifier inference;
- emitting a set of proposed emotion memberships for one canonical item;
- handing those predictions to AI-CI/RHS verification before materializing symlinks;
- preserving provenance between human/reference labels and generated suggestions.

Training/evaluation must operate on canonical works rather than treating multiple symlinks as independent examples. Poetry is the seed corpus only; the classifier should not be architecturally restricted to poems because the same emotion taxonomy is intended for other material later.

This is a future integration note, not an implementation commitment in the current compiler work.
