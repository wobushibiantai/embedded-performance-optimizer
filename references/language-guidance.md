# C, C++, and Rust Guidance

Read only the language sections relevant to the project. Target manuals, ABI documentation, compiler output, and the project's safety rules take precedence.

## C

- Use fixed-width integer types for registers, wire formats, persistent layouts, and arithmetic with exact width requirements. Use native-width types for ordinary loop indices only when range and ABI permit.
- `const` expresses immutability through an access path; confirm placement with the linker map. Use linker sections only when ordinary placement is insufficient.
- `volatile` is appropriate for MMIO and objects modified outside the abstract machine in toolchain-supported patterns. It does not make compound operations atomic or create inter-thread ordering.
- Use `_Static_assert` for structure size/offset, buffer capacity, and configuration invariants. Check multiplication/addition before allocating or indexing.
- Treat `restrict` as a correctness promise. Add it only when all callers satisfy non-aliasing for the full access lifetime.
- Prefer explicit serialization over casting packed network/device data to structs. Avoid unaligned dereferences and strict-aliasing violations.
- For pools and static buffers, define ownership, exhaustion behavior, alignment, concurrency protection, and maximum lifetime.

## C++

- Apply the C rules where relevant. Confirm which language/runtime features the platform supports rather than banning C++ abstractions categorically.
- Prefer fixed-capacity containers, spans/views, RAII ownership, and compile-time configuration. Audit hidden allocation in `std::function`, strings, containers, exceptions, and third-party APIs.
- If exceptions/RTTI are disabled, ensure all code and libraries agree and that error paths remain explicit. If enabled, measure code size and define failure behavior.
- Avoid virtual dispatch only on confirmed hot paths or where it blocks whole-program optimization. Interfaces with compile-time polymorphism can grow flash through duplication.
- Use `constexpr`/`consteval` for genuine compile-time work while watching generated tables and code size.
- Keep constructors before scheduler/startup ordering deterministic; avoid uncontrolled static initialization dependencies.

## Rust

- `#![no_std]` removes the standard library dependency but does not by itself forbid heap allocation. Avoid the `alloc` crate/global allocator for heap-free designs, or supply a bounded allocator with explicit failure behavior.
- Prefer fixed-capacity collections, slices, iterators that compile to efficient loops, and ownership transfer. Verify generated code for critical abstractions rather than assuming zero cost.
- Use `Atomic*` only for supported widths and with a justified ordering. `Relaxed` supplies atomicity but not cross-variable synchronization; use Acquire/Release or critical sections where the protocol requires them.
- Use an interrupt-aware mutex/critical-section abstraction appropriate to the runtime. A blocking task mutex is generally not safe inside an ISR.
- `Send` and `Sync` prevent classes of sharing errors only when all `unsafe` implementations and HAL abstractions uphold their contracts; they do not prove protocol timing or logical race freedom.
- Use typestate to encode legal peripheral modes, initialized state, pin ownership, DMA ownership, and transfer lifecycle when it simplifies invalid-state prevention. Do not add type complexity without a concrete invariant.
- `#[repr(Rust)]` layout is not a stable ABI contract; do not rely on field order or padding. Use `#[repr(C)]` for FFI/stable layout and explicit serialization for wire/storage formats. Reordering fields manually can reduce current size but must not become an undocumented ABI dependency.
- `#[repr(packed)]` can create unaligned references and should not be used as a general RAM optimization. Decode into an aligned working representation.
- `#[inline]` is a hint; `#[inline(always)]` can bloat flash. Use it only after inspecting code generation and measuring the hot path.
- Control panic behavior deliberately (`panic = "abort"` when appropriate), and audit formatting, unwinding, debug assertions, overflow checks, and backtrace features in the release profile.
- Evaluate `opt-level`, `lto`, `codegen-units`, `strip`, and `panic` together for speed/size needs. Confirm interrupt symbols, linker scripts, memory regions, and target features after changes.
- Encapsulate MMIO in vetted PAC/HAL APIs or volatile pointer primitives with documented safety invariants. `unsafe` blocks should be small and explain aliasing, lifetime, alignment, and concurrency assumptions.

## Refactoring examples

### Fixed-point conversion

Do not mechanically replace floating point. Derive the representation first:

```text
real_value = stored_integer / SCALE
required range -> integer width
maximum intermediate -> wider accumulator
rounding rule -> truncation / nearest / ties policy
overflow rule -> reject / clamp / saturate
```

For a temperature stored in centi-degrees, `2534` can represent `25.34`, but multiplication and filtering may require a 32- or 64-bit intermediate. Tests must cover negative values and both range endpoints.

### ISR deferral

Keep hardware acknowledgement and timestamp/sample capture in the ISR. Transfer a bounded event or buffer ownership with an ISR-safe primitive; perform parsing, formatting, allocation-free protocol work, and application callbacks in task context. Define queue-full behavior explicitly.

### DMA ownership

Represent `Free -> FillingByCPU -> OwnedByDMA -> Complete -> OwnedByCPU -> Free`. Cache maintenance and barriers belong at documented transitions. Timeouts and errors must return the buffer to exactly one owner.
