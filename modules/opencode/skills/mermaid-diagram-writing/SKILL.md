---
name: mermaid-diagram-writing
description: Guidelines for creating clear, readable Mermaid diagrams. Covers minimal styling, preferring many small focused diagrams over one large diagram, participant naming, structured flow control with alt/else/loop/opt, consistent message patterns, and common patterns for API endpoints and error handling. Use when creating sequence diagrams, flowcharts, architecture diagrams, or any visual representation of system behavior.
---

# Mermaid Diagram Writing

## Core Rules

### 1. Keep Diagrams Simple

Avoid colored rectangles and complex styling. Use `theme: base` or let renderers use their default minimal style.

### 2. Prefer Many Small Diagrams Over One Big Diagram

**Bad** - One large diagram trying to show everything:
```mermaid
sequenceDiagram
    participant A
    participant B
    participant C
    participant D
    participant E
    A->>B: 1
    B->>C: 2
    C->>D: 3
    D->>E: 4
    -- lots more steps --
```

**Good** - Multiple focused diagrams:
```mermaid
sequenceDiagram
    participant FE
    participant BE
    FE->>BE: Request
    BE-->>FE: Response
```

### 3. Diagram Scope Guidelines

- **Max 4-5 participants** per diagram
- **Max 10-15 messages** per sequence diagram
- Each diagram should tell one coherent story

### 4. Participant Naming

- Use short, clear names: `FE`, `BE`, `DB`, `Provider`, `User`
- Avoid: `FrontendApplication`, `BackendService`

### 5. Use Structured Flow Control

Leverage `alt`/`else`, `loop`, and `opt`:

```mermaid
sequenceDiagram
    participant FE
    participant BE
    FE->>BE: Request
    alt Success
        BE-->>FE: 200 OK
    else Error
        BE-->>FE: 400 Error
    end
```

### 6. Consistent Message Patterns

- **Queries**: `Source->>Target: Action`
- **Responses**: `Target-->>Source: Result`

### 7. Label Everything

- Always label `alt`/`else` blocks
- Include status codes when relevant

## Common Patterns

### API Endpoint
```mermaid
sequenceDiagram
    participant Client
    participant Server
    participant DB
    Client->>Server: POST /resource
    Server->>DB: Insert
    DB-->>Server: Result
    Server-->>Client: 201 Created
```

### Error Handling
```mermaid
sequenceDiagram
    participant FE
    participant BE
    FE->>BE: Request
    alt Valid
        BE-->>FE: Success
    else Invalid
        BE-->>FE: 400 Error
    end
```

### Conditional Flow
```mermaid
sequenceDiagram
    participant FE
    participant BE
    participant Provider
    FE->>BE: Check status
    BE->>Provider: Verify
    alt Exists
        Provider-->>BE: found
        BE-->>FE: { status: active }
    else Not Found
        Provider-->>BE: not found
        BE-->>FE: { status: deleted }
    end
```

## When to Split

- More than 5 participants
- More than 15 messages
- Multiple unrelated flows mixed together
