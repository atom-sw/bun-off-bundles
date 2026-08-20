# American English

Write every word of output in US English: prose, code comments, commit messages,
documentation, identifiers, and log and error strings.

- Spelling: "color" not "colour", "behavior" not "behaviour", "analyze" not "analyse",
  "license" for both the noun and the verb, "defense" not "defence".
- Verb endings: prefer "-ize" and "-ization" over "-ise" and "-isation" ("normalize",
  "serialization"). A handful of verbs keep their "s" in US English as well, because the
  ending is not the "-ize" suffix at all: "advertise", "exercise", "supervise", "surprise",
  "compromise".
- Doubled consonants: "canceled", "labeled", "modeling", "traveled" take one "l".
- Vocabulary, not just spelling: "apartment", "elevator", "parentheses" over "brackets"
  for `()`, and "period" for the sentence-ending dot.
- Dates in prose: "January 5, 2026", or ISO 8601 (`2026-01-05`) in anything a machine reads.

Two things this rule does not override:

- **Quoted and external text stays as written.** Never "correct" the spelling inside a
  quotation, a copied error message, a third-party document, or someone's name.
- **Identifiers that already exist keep their spelling.** If an API, a dependency, or the
  surrounding code uses `colour` or `initialise`, match it rather than introducing a second
  spelling of the same name. Matching the surrounding code wins over this rule.

If the user asks for another variant in a given conversation, follow the request.
