/**
 * OpenCode V2 registers every tool into Code Mode by default; each built-in
 * native tool opts out with `codemode: false` so it stays on the model-facing
 * tool list. This plugin flips those opt-outs back into Code Mode, so the
 * model-facing list collapses to the `excluded` set below.

 * Disable without removing it with `settings.plugins = [ "-all-tools-codemode" ]`.
 */
const excluded = ["execute", "skill", "subagent"];

export default {
  id: "all-tools-codemode",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      for (const tool of editor.list()) {
        if (excluded.includes(tool.id)) continue;
        if (tool.options?.codemode !== false) continue;
        if (tool.options?.namespace !== undefined) continue;
        editor.update(tool.id, (definition) => {
          definition.options = { ...definition.options, codemode: true };
        });
      }
    });
  },
};
