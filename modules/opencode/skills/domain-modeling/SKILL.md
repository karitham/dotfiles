---
name: domain-modeling
description: Design the representation before writing code that uses it. Use before implementing a change that introduces or alters a concept, module, boundary, or data representation. Do not use for typo-level or local mechanical edits, or for reviewing code that already exists.
---

# Domain modeling

Changing a representation after code exists forces a rewrite of every caller, so choose the representation before writing the code that uses it. Code written straight from a requirement's steps is procedural by default.

## Sequence

1. **Frame the requirement as facts, not steps.** Separate the invariants that must always hold from the procedure that satisfies them. A ticket's steps describe one procedure, not the invariants the model must enforce.
2. **Derive one answer value from the acceptance criteria.** List the cases the requirement must distinguish; that list is the value's variants. The value carries the answer and the reason, and every caller reads both from it. A constraint that only names what not to build, such as "no interface", is not enforced by itself; the value enforces it. Specify operations without a value instead, and each caller builds its own answer from them.
3. **Propose representations.** When the model is contested, give two or three candidates: the types, the invariants each encodes, and what each makes easy, hard, or impossible. Pick one and say why.
4. **Freeze the interface.** Types, operations, and the invariant each operation preserves. Signatures only, no bodies.
5. **Review the model before the bodies.** For structural changes, dispatch `suckless` as a pre-code design review and resolve its model-level accusations before writing bodies.
6. **Prove one slice before replicating.** For a change that touches several call sites, take the hardest one end to end through the value and review it before touching the rest. If a site does not fit, change the value; never add an operation or interface to serve one caller.

## Artifact

Keep it short enough to read in one pass:

    Cases:       the distinct answers the requirement must give.
    Facts:       what must always hold.
    Vocabulary:  one term per concept, no synonyms.
    Types:       the representation and the invalid states it rules out.
    Operations:  signatures only; the invariant each preserves.
    Boundaries:  the effect edges and the pure core between them (impure → pure → impure).
    Absent:      what this deliberately does not model.

## Smells

Model first when the draft shows any of:

- The same question answered by more than one type: a lookup map in one caller, an enum in another, a result struct in a third. No value holds the shape; derive one and make every caller switch on it.
- A new operation or interface that serves a single caller or a test fake. The call site needed a shape change; make it in the value instead of growing the surface.
- A role-named type holding one behavior: `Validator`, `Hydrator`, `Manager`, `Service`. Prefer a function. A validator returns an error and leaves the invalid value usable; a parse or constructor returns a type that cannot be invalid.
- Decisions and effects written directly as control flow instead of built as a value. Build the plan as data and pass it to a function that executes it; a plan in the control flow cannot be inspected, transformed, or tested.
- A concept's rules scattered across unrelated functions with no single home. Gather them into one module of pure functions over the concept's type. Plain data with functions over it is fine; the fault is scatter and unexpressed invariants, not missing methods.
- Repeated `if kind == ...` or a type switch on a field. The representation does not express the domain; replace the flag with variants.
- Several values that always travel together and have no type of their own. Name the concept they represent.
- A function body that is a numbered list of mechanical steps, or helpers each called once. Decomposition by control-flow step, not by concept; a short list of domain operations is fine and quality-code covers the split.

A requirement that enumerates credential states (valid, archived, revoked, disabled, unshared) is one value with those cases. Specify classify and resolve operations instead, and each endpoint reads its own view from the value: a credential map for funding, an enum for destinations, a struct for listing.

software-architecture and quality-code state the targets; this skill applies them before there is code to review.
