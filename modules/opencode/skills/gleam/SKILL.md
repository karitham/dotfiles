---
name: gleam
description: >
  Reference for idiomatic Gleam: custom types, Result/Option, decoders, pipelines
  and use, opaque types, records, labelled arguments, targets and FFI, OTP actors
  and supervision, wisp middleware, and testing. Use when writing, editing, or
  reviewing Gleam code. For generic structure, naming, and commenting see
  engineering and code-writing; this skill covers only Gleam and functional
  patterns. Trigger keywords include gleam, lustre, wisp, mist, BEAM, OTP,
  result, option, decode, use, pipeline, gleam.toml, and gleeunit.
---

# Gleam

Gleam is a type-safe functional language on the BEAM and JavaScript. Values are immutable, errors are values, and the compiler checks exhaustiveness. There are no nulls, no exceptions, and no implicit conversions. This skill covers Gleam-specific idioms. For general module depth, information hiding, and function tactics see engineering and code-writing.

## Custom Types

Custom types make illegal states unrepresentable. A closed set of variants carries its data.

BAD:

    pub type Status { Status(String) }
    pub fn is_ready(s: Status) -> Bool {
      case s { Status("ready") -> True _ -> False }
    }

GOOD:

    pub type Status { Ready Loading Failed(reason: String) }
    pub fn is_ready(s: Status) -> Bool {
      case s { Ready -> True Loading -> False Failed(_) -> False }
    }

- MUST model a closed set with a custom type, because a string allows values the domain forbids.
- MUST put data on the variant that needs it, because a shared record with optional fields allows inconsistent combinations.
- MUST handle every variant in a case, because exhaustiveness keeps logic in sync with the type.

## Result and Option

Result carries failure with a reason. Option carries absence. The two do not substitute.

BAD:

    pub fn parse_port(input: String) -> Int {
      let assert Ok(port) = int.parse(input)
      port
    }
    pub fn find_user(id: String) -> Result(User, Nil) {
      case dict.get(users, id) { Ok(u) -> Ok(u) Error(_) -> Error(Nil) }
    }

GOOD:

    pub type ParseError { NotANumber(input: String) OutOfRange(port: Int) }
    pub fn parse_port(input: String) -> Result(Int, ParseError) {
      case int.parse(input) {
        Error(_) -> Error(NotANumber(input:))
        Ok(p) if p < 1 || p > 65_535 -> Error(OutOfRange(port: p))
        Ok(p) -> Ok(p)
      }
    }
    pub fn find_user(id: String) -> Option(User) {
      case dict.get(users, id) { Ok(u) -> Some(u) Error(_) -> None }
    }

- MUST return Result with a custom error type per failure mode at application boundaries, because a string or Nil error loses structure for matching.
- MAY use Result(_, Nil) for low-level primitives where the caller adds context; stdlib does this for dict.get, int.parse, and list.first, and internal wisp and mist code uses Error(Nil) where the next step maps immediately to a Response.
- SHOULD use Option for stored fields and for find-style lookups where absence is not an error, but note stdlib's own docs prefer Result even for absence and reserve Option for arguments and stored data; pick one style per package and stay consistent.
- SHOULD thread Results with result.try, result.map, result.map_error, and list.try_map over nested cases.

## Let Assert

Let assert crashes on mismatch. Panic with panic as halts with a message for unreachable branches. Echo prints any value for debugging.

BAD:

    pub fn get_env(name: String) -> String {
      let assert Ok(v) = dict.get(env, name)
      v
    }

GOOD:

    pub fn get_env(name: String) -> Result(String, Nil) { dict.get(env, name) }
    pub fn parse_fixture_test() {
      let assert Ok(user) = decode.run(fixture_json(), user_decoder())
      user.name |> should.equal("Ada")
    }
    // Proven invariant in production is acceptable, with a message for the unreachable arm:
    pub fn weekday_name(n: Int) -> String {
      case n {
        1 -> "Mon" 2 -> "Tue" _ -> panic as { "invalid weekday: " <> int.to_string(n) }
      }
    }

- MUST NOT use let assert on external input, decodes, or dict lookups in production where failure is possible.
- MAY use let assert or panic as on a proven invariant such as a math domain, a subject that must have an owner, or a branch the type system cannot prove but the programmer can; keep the proof local and obvious.
- MAY use let assert in tests with literal fixtures.
- SHOULD prefer echo for ad-hoc debug printing over io.debug, because echo works for any type and is removed before commit.

## Pattern Matching

Case is the primary control flow. The compiler checks reachability and exhaustiveness. Guards add only a simple predicate. Stdlib never uses if for control; it uses case True/False and bool.guard.

BAD:

    pub fn label(s: Status) -> String {
      case s { Ready -> "ready" _ -> "not ready" }
    }
    pub fn div(a: Int, b: Int) -> Int {
      if b == 0 { 0 } else { a / b }
    }

GOOD:

    pub fn label(s: Status) -> String {
      case s { Ready -> "ready" Loading -> "loading" Failed(r) -> "failed: " <> r }
    }
    pub fn div(a: Int, b: Int) -> Int {
      case b == 0 { True -> 0 False -> a / b }
    }
    pub fn require_admin(req: Request, next: fn(Request) -> Response) -> Response {
      use <- bool.guard(when: !is_admin(req), return: unauthorised())
      next(req)
    }

- MUST match exhaustively without a wildcard that hides a variant.
- MUST keep guards simple and side-effect free, because guards cannot call functions.
- SHOULD prefer case True -> ... False -> ... and bool.guard with use <- for early return over if, because the stdlib and wisp idiom uses this shape and it composes with use.

## Pipelines

Data flows through |>. The left value passes as the first argument to the function on the right.

BAD:

    pub fn normalize(input: String) -> String {
      string.trim(string.lowercase(string.replace(input, "_", "-")))
    }

GOOD:

    pub fn normalize(input: String) -> String {
      input |> string.replace("_", "-") |> string.lowercase |> string.trim
    }
    pub fn with_prefix(items: List(String), p: String) -> List(String) {
      items |> list.map(string.append(p, _))
    }

- MUST design the subject of a pipelinable function as its first argument.
- SHOULD use a capture with _ to pipe into a non-first position.
- MUST NOT nest pipelines inside other calls.

## Use

Use flattens a function that takes a callback as its final argument. Code below use becomes the callback body.

BAD:

    pub fn load(path: String) -> Result(Config, LoadError) {
      result.try(read_file(path), fn(t) { result.try(parse(t), validate) })
    }

GOOD:

    pub fn load(path: String) -> Result(Config, LoadError) {
      use text <- result.try(read_file(path))
      use data <- result.try(parse(text))
      validate(data)
    }

- MUST use use only when the right-hand side is a function that takes a callback as its final argument.
- SHOULD combine use with result.try for chains of fallible steps.
- MUST keep the right-hand side a plain call; a complex expression obscures the desugaring.

## Decoders

Gleam has no reflection. Data from JSON, query strings, or Erlang is Dynamic. The gleam/dynamic/decode module builds typed decoders that compose with field, list, optional, and one_of. The language server can generate a decoder from a custom type.

BAD:

    pub fn user_from_json(json: String) -> User {
      let assert Ok(dyn) = json.parse(json, decode.dynamic)
      let assert Ok(name) = decode.run(dyn, decode.field("name", decode.string))
      User(name:, email: "")
    }

    pub fn handler(req: Request) -> Response {
      let assert Ok(json) = wisp.read_body(req)
      // manual dict.get on Dynamic
      json
    }

GOOD:

    import gleam/dynamic/decode
    pub type User { User(name: String, email: String) }
    fn user_decoder() -> decode.Decoder(User) {
      use name <- decode.field("name", decode.string)
      use email <- decode.field("email", decode.string)
      decode.success(User(name:, email:))
    }
    pub fn handler(req: Request) -> Response {
      use json <- wisp.require_json(req)
      case decode.run(json, user_decoder()) {
        Ok(user) -> wisp.json_response(to_json(user), 200)
        Error(_) -> wisp.unprocessable_content()
      }
    }

    // Optional fields, nesting, and alternatives compose:
    fn item_decoder() -> decode.Decoder(Item) {
      use name <- decode.field("name", decode.string)
      use tags <- decode.optional_field("tags", [], decode.list(decode.string))
      use kind <- decode.field("kind", decode.one_of(decode.string, or: [decode.string]))
      decode.success(Item(name:, tags:, kind:))
    }

- MUST build decoders with decode.field, decode.optional_field, decode.list, decode.optional, decode.one_of, and combine with use and decode.success, because manual dynamic access bypasses the typed decoder contract.
- MUST run decode.run and match on Result; MUST NOT use let assert on external data.
- SHOULD use decode.then and decode.map when a field needs validation into an opaque type, because then chains a Result-returning constructor into the decoder.
- SHOULD prefer decode.optional_field with a default over a bare optional when the field has a sensible default, because the call site avoids Option plumbing.

## Opaque Types

Validation happens once at the boundary. An opaque type hides its constructor and exposes only a smart constructor that returns Result.

BAD:

    pub type Email { Email(String) }
    pub fn send(to: String, body: String) -> Nil { do_send(to, body) }

GOOD:

    pub opaque type Email { Email(String) }
    pub type EmailError { EmptyEmail MissingAt }
    pub fn parse(input: String) -> Result(Email, EmailError) {
      case string.trim(input) {
        "" -> Error(EmptyEmail) t if string.contains(t, "@") -> Ok(Email(t))
        _ -> Error(MissingAt)
      }
    }
    pub fn send(to: Email, body: String) -> Nil {
      let Email(a) = to
      do_send(a, body)
    }

- MUST make validated domain values opaque.
- MUST return Result from the parse function and put all checks inside it.
- SHOULD use decode.then to lift a parse function into a decoder so the opaque invariant holds at the wire boundary.

## Records

Every value is immutable. Record update syntax copies with changes, and accessor syntax only works for shared fields.

BAD:

    pub fn promote(user: User) -> User { let u = user u.role = Admin u }

GOOD:

    pub fn promote(user: User) -> User { User(..user, role: Admin) }
    pub fn with_defaults(c: Config) -> Config {
      case c.port { Some(_) -> c None -> Config(..c, port: Some(8080)) }
    }

- MUST use User(..user, field: value) to derive a new record.
- MUST NOT assume accessor works for every field of a multi-variant type; only fields at the same position and type on every variant are directly accessible.

## Labelled Arguments

Labels make call sites self-documenting when two parameters share a type. The pipeline subject stays first.

BAD:

    pub fn create_user(a: String, b: String, c: Int) -> User { User(name: a, email: b, age: c) }

GOOD:

    pub fn create_user(name name: String, email email: String, age age: Int) -> User {
      User(name:, email:, age:)
    }
    pub fn add(over list: List(Int), each v: Int) -> List(Int) {
      list.map(list, fn(x) { x + v })
    }

- SHOULD use labelled arguments when two parameters share a type.
- SHOULD use label shorthand name: when the variable matches the label.
- SHOULD put the pipeline subject first and keep labelled arguments after it.

## Imports and Modules

A file is a module. Its path under src or test decides its name. Value imports stay qualified; type imports are the idiomatic exception.

BAD:

    import gleam/list.{map, filter}
    pub fn process(items: List(String)) -> List(String) { items |> map(string.uppercase) }

GOOD:

    import gleam/list
    import gleam/string
    import gleam/option.{type Option}
    import gleam/bytes_tree.{type BytesTree}
    pub fn process(items: List(String)) -> List(String) {
      items |> list.map(string.uppercase) |> list.filter(fn(s) { s != "" })
    }

- MUST keep value imports qualified; the qualifier documents origin.
- SHOULD import types unqualified with {type X} when the type name is the subject; this is conventional in stdlib and wisp.
- MAY alias a module only to avoid a collision.

## Targets and FFI

Gleam targets Erlang and JavaScript. @external binds to host code with an optional Gleam fallback that documents the contract. @target gates a definition to one target, and bit arrays <<>> expose binary data for protocols.

BAD:

    @external(javascript, "./ffi.mjs", "now")
    pub fn now() -> Int

GOOD:

    @external(erlang, "erlang", "system_time")
    fn sys_time(unit: Int) -> Int
    @external(javascript, "./ffi.mjs", "nowMs")
    fn now_ms() -> Int
    @target(erlang)
    pub fn now() -> Int { sys_time(1_000_000) }
    @target(javascript)
    pub fn now() -> Int { now_ms() }
    @target(erlang)
    pub fn buffer_size() -> Int { 1_000_000 }
    @target(javascript)
    pub fn buffer_size() -> Int { 40_000 }
    // Bit syntax for wire protocols, as in mist's http2 frame:
    pub fn encode_frame(len: Int, flags: Int) -> BitArray {
      <<len:size(24), flags:size(8)>>
    }

- SHOULD provide both targets or a Gleam fallback where the package supports both; BEAM-only packages like gleam_otp and mist correctly use only @external(erlang, ...).
- SHOULD use @target(erlang) and @target(javascript) for platform constants or imports rather than runtime branching when the implementation differs per target; lustre and stdlib gate entire modules this way.
- MUST validate any value returned from external code before wrapping it in an opaque type.
- MUST NOT let an external type leak into the core; the adapter translates at the edge.
- SHOULD use @internal for helpers that are public for cross-module use but not part of the public API, and hide them with internal_modules in gleam.toml.

## OTP and Concurrency

The BEAM runs actors. gleam/otp models state as an actor that owns its state and communicates via subjects and selectors. Supervision trees make restart policy declarative.

BAD:

    pub fn bad_counter() {
      let count = 0
      let _ = process.spawn(fn() { echo count })
      count
    }

GOOD:

    import gleam/erlang/process.{type Subject}
    import gleam/otp/actor
    import gleam/otp/supervision

    pub type Msg { Increment(reply: Subject(Int)) Get(reply: Subject(Int)) }

    // Builder style used throughout gleam_otp:
    pub fn start() -> Result(Subject(Msg), actor.StartError) {
      actor.new(0)
      |> actor.on_message(handle)
      |> actor.start
      |> result.map(fn(s) { s.data })
    }

    fn handle(state: Int, msg: Msg) -> actor.Next(Int, Msg) {
      case msg {
        Increment(reply) -> { let n = state + 1 process.send(reply, n) actor.continue(n) }
        Get(reply) -> { process.send(reply, state) actor.continue(state) }
      }
    }

    // Selector that merges user messages with unexpected messages:
    fn with_selector(sel: process.Selector(Msg)) -> process.Selector(Msg) {
      process.new_selector()
      |> process.select_other(fn(d) { handle_unexpected(d) })
      |> process.merge_selector(sel)
    }

    // Declarative child spec consumed by both supervisor types:
    fn child_spec() -> supervision.ChildSpecification(Msg) {
      supervision.worker(fn() { start() })
      |> supervision.restart(supervision.Transient)
    }

- MUST model shared state as an actor that owns its state and communicates via subjects and process.Selector, because the BEAM has no shared heap.
- SHOULD use the builder pattern actor.new |> on_message |> named |> restart_tolerance |> start, because gleam_otp configurers chain this way.
- SHOULD merge selectors with select_other and merge_selector to handle user and unexpected messages together.
- SHOULD use supervision.ChildSpecification and strategies OneForOne, OneForAll, RestForOne; prefer factory_supervisor for dynamic children.
- MUST give every spawned process an owner and a shutdown path; a leaked actor prevents clean shutdown.

## Wisp, Lustre, and Effects

Wisp composes HTTP as functions Request -> Response. Lustre follows Model-View-Update with Effects as data. Middleware and handlers use the same use chain, and bool.guard provides early return.

BAD:

    pub fn handle(req: Request) -> Response {
      case wisp.require_json(req) {
        Error(_) -> wisp.bad_request("need json")
        Ok(json) -> case decode.run(json, decoder()) {
          Error(_) -> wisp.unprocessable_content()
          Ok(v) -> handle_value(v)
        }
      }
    }

GOOD:

    import gleam/bool
    pub fn handle(req: Request) -> Response {
      use <- wisp.rescue_crashes
      use <- wisp.log_request(req)
      use req <- wisp.handle_head(req)
      use json <- wisp.require_json(req)
      case decode.run(json, user_decoder()) {
        Ok(user) -> wisp.json_response(to_json(user), 201)
        Error(_) -> wisp.unprocessable_content()
      }
    }

    // Guard that short-circuits the middleware chain:
    pub fn require_admin(req: Request, next: fn(Request) -> Response) -> Response {
      use <- bool.guard(when: !is_admin(req), return: wisp.response(401))
      next(req)
    }

- MUST model wisp middleware as fn(Request, fn(Request) -> Response) -> Response and invoke with use <- middleware(req) or use x <- require_x(req), because wisp's simulate harness depends on this shape.
- SHOULD use bool.guard and bool.lazy_guard for guard clauses inside middleware, because they desugar to early return without case nesting.
- SHOULD model lustre effects as data Effect(sync, before_paint, after_paint) with batch and map, not as side-effecting callbacks; lustre's runtime dispatches them and tests assert on the data.
- MAY return Result(_, Response) or Error(Nil) at the framework boundary where the error maps immediately to an HTTP response.
- SHOULD use lustre's simulate and query DSL and wisp's simulate for component and handler tests over hand-built fixtures.

## Testing

Tests use gleeunit. Each test ends in _test. Wisp and lustre provide simulators for integration-style handler tests.

BAD:

    pub fn test_add() { let r = add(2, 3) assert r == 5 }

GOOD:

    import gleeunit/should
    import wisp/simulate
    pub fn add_test() { add(2, 3) |> should.equal(5) }
    pub fn add_assert_test() { assert add(2, 3) == 5 }
    pub fn create_user_test() {
      let req = simulate.request(http.Post, "/users") |> simulate.json_body(user_json())
      router.handle_request(req, ctx) |> should.equal(201)
    }

- MUST name tests with a _test suffix in test/, because gleeunit discovers them by convention.
- SHOULD use should.equal when the failure message matters and assert when the literal is obvious; stdlib and the gleam new template use bare assert, and both are canonical.
- SHOULD use wisp/simulate or lustre's test helpers for handler and component tests rather than hand-building requests.

## Documentation

Public types and functions carry /// and the module carries //// at the top. HexDocs renders these as the contract. Generated DOM helpers in lustre may leave /// empty.

BAD:

    // loop over ids
    pub fn ids(ids: List(String)) -> List(String) { list.map(ids, fn(id) { id }) }

GOOD:

    //// User domain. Validated emails and roles. No I/O.
    /// An email that has passed parse. Use parse to construct.
    pub opaque type Email { Email(String) }
    /// Parse an email. Returns MissingAt when the string has no @.
    pub fn parse(input: String) -> Result(Email, EmailError) { todo }

- MUST document public types and functions with /// and the module with //// at the top for HexDocs; empty /// is acceptable for code-generated per-tag helpers where prose would be noise.

## Tooling

The Gleam toolchain is the gate.

GOOD:

    gleam check          # fast type feedback
    gleam format --check # CI must fail on unformatted code
    gleam test           # runs gleeunit

- MUST run gleam format and treat its output as final.
- MUST run gleam check and gleam test before considering Gleam code complete.
