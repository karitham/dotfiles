---
description: Explicitly delegate a task to a subagent
---

**Protocol:** The human has explicitly chosen to delegate. This overrides the default "do it yourself" behavior.

1. Determine the right subagent based on the task:
   - **explore** — code research, finding files, understanding unknown code
   - **code-designer** — design work when the approach isn't settled
   - **code-implementer** — implementation when the approach IS settled
   - **debugging** — investigating failures, crashes, or test issues
   - **ask** — open-ended codebase analysis and questions

2. Distill shared understanding into a focused prompt. MUST include:
   - **Goal** (one sentence)
   - **File paths** (what to read/modify)
   - **Constraints** (MUST/SHOULD rules)
   - **Verification** (how to check success)

3. Validate the output before presenting it to the human.

User wants to delegate:
$ARGUMENTS