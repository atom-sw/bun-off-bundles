# Use rtk for shell commands

rtk (Rust Token Killer) is a CLI proxy that compresses verbose command output
before it reaches the model, saving 60–90% of tokens on routine dev operations.
This platform has no rtk interception hook, so apply rtk yourself.

## Rule

Prefix shell commands with `rtk` whenever a compressed proxy exists for them:
`git`, `gh`, `grep`, `rg`, `find`, `ls`, `tree`, `diff`, `npm`, `pnpm`, `cargo`,
`docker`, `kubectl`, `curl`, and the test/lint/format runners. rtk keeps the full
output on failure, so nothing important is hidden.

```bash
rtk git status
rtk grep -n "pattern" src/
rtk test        # run tests, show only failures
```

## Meta commands

Run these directly, without a wrapped command:

```bash
rtk gain              # token savings analytics
rtk gain --history    # usage history with savings
rtk proxy <cmd>       # run a command raw, no filtering (for debugging)
rtk --version         # confirm rtk is installed
```

## Name collision

If `rtk gain` fails with an unknown-subcommand error, a different `rtk` (Rust Type
Kit) is on PATH. Verify the binary with `which rtk` before relying on it.
