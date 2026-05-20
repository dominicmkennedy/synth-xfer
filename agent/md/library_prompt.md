Extract reusable helper functions from the {DOMAIN_NAME} transfer functions in the corpus.

- Call `get_corpus_functions()`, then check the existing library to avoid duplicates.
- You must return at least 3 new functions. If your first pass yields fewer, look harder for recurring sub-computations or semantically coherent patterns across the corpus.
- Return only new functions as a JSON `functions` array — no surrounding explanation.
