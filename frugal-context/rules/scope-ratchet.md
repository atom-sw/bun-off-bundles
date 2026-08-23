# Widen scope one notch at a time

Start where the request points and stay there. Reading past what the task needs costs
tokens and, worse, buries the code that matters in code that does not.

- Begin with exactly the files, symbols, or directories the request names. Treat those as
  the whole task until they demonstrably cannot answer the question.
- Widen one notch at a time: the named file, then its direct imports and callers, then its
  module, then the repository. Never skip a notch.
- Before widening, say which question the current scope could not answer. Stop as soon as
  that question is answered, rather than sweeping the rest for completeness.
- When the request names nothing to start from, ask one scoping question instead of
  scanning the codebase for candidates.
