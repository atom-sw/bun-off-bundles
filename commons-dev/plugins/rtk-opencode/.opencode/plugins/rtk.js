// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// Vendored from rtk 0.43.0, which installs this file at
// ~/.config/opencode/plugins/rtk.ts. `rtk init --opencode` refuses a workspace-local
// install ("OpenCode plugin is global-only"), so the bundle ships its own copy to keep
// the integration project-local: see commons-dev/README.md.
//
// Two deliberate departures from upstream: plain JS instead of TypeScript, so OpenCode
// loads it with no `@opencode-ai/plugin` dependency to resolve, and a plugin name scoped
// to the bundle.
//
// Do not add rewrite rules here. This is a thin delegating plugin: all rewrite logic
// lives in `rtk rewrite`, whose Rust registry is the single source of truth. That is
// what makes the copy safe across rtk version bumps — re-sync it only if rtk changes
// the plugin contract itself.

export const RtkOpenCodePlugin = async ({ $ }) => {
  try {
    await $`which rtk`.quiet()
  } catch {
    console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
    return {}
  }

  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return
      const args = output?.args
      if (!args || typeof args !== "object") return

      const command = args.command
      if (typeof command !== "string" || !command) return

      try {
        const result = await $`rtk rewrite ${command}`.quiet().nothrow()
        const rewritten = String(result.stdout).trim()
        if (rewritten && rewritten !== command) {
          args.command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    },
  }
}
