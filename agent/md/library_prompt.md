Extract reusable helper functions from the KnownBits transfer functions in the corpus.

- Call `get_corpus_functions()`, then check the existing library to avoid duplicates.
- Return only new functions as a JSON `functions` array — no surrounding explanation.
