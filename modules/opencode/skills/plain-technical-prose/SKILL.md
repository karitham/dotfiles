---
name: plain-technical-prose
description: Write and revise prose in a plain technical register. Use for documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, and code comments.
---

# Plain technical prose

Prose written to this style reads as a specification rather than as persuasion. It states what is true, why, and at what cost, without typographic emphasis or rhetorical construction. Apply it to documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, and code comments.

The reference for this style is ASD-STE100. Apply its discipline: short sentences, active voice, one topic per sentence, present tense, and controlled terminology. Do not claim conformance, and do not apply its approved-word list, which mangles domain terms such as `dmabuf`, `composite`, and `swapchain`.

Register rules apply to all prose. Sentence mechanics apply only to declarative sentences during a clarity rewrite, and only when a sentence fails the `WHO is doing WHAT?` diagnostic. A sentence that already has a short concrete subject and an active verb is left alone, even when it uses `was` or `is` for cohesion.

## Rules

Sentences. One idea per sentence. For descriptive and capability prose, use short declarative sentences in active voice and present tense for behaviour (past only for history). For procedural instructions such as setup steps and local commands, use imperative mood ("Start PostgreSQL:", "Run `docker-compose up -d`"). Use active voice unless the actor is genuinely unknown or irrelevant.

Person. Name the true actor and choose mood by discourse type. For descriptive prose about system behaviour, use third person and name the component that performs the action (the user, the compositor, the host desktop, the caller, the backend). For capability and feature prose, the actor is the user or caller, not the feature: "Users roll and claim characters", not "Character collection rolls"; "Users give characters to other users", not "Trading system gives". For procedural instructions, use imperative with no actor ("Start PostgreSQL:", "Build the backend:") or an actorless label ("PostgreSQL:", "Backend:"); do not invent an actor such as "the operator" or "the developer" to satisfy third person when the reader performs the action. Do not use "you", "your", "we", "our", or "us" in descriptive prose; imperatives contain no pronoun and need none. "our fork" becomes "the fork"; "you can't read your editor with the headset on" becomes "the editor is not readable with the headset on".

Personification. Software does not choose, want, know, promise, or decide. Name the actor and the action: "the fold records the home page", not "the home the capture chose". A component described as having intent obscures which code performs the action.

Terminology. Choose one term per concept and keep it. Synonym variation for stylistic relief obscures whether two names mean the same thing. If a document uses both "Rust" and "the native layer", decide which one each context needs and apply it consistently.

Definitions. Define a term where the reader first meets it, and define it once. Reference material is read out of order and in part, so a term introduced in one section and used in another is defined at first use in each, or the second use links to the first.

Figures of speech. No metaphor, idiom, rhetorical question, or aside. No sentence fragments used for effect. No punchlines, no understatement, no self-deprecation. No aphorism: a sentence shaped as a maxim, such as "text is evidence of an identity, not an identity", states a mechanism indirectly, so state the mechanism. No loaded noun standing in for one, such as a trap, a spine, a promise, or a warning, where the thing itself can be named.

Punctuation. No em-dash asides. Split the aside into its own sentence, or replace the dash with a colon when the second clause expands the first. Parentheses are acceptable for short references and qualifications.

Markdown. Keep headings, tables, code blocks, inline code, links, and lists that enumerate a real set. Remove bold, italics, and bolded lead-in labels. A bolded lead-in becomes an ordinary sentence opener: "**Import is zero-copy and per-buffer.** Wayland clients cycle..." becomes "Import is zero-copy and per-buffer. Wayland clients cycle...". Remove any formatting whose purpose is emphasis rather than structure. The result is never line-wrapped. Each paragraph occupies a single source line, and a newline ends a paragraph, a list item, or a block. Hard-wrapped prose renders as fragmented paragraphs in Markdown viewers, so wrapping corrupts the output as well as the source.

One exception applies to agent instruction files, meaning `SKILL.md` and similar. Those keep bolded lead-in labels on numbered workflow steps, where the label names the step and acts as structure. The register rules still apply to the prose that follows each label.

Headings. Name the subject, not the reading experience. "How a click reaches an application" becomes "Path of an input event". "Two details that bite if ignored" becomes "Two details matter if ignored", or the sentence is dropped and the list stands alone.

Self-reference. A document does not describe itself. "This document explains", "this section covers", and "the purpose of this issue is" announce content instead of stating it. Write the content. A genuine navigational statement, such as a table of contents entry or a cross-reference to another document, is not self-reference.

Emphasis. Emphasis carried by typography or by a catchy line is carried by plain prose instead. State the fact and its consequence in order. "Dead handles go inert. Ugly. Less ugly than a race taking down your desktop." becomes "Dead handles go inert rather than raising errors. This is a compromise, made because it is less disruptive than a race condition taking down the session."

Generated-sounding phrasing. Avoid formulaic contrasts, staged candour, and generic signposting when they add no information. Phrases such as "not X, but Y", "the honest take", "the important thing to understand", "let's unpack this", and "the bottom line" often announce a point instead of stating it. Replace them with the claim, action, or consequence directly. Prefer concrete verbs over abstract management or assistant phrasing such as "synthesize", "surface", "navigate", "operationalize", "land", and "align" when a simpler verb is available.

Avoid implicature: a sentence that gestures at a conclusion without stating it, such as "the answer is owed", "this deserves attention", or "the question arises". State the conclusion, or state what depends on it.

Avoid describing a set by its size where its members can be named. "None of the three is implemented" leaves the reader counting; "the supersede, retract, and redate events are not implemented" does not.

Use technical terms and punctuation when they describe something precise. Terms such as "synthesize", "seam", "shape", and "load-bearing", along with em dashes and parentheticals, become a problem when they are repeated mechanically, used as vague abstractions, or substituted for a concrete mechanism. Judge the wording by its context and density. A component can be "load-bearing" when a specific dependency relies on it; an integration boundary can be a "seam".

Do not simulate personal experience that the writer does not have. Avoid claims about memories, feelings, recurring observations, or physical experiences, such as "What I often feel" or "I can't tell you how many times I've...". State the observation and its evidence directly.

Judgements. Keep every judgement, and state it as a claim with a reason. Drop the attitude, not the position. "which is a debugging surface we don't need" becomes "would add a debugging surface with no offsetting benefit". "exactly backwards" becomes "counterproductive".

Characters. Use ASCII where a Unicode character adds nothing: `1920x1080`, not `1920×1080`; `2 to 4 buffers`, not `2–4 buffers`. Keep Unicode in proper nouns and in code.

## Sentence mechanics

Every declarative sentence puts its story character in the subject and the character's action in the verb. Imperative procedural steps ("Start PostgreSQL:", "Run `docker-compose up -d`") are exempt.

- The subject is the main character: a short, concrete noun or noun phrase, not a long abstract phrase.
- The verb is the character's action. Convert nominalizations (`evaluate` → `evaluation`, `decide` → `decision`, `argue` → `argument`) to verbs when they bury the clause's key action and force vague `to be` / `to have` verbs.
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

This skill governs register, not structure. Follow the structure the target dictates — an issue template, the repository's commit conventions, a README's existing shape — and write the prose to these rules.

Two carve-outs for code comments: comments stay short, and a comment that is already a single plain sentence needs no change. Do not rewrite comments in a file that the task did not otherwise touch.

## Verification

Before presenting a rewrite, check:

- No bold, italics, or em-dashes used for emphasis; no line breaks inside a paragraph; headings name the subject.
- No "you", "your", "we", "our" in descriptive prose; imperative steps are exempt.
- No self-reference ("this document", "this section"); no component that chooses, wants, knows, or promises; no invented actor ("the operator") where the reader performs the action.
- No set described by its size where members could be named; no term used but never defined.
- No nominalization hiding the verb, no long abstract subject, no subject separated from verb by a long phrase, no new information before old.
