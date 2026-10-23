/**
 * OpenCode V2 registers every tool into Code Mode by default; each built-in
 * native tool opts out with `codemode: false` so it stays on the model-facing
 * tool list. This plugin flips those opt-outs back into Code Mode, so the
 * model-facing list collapses to the `excluded` set below.

 * Disable without removing it with `settings.plugins = [ "-all-tools-codemode" ]`.
 */
const excluded = ["execute", "skill", "subagent", "question"];

// The built-in Code Mode text explains the mechanics but not the reason to use
// it, and agents wrap one tool call per `execute` (85-89% of gate calls in
// OpenCode's session database). Appended to the `execute` description so
// every agent gets it.
const batching = `

Each \`execute\` call costs a full model round trip; the tools inside it are cheap. Write one script per phase of work, not one per tool call. Run every independent read, search, shell command, and fetch together with \`Promise.allSettled\`, and chain dependent calls in the same script when the next call follows mechanically from the previous result. Trim and filter results in the script before returning them. A script that calls a single tool wastes a round trip unless the next call depends on reading its result. Run tools outside Code Mode, such as \`skill\`, as parallel tool calls in the same step as \`execute\`.`;

export default {
  id: "all-tools-codemode",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.update("execute", (definition) => {
        definition.description = definition.description + batching;
      });
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
