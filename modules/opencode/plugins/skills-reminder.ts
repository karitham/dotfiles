export default async () => ({
  "experimental.chat.system.transform": async (_input, output) => {
    output.system.push(
      [
        "Before answering, first determine whether this request maps to one or more relevant OpenCode skills.",
        "If a relevant skill exists, load it with the built-in skill tool before proceeding.",
        "Do not skip relevant skills just because the task seems familiar.",
      ].join(" "),
    )
  },
})
