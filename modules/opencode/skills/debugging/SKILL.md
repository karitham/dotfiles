---
name: debugging
description: Load when debugging failures, errors, crashes, or unexpected behavior. Emphasizes empirical investigation over code reasoning.
---

# Debugging Protocol

You are debugging a system. You MUST NOT diagnose from code reading alone. You MUST observe the system's actual behavior and design experiments to narrow the failure.

## Core Loop

The debugging process is a tight iteration of four steps. You MUST complete each step before proceeding to the next.

1. **Observe.** Gather the actual failure: error messages, stack traces, logs, exit codes, output. If you have none, that is your first problem to solve.
2. **Hypothesize.** Propose the *narrowest* possible explanation consistent with all observations. If your hypothesis requires two things to be wrong, find a way to isolate them.
3. **Experiment.** Design a test that distinguishes your hypothesis from alternatives. Execute it. You MUST NOT skip this step.
4. **Narrow.** Based on the result, eliminate what is impossible. Refine the hypothesis. Repeat.

The temptation to skip straight from observation to conclusion is the primary failure mode. You MUST resist it.

## Guiding Principles

- **Run first, reason second.** Code behavior emerges from execution, not reading. You SHOULD run the code or tests before you try to explain what they do.
- **Distrust your assumptions.** The bug is always where you least expect it, because you would have checked the expected places already. When you feel certain, design an experiment that would prove you wrong.
- **Change one thing at a time.** If you change two things and the problem goes away, you have learned nothing.
- **The minimal reproduction is the diagnosis.** If you can build a minimal case that reproduces the failure, the bug is usually obvious. You SHOULD invest effort here early, not late.
- **Read the output, not the code.** Error messages, warnings, logs, and output contain information that the code often does not make obvious. Read every line of output carefully.

## Phase 1: Establish the Failure

Before doing anything else, you MUST answer these questions. If you cannot answer them, ask the user or run commands until you can.

- **What is the observed behavior?** The exact error message, crash, wrong output, or unexpected state.
- **What is the expected behavior?** What should happen instead.
- **How can it be reproduced?** A specific command, test, or sequence of actions. If reproduction is unclear, your first task is to find one.

You MUST NOT proceed to hypothesis generation until you have at least a clear description of observed vs. expected behavior.

## Phase 2: Gather Evidence

Collect information empirically. You SHOULD do as many of these as your environment allows.

- Run the failing test, command, or program. Capture full output including stderr.
- Check version information: language runtime, dependencies, OS, tool versions.
- Look at recent changes: `git log`, `git diff`, recent file modifications.
- Check environment variables, configuration files, feature flags.
- Inspect actual data: file contents, database state, network responses, API outputs.

When you can run commands yourself, you SHOULD do so without asking. You have bash access — use it.

## Phase 3: Hypothesize and Experiment

### Forming Hypotheses

Each hypothesis MUST be:
- **Specific.** Not "something is wrong with the parser" but "the parser fails when the input contains a trailing newline."
- **Testable.** You MUST be able to design an experiment that would confirm or refute it.
- **Minimal.** Prefer the hypothesis that assumes the fewest concurrent failures.

### Designing Experiments

An experiment is a precise action with a predicted outcome. You MUST state both before running it:

- **Action:** What you will do.
- **Prediction:** What will happen if the hypothesis is true. What will happen if it is false.
- **Result:** What actually happened.

Useful experiment types:

| Technique | When to use |
|---|---|
| Add logging / print statements | To inspect runtime state that is not visible |
| Binary search (divide and conquer) | Large inputs, long histories, or complex configurations |
| Minimal reproduction | When the failure context is large and you need to isolate |
| Compare working vs. broken | When you have a known-good state to diff against |
| Simplify to remove variables | When many things could be going wrong |
| Instrument assertions | To catch incorrect state as early as possible |

### Running Experiments Yourself

When you have access to the environment, you SHOULD run experiments directly. Prefer this over asking the user. Examples:

- Run a specific test: `go test -v -run TestName ./pkg/foo/`
- Add a print statement, run, then remove it.
- Inspect runtime state: print a variable, check a file, query a database.
- Modify a test to isolate a specific case.

### When You Cannot Run Things

Some experiments require production access, credentials, specific hardware, running services, or interactive debugging. When this happens:

1. You MUST design a *precise* experiment for the user to run.
2. You MUST provide the exact command to execute.
3. You MUST state what information to capture from the output.
4. You SHOULD NOT say "try running the tests." You SHOULD say: run `go test -v -run TestFoo ./pkg/bar/ 2>&1` and paste the full output.

Be specific about what you need. The user is your hands when you cannot use your own.

## Phase 4: Fix and Verify

Once you have identified the root cause:

- Make the smallest change that fixes the problem.
- You MUST verify the fix by running the failing test or reproduction case.
- You SHOULD check that you have not introduced regressions. Run the broader test suite if available.
- If the fix is complex, consider whether a simpler fix addresses the root cause rather than the symptom.

## Common Anti-patterns

You MUST NOT do these things:

- **Conclude from reading.** "I read the code and I think the problem is..." without any experimental evidence.
- **Shotgun debugging.** Making multiple changes hoping one will work.
- **Ignore evidence.** Dismissing an error message or log line because it does not match your hypothesis.
- **Fix symptoms.** Suppressing an error rather than understanding why it occurs.
- **Assume the framework is wrong.** The bug is almost always in your code, not the compiler, runtime, or library.
- **Skip the loop.** Going straight from "this looks wrong in the code" to editing it without confirming.

## Building Observability

When the system lacks sufficient logging or test coverage, you SHOULD help build it:

- Add targeted logging around suspected failure points.
- Write a focused test that isolates the suspected behavior.
- Create a minimal script or harness that reproduces the issue outside the full application.
- Add assertions that verify intermediate state.

This infrastructure is part of the debugging process. It is not wasted effort — it is how you see what the system is actually doing.

## Escalation

If after multiple iterations you have not narrowed the problem:

1. Re-examine your assumptions. Are you debugging the right thing?
2. Look wider. The failure may be in a different component than where it manifests.
3. Search for similar issues: error messages, stack traces, or symptoms in issue trackers, documentation, or forums.
4. Ask the user for context you may be missing: deployment details, timing, frequency, or related changes.
