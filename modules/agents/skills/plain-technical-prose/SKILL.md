---
name: plain-technical-prose
description: Write and revise prose in a plain technical register. Use for documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, and code comments.
---

# Plain technical prose

Prose written to this style reads as a specification rather than as persuasion. It states what is true, why, and at what cost, without typographic emphasis or rhetorical construction. Apply it to documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, and code comments.

The reference for this style is ASD-STE100. Apply its discipline: short sentences, active voice, one topic per sentence, present tense, and controlled terminology. Do not claim conformance, and do not apply its approved-word list, which mangles domain terms such as `dmabuf`, `composite`, and `swapchain`.

Register rules apply to all prose. Sentence mechanics apply only to declarative sentences during a clarity rewrite, and only when a sentence fails the `WHO is doing WHAT?` diagnostic. A sentence that already has a short concrete subject and an active verb is left alone, even when it uses `was` or `is` for cohesion.

## Rules

Sentences. One idea per sentence. State the fact and its consequence in order. For descriptive and capability prose, use short declarative sentences in active voice and present tense for behaviour (past only for history). For procedural instructions such as setup steps and local commands, use imperative mood ("Start PostgreSQL:", "Run `docker-compose up -d`"). Use active voice unless the actor is genuinely unknown or irrelevant.

Person. Name the true actor and choose mood by discourse type. For descriptive prose about system behaviour, use third person and name the component that performs the action (the user, the compositor, the host desktop, the caller, the backend). For capability and feature prose, the actor is the user or caller, not the feature: "Users roll and claim characters", not "Character collection rolls"; "Users give characters to other users", not "Trading system gives". For procedural instructions, use imperative with no actor ("Start PostgreSQL:", "Build the backend:") or an actorless label ("PostgreSQL:", "Backend:"); do not invent an actor such as "the operator" or "the developer" to satisfy third person when the reader performs the action.

Personification. Software has no intent; name the component and the operation it performs: "the fold records the home page", not "the home the capture chose".

Terminology. Choose one term per concept and keep it. Synonym variation for stylistic relief obscures whether two names mean the same thing. If a document uses both "Rust" and "the native layer", decide which one each context needs and apply it consistently.

Definitions. Define a term where the reader first meets it, and define it once. Reference material is read out of order and in part, so a term introduced in one section and used in another is defined at first use in each, or the second use links to the first.

Figures of speech. No metaphor, idiom, rhetorical question, or aside. No sentence fragments used for effect. No punchlines, no understatement, no self-deprecation. No aphorism: a sentence shaped as a maxim, such as "text is evidence of an identity, not an identity", states a mechanism indirectly, so state the mechanism. No loaded noun standing in for one, such as a trap, a spine, a promise, or a warning, where the thing itself can be named.

Markdown. Keep headings, tables, code blocks, inline code, links, and lists that enumerate a real set. The result is never line-wrapped. Each paragraph occupies a single source line, and a newline ends a paragraph, a list item, or a block. Hard-wrapped prose renders as fragmented paragraphs in Markdown viewers, so wrapping corrupts the output as well as the source.

One exception applies to agent instruction files, meaning `SKILL.md` and similar. Those keep bolded lead-in labels on numbered workflow steps, where the label names the step and acts as structure. The register rules still apply to the prose that follows each label.

Headings. Name the subject, not the reading experience. "Two details that bite if ignored" becomes "Two details matter if ignored", or the sentence is dropped and the list stands alone.

Generated-sounding phrasing. Avoid formulaic contrasts ("not X, but Y") and implicature (gesturing at a conclusion without stating what depends on it). State the claim, action, or consequence directly. Prefer concrete verbs over abstract management or assistant phrasing such as "synthesize", "surface", "navigate", "land", and "align" when a simpler verb is available. Terms such as "synthesize", "seam", "shape", and "load-bearing", along with parentheticals, become a problem when they are repeated mechanically, used as vague abstractions, or substituted for a concrete mechanism; judge them by context and density. A component can be "load-bearing" when a specific dependency relies on it; an integration boundary can be a "seam".

Avoid describing a set by its size where its members can be named. "None of the three is implemented" leaves the reader counting; "the supersede, retract, and redate events are not implemented" does not.

<!-- vale off -->

Judgements. Keep every judgement, and state it as a claim with a reason. Drop the attitude, not the position. "which is a debugging surface we don't need" becomes "would add a debugging surface with no offsetting benefit". "exactly backwards" becomes "counterproductive".
<!-- vale on -->

Characters. Keep Unicode only in proper nouns and in code.

## Sentence mechanics

Every declarative sentence puts its story character in the subject and the character's action in the verb. Imperative procedural steps ("Start PostgreSQL:", "Run `docker-compose up -d`") are exempt.

- The subject is the main character: a short, concrete noun or noun phrase, not a long abstract phrase.
- The verb is the character's action. Convert nominalizations (`evaluate` -> `evaluation`, `decide` -> `decision`, `argue` -> `argument`) to verbs when they bury the clause's key action and force vague `to be` / `to have` verbs.
- Lead with subject and verb within the first few words. No long phrase before the subject or between subject and verb. An introductory phrase that contains its own character and action becomes its own sentence.
- `to be` is allowed only to link old information to new for cohesion, never to carry a hidden action. When `is + nominalization` can become a verb, use the verb.

BAD:

    The evaluation of the swapchain configuration occurs before import.

GOOD:

    The compositor evaluates the swapchain configuration before import.

- Old before new: start each sentence with information the previous sentence established, even when the cohesive version uses `was` and a few more words. Flow beats local brevity.

## Writing and rewriting

- Write to these rules from the first draft. Do not draft in a livelier register to flatten later; the flattening pass loses content.
- Register is the delivery, not the content. Reasoning, caveats, numbers, trade-offs, and cross-references belong in plain-register prose exactly as in any other. A dry document is not a shorter document.
- Describe the present state. Where a past decision explains a present constraint, state the constraint and its reason rather than narrating how it came about.
- Read the whole document before rewriting. The rewrite depends on which terms the document commits to and which cross-references must survive.
- Rewrite section by section: identify what each paragraph asserts, then restate the assertions. Do not paraphrase sentence by sentence; that preserves the original's rhetorical shape.
- Preserve content exactly. Every decision, rationale, caveat, number, file reference, link, and anchor target stays; update every link to a heading that is renamed.
- Check the line count after the rewrite. A content-preserving rewrite lands close to its original length; a large drop means content was lost, not compressed.
- For a multi-document rewrite, do all documents in one pass so terminology stays consistent.

## Scope

This skill governs register, not structure. Follow the structure the target dictates: an issue template, the repository's commit conventions, or a README's existing shape, and write the prose to these rules.

Two carve-outs for code comments: comments stay short, and a comment that is already a single plain sentence needs no change. Do not rewrite comments in a file that the task did not otherwise touch.

## Verification

Before presenting a rewrite:

- Run `vale` on every written or modified document or source file and fix its alerts across technical documents (`.md`, `.txt`, `.rst`, `.adoc`, `.org`, `.typ`), commit descriptions (`.jjdescription`), and code comments (`.go`, `.rs`, `.ts`, `.js`, `.py`, `.rb`, `.gleam`, `.nix`, `.nu`, `.sh`, `.sql`, `.thrift`, etc.; pronoun checks are disabled on code comments and commit descriptions).
- Check what `vale` cannot judge: no line breaks inside a paragraph; headings name the subject; no component or feature acting as a personified subject; no invented actor ("the operator") where the reader performs the action; no set described by its size where members can be named; every term defined at first use; concrete subject and active verb leading each declarative sentence with old information before new.
