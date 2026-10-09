# Tool names

Name a tool by what the reader is looking at: the product, the command, or the package.

- In prose, use the product name, capitalized as its project writes it: "Git", "Cargo",
  "Python", "Bun Off". Write it as an ordinary proper noun, without code formatting.
- For anything the reader types or runs, use the executable name in code formatting: `git`,
  `cargo`, `python`, `boff`. This covers commands and code blocks, and also a mention of the
  command in a sentence: "Run `boff deploy` from the project root."
- For the name a package registry or an installer knows, use that name in code formatting,
  even when it differs from the command: `pip install bun-off` installs the `boff` command.
  The same goes for a repository, a URL, or a configuration key that spells the name.
- Do not capitalize a command because it starts a sentence. Rephrase instead: write
  "The `boff check` command reports drift," not "`Boff` check reports drift."

Follow the project's own spelling of its name. If its documentation already uses one form
consistently, match it rather than introducing a second one.
