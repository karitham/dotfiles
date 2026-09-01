---
name: plain-technical-prose
description: Use when writing or revising any prose — documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, code comments. Triggers on phrases like "less Claudish", "make this drier", "plain technical register", "too much Markdown", "de-emphasise this", "rewrite the docs", or when drafting a document that should read as a plain specification. References ASD-STE100 style discipline and Williams sentence clarity (characters-as-subjects, actions-as-verbs).
---

# Plain technical prose

Prose written to this style reads as a specification rather than as persuasion. It states what is true, why, and at what cost, without typographic emphasis or rhetorical construction. Apply it to documentation, design specs, READMEs, commit messages, PR descriptions, issue bodies, and code comments.

The reference for this style is ASD-STE100. Apply its discipline: short sentences, active voice, one topic per sentence, present tense, and controlled terminology. Do not claim conformance, and do not apply its approved-word list, which mangles domain terms such as `dmabuf`, `composite`, and `swapchain`.

This file contains two layers. The agent applies them selectively:

- **Register (Rules below):** always applied when writing or revising any prose.
- **Sentence mechanics (§Sentence mechanics):** applied only to declarative sentences when revising for clarity or when a sentence fails the `WHO is doing WHAT?` diagnostic (imperative procedural steps are exempt). The agent MUST NOT rewrite a sentence that already has a short concrete subject and an active verb carrying the action, even if the sentence uses `was/is` for cohesion.

The register rules and the sentence rules are applied together when the task is a clarity rewrite.

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

Sentence mechanics (Williams). Every declarative sentence MUST satisfy the rules in the next section: the grammatical subject MUST be the story character (short, concrete noun) and the verb MUST be the character's action. Nominalizations MUST be converted to verbs where the action is the point. Lead with subject+verb; apply Simplicity Before Complexity and Old Before New. Imperative procedural steps ("Start PostgreSQL:", "Run `docker-compose up -d`") are exempt from the subject requirement.

## Sentence mechanics — Characters as Subjects, Actions as Verbs

Source: Boston University Teaching Writing, *Sentence Clarity: Characters and Actions* script (Williams, *Style: The Basics of Clarity and Grace*, 5th ed.; Turabian, *Student's Guide to Writing College Papers*). Full PDF: https://www.bu.edu/teaching-writing/files/2020/03/Sentence-Clarity-Script.pdf

### 1. Characters as Subjects

English requires subject + tensed verb. Clarity depends on that pair aligning with the story's WHO and WHAT.

- The grammatical subject SHOULD be the main character of the clause.
- The subject SHOULD be a short, concrete noun or noun phrase, not a long abstract phrase.

BAD:
    As a walk through the woods was taking place on the part of Little Red Riding Hood, the Wolf's jump out from behind a tree occurred, causing her fright.

GOOD:
    Little Red Riding Hood was walking through the woods, and the Wolf jumped out from behind a tree and frightened her.

Why: In the BAD version the verbs are `was taking place` / `occurred` and the subjects are `walk` / `jump` (the actions nominalized as nouns). In the GOOD version the characters are subjects and the actions are verbs.

Diagnostic: Ask `WHO is doing WHAT?` If the answer's WHO is not the subject, or the WHAT is not the verb, rewrite.

### 2. Actions as Verbs — Kill Nominalizations

A nominalization is a noun formed from a verb or adjective: `evaluate→evaluation`, `decide→decision`, `persuasive→persuasion`, `argue→argument`, `arguing` (gerund). They are common in technical prose and often harmless, but they MUST be rewritten when they bury the clause's key action and force vague `to be / to have` verbs.

BAD:
    It is our requirement that a review of the data be done.

GOOD:
    The team requires that the operator review the data.

BAD:
    The evaluation of the swapchain configuration occurs before import.

GOOD:
    The compositor evaluates the swapchain configuration before import.

BAD:
    The implementation of the retract event is not yet done.

GOOD:
    The retract event is not yet implemented.

Check: If a `to be / to have / to do` verb carries the sentence and a nearby noun contains the real action (`-tion`, `-ment`, `-ance`, `-ing`), convert the noun to a verb and make its actor the subject.

`to be` is allowed only to link old information to new for cohesion (see Old Before New below), not to carry a hidden action. When `is + nominalization` can become `verb`, the agent MUST prefer the verb.

### 3. Lead with Clear Subject + Verb

Readers grasp a clause fastest when a short subject and a specific verb appear near the beginning.

#### Simplicity Before Complexity

Do not put a long introductory phrase or appositive before the subject, and do not separate subject and verb with a long phrase.

BAD:
    The most beloved child of everyone in her village, especially her grandmother, Little Red Riding Hood entered the woods.

BAD:
    Little Red Riding Hood, the most beloved child of everyone in her village, especially her grandmother, entered the woods.

GOOD:
    Little Red Riding Hood entered the woods. Everyone in her village loved her, especially her grandmother.

Technique: If an adjective phrase (e.g., `beloved` ← `to love`) contains its own character+action, split into a second sentence.

#### Old Before New

Link each sentence to the previous one by putting familiar/old information first and new information last. Flow beats local brevity.

Context: `Little Red Riding Hood entered the woods.`

GOOD (cohesive):
    She was the most beloved child of everyone in her village, especially her grandmother.

Also GOOD (more concise, less cohesive in this context):
    Everyone in her village loved her, especially her grandmother.

Trade-off: Prefer the version that keeps the same character as subject across adjacent sentences, even if it uses `was` and a few more words. Old-first aids the reader who tracks the map sentence by sentence.

Checklist for this section:

- [ ] Each clause answers `WHO is doing WHAT?` and that WHO is the subject, that WHAT is the verb.
- [ ] Subjects are short, concrete nouns. No `the walk was taking place` or `the evaluation occurs`.
- [ ] No nominalization hides the main action. `is a requirement` → `requires`; `conduct a review` → `review`.
- [ ] Subject and verb appear within the first ~6 words; no long phrase separates them.
- [ ] Each sentence starts with old/familiar information that links to the prior sentence.

## Writing new prose

Write to these rules from the first draft. Do not draft in a livelier register with the intention of flattening it later; the flattening pass loses content.

The register is the delivery, not the content. Reasoning, caveats, numbers, trade-offs, and cross-references belong in a plain-register document exactly as much as in any other. A dry document is not a shorter document.

Describe the present state. History belongs in a document about history, in a changelog, or in a commit message. Where a past decision explains a present constraint, state the constraint and its reason in the present tense rather than narrating how it came about.

## Rewriting existing prose

1. Read the whole document before changing anything. The rewrite depends on knowing which terms the document has committed to and which cross-references must survive.
2. Rewrite section by section. For each paragraph, identify what it asserts, then restate the assertions in the target register. Do not paraphrase sentence by sentence; that preserves the original's rhetorical shape.
3. Preserve content exactly. Every decision, rationale, caveat, number, file reference, link, and anchor target stays. Anchors are load-bearing: renaming a heading breaks inbound links, so update every link to a heading that is renamed.
4. Check the line count and the file list after the rewrite. A content-preserving rewrite lands close to its original length. A large drop means content was lost, not compressed.
5. For a multi-document rewrite, do all documents in one pass so terminology stays consistent across them, and state in the commit message that content is unchanged.

## Interaction with other skills

This skill governs register. It does not override document structure defined elsewhere. When drafting a GitHub issue, follow the `github-issue` structure and write its prose to these rules. When writing a commit message, follow the repository's commit conventions and write the body to these rules.

Two carve-outs apply to code comments. Comments stay short, and a comment that is already a single plain sentence needs no change. Do not rewrite comments in a file that the task did not otherwise touch.

Companion skill `software-design` governs software structure from functions through system boundaries. When prose describes a design decision, `software-design` determines what to say and this skill determines how to say it. Apply both.

## Verification

Before presenting a rewrite, check the result for: remaining bold or italic markers used for emphasis; occurrences of "you", "your", "we", "our" in descriptive prose (imperative procedural steps contain no pronoun and are exempt); em-dashes; headings that describe the reader's experience rather than the subject; and line breaks inside a paragraph. Each of these is a fast grep and each catches the common failure.

Check also for: self-reference ("this document", "this section", "this issue"); a component that chooses, wants, knows, or promises; invented actors where a feature name or "the operator"/"the developer" performs a user or reader action (e.g., "Character collection rolls" for "Users roll", "The operator starts the backend" for "Start the backend:"); a set described by its size where its members could be named; and a term used but never defined.

Check also for Williams failures in declarative sentences (imperative steps are exempt): nominalizations hiding the verb (`requirement`, `evaluation`, `review` where `require/evaluate/review` is the action); long abstract subjects; subject separated from verb by a long phrase; new information before old.

## References

- Williams, Joseph M. and Joseph Bizup. *Style: The Basics of Clarity and Grace*. 5th ed., Pearson, 2014. (Source for Characters as Subjects / Actions as Verbs via BU Teaching Writing, Sentence Clarity Script: https://www.bu.edu/teaching-writing/files/2020/03/Sentence-Clarity-Script.pdf)
- Turabian, Kate L. *Student's Guide to Writing College Papers*. 4th ed., revised by Colomb and Williams, University of Chicago Press, 2010.
- ASD-STE100 Simplified Technical English (register discipline only; approved-word list not applied).
