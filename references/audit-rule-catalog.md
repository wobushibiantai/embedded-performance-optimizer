# Embedded Optimization Audit Rule Catalog

Apply a rule only when its stated trigger holds. Severity is contextual: `critical` means a likely deadline, corruption, or safety failure; `high` means a material performance/resource risk; `medium` means workload-dependent waste; `info` means a measurement or build-quality opportunity.

## Computation and CPU

### OPT-CPU-01 — Software floating point in a hot or bounded path

- Trigger: the target lacks suitable hardware FPU support, the ABI/build does not enable it, or generated code calls software floating-point helpers; the operation is frequent or deadline-critical.
- Check: target/FPU flags, disassembly and helper symbols such as floating-point runtime calls, call frequency, accuracy requirements.
- Fix: consider scaled fixed-point or integer arithmetic; define scale, range, rounding, saturation, overflow behavior, and error tolerance. Keep floating point when it is clearer and measured cost is acceptable.
- Verify: numerical error across boundary inputs, cycle distribution, code size, stack use.

### OPT-CPU-02 — Expensive division, modulo, or transcendental operation

- Trigger: variable division/modulo, `pow`, trig, logarithm, or similar work occurs in a confirmed hot path or ISR.
- Check: compiler output first; constant power-of-two operations are normally strength-reduced automatically. Signed right shift and negative division semantics may differ from a naive rewrite.
- Fix: use reciprocal multiplication, lookup/interpolation, CORDIC, fixed-point, or a domain-specific approximation only with a stated error bound.
- Verify: exhaustive or property tests over valid input range and target cycle measurements.

### OPT-CPU-03 — Loop-invariant or repeated computation

- Trigger: a loop/callback repeats address calculation, conversion, parsing, calibration, bounds, or configuration work whose inputs do not change.
- Check: aliasing, volatile/MMIO semantics, concurrency, compiler optimization report.
- Fix: hoist, cache, precompute, or change representation without suppressing required hardware reads.
- Verify: equivalent results under state changes and measured cycle reduction.

### OPT-CPU-04 — Excessive call overhead on a tiny hot function

- Trigger: profiling or disassembly shows calls dominate a tiny frequently executed function.
- Check: whether the compiler already inlines it, function-pointer/ABI boundaries, I-cache and flash impact.
- Fix: use ordinary `inline`/`#[inline]` first; reserve force-inline attributes for measured cases. Do not force recursion, large bodies, cold paths, or address-taken functions.
- Verify: disassembly, text size, I-cache behavior, and end-to-end latency.

### OPT-CPU-05 — Missed DSP/SIMD or hardware primitive

- Trigger: saturating arithmetic, MAC, CRC, bit operations, byte swaps, or vectorizable loops dominate runtime and the target supplies a suitable instruction/peripheral.
- Check: compiler code generation, alignment, vector width, tail handling, numerical semantics.
- Fix: enable correct architecture flags, use portable intrinsic/library support, then target intrinsics if necessary.
- Verify: bit-exactness or tolerance, alignment cases, scalar fallback, target speed.

### OPT-CPU-06 — Branch-heavy or data-dependent hot path

- Trigger: measured stalls or timing variability correlate with unpredictable branches or input-dependent loops.
- Check: target pipeline/predictor, input distribution, WCET implications.
- Fix: simplify decisions, use bounded tables or branchless operations only when they are faster and do not introduce unsafe arithmetic.
- Verify: representative and adversarial inputs, tail latency, code size.

## Data movement, peripherals, and DMA

### OPT-IO-01 — CPU-driven bulk transfer

- Trigger: CPU copies or polls substantial SPI/UART/I2C/ADC/DAC/memory traffic and the transfer size/frequency can amortize DMA setup.
- Check: DMA availability, setup cost, bus contention, transfer break-even size, cache coherency, alignment, latency needs.
- Fix: use DMA with explicit buffer ownership, completion/error handling, timeout/recovery, and cache maintenance. Retain polling/interrupt paths for short transfers when faster.
- Verify: throughput, CPU occupancy, latency, overrun/error recovery, energy.

### OPT-IO-02 — Byte-at-a-time or fragmented transactions

- Trigger: throughput paths repeatedly invoke per-byte APIs, toggle chip select unnecessarily, or issue many tiny storage/network operations.
- Check: protocol transaction boundaries, FIFO size, device limits, latency budget.
- Fix: batch into legal bursts, use FIFO thresholds, scatter/gather, or buffered APIs.
- Verify: protocol trace, throughput, first-byte latency, buffer bounds.

### OPT-IO-03 — Redundant copies

- Trigger: payloads are copied through multiple queues/layers without transformation or ownership need.
- Check: lifetime, mutability, DMA constraints, producer/consumer concurrency.
- Fix: transfer ownership, use views/spans/slices, ping-pong buffers, scatter/gather, or bounded zero-copy.
- Verify: use-after-free/reuse safety, cache behavior, peak RAM, throughput.

### OPT-IO-04 — Busy polling without a proven latency need

- Trigger: a task or main loop repeatedly polls a peripheral/event while useful sleep or work is possible.
- Check: required response time, poll duration, interrupt availability and reliability, power mode wake sources.
- Fix: interrupt/event-driven waiting, bounded hybrid spin-then-sleep, or RTOS notification.
- Verify: response latency, missed events, CPU load, energy.

## RAM, stack, and layout

### OPT-RAM-01 — Unbounded or nondeterministic dynamic allocation

- Trigger: allocation occurs after initialization, in ISR, or in a hard-real-time/high-reliability path without bounds for latency, fragmentation, and failure.
- Check: allocator implementation, maximum live objects, failure handling, synchronization, fragmentation test.
- Fix: static allocation, fixed-capacity containers, slab/pool/arena, or initialization-only allocation. In Rust, `#![no_std]` alone does not prohibit an allocator; avoid `alloc` or enforce a bounded allocator/API design.
- Verify: exhaustion behavior, maximum latency, long-duration fragmentation, RAM high-water mark.

### OPT-RAM-02 — Large or unbounded stack use

- Trigger: large automatic arrays/objects, recursion, VLAs, deep call graphs, formatting, or large interrupt frames exist near a stack limit.
- Check: compiler stack-usage output, RTOS high-water marks, interrupt nesting, worst call chain.
- Fix: bound recursion or make it iterative; move long-lived buffers to an owned static/pool region; split or stream work. Do not blindly make shared globals.
- Verify: worst-case stack with margin in all tasks and interrupt contexts.

### OPT-RAM-03 — Wasteful structure layout

- Trigger: many instances or transmitted/stored arrays waste meaningful RAM due to padding.
- Check: `sizeof`, alignment, field offsets, array count, ABI/FFI/serialization constraints, access-cost penalty.
- Fix: reorder fields when layout is private; split hot/cold fields; narrow only with proven ranges. Avoid packed structs for normal CPU access.
- Verify: static size assertions, alignment-safe access, ABI/wire compatibility, speed.

### OPT-RAM-04 — Oversized queues and buffers

- Trigger: buffers are sized by guesswork, duplicate the same burst allowance, or consume significant reserved RAM.
- Check: arrival/service rates, burst length, backpressure, loss policy, observed high-water marks.
- Fix: derive capacity from workload and deadline; consolidate buffers or stream where safe.
- Verify: overload tests, queue high-water telemetry, drop/block behavior.

### OPT-RAM-05 — Inefficient data representation

- Trigger: booleans/enums/indices/timestamps or sparse data consume material RAM or bandwidth at scale.
- Check: numeric ranges, atomicity, alignment, conversion cost, ABI stability.
- Fix: use explicit-width types, bitsets, indices, compact state, or delta encoding when savings exceed access cost.
- Verify: range and serialization tests, performance, atomic access requirements.

### OPT-RAM-06 — Unsafe storage reuse

- Trigger: union/overlay/pool buffer is reused across asynchronous operations or unclear ownership phases.
- Check: ISR/DMA/task lifetimes and cancellation/error paths.
- Fix: explicit state machine, ownership transfer, generation counter, or separate storage.
- Verify: race tests, delayed completion, timeout and retry scenarios.

## Flash and code size

### OPT-FLASH-01 — Immutable data copied into RAM

- Trigger: lookup tables, fonts, strings, or configuration intended to be immutable consume `.data`/heap unexpectedly.
- Check: map file and relocations; `const` does not guarantee physical flash placement on every toolchain/architecture.
- Fix: use `const`/`static` plus the toolchain's section/linker placement where required; avoid APIs that force RAM copies.
- Verify: map/ELF sections, startup time, flash access performance.

### OPT-FLASH-02 — Heavy formatting/runtime features

- Trigger: `printf` family, float formatting, iostreams, panic formatting, backtraces, unwinding, RTTI, exceptions, or generic instantiations materially inflate firmware.
- Check: map file, symbol sizes, feature flags, actual diagnostic requirements.
- Fix: lightweight bounded formatting, binary events, feature removal, size-oriented profiles, or deferred host decoding. Preserve required diagnostics and safety behavior.
- Verify: text/rodata size, stack, output correctness, failure diagnostics.

### OPT-FLASH-03 — Dead code or unused data retained

- Trigger: map file shows unreachable modules, duplicate libraries, unused tables, or uncollected sections.
- Check: per-function/data sections, linker roots/KEEP directives, registration tables, interrupt vectors.
- Fix: enable section garbage collection/LTO as supported and remove unused features/dependencies.
- Verify: boot, vectors, constructors/registries, full feature tests, size delta.

### OPT-FLASH-04 — Uncontrolled inlining or monomorphization

- Trigger: text growth comes from forced inlining, templates, generics, or repeated panic/format paths.
- Check: size reports and symbol duplication.
- Fix: outline cold paths, remove force-inline, share non-generic helpers, reduce feature combinations.
- Verify: code size and hot-path latency together.

## Interrupts, concurrency, and RTOS

### OPT-RT-01 — Excessive ISR work

- Trigger: ISR performs parsing, formatting, allocation, blocking, bulk copies, long loops, or nonessential computation.
- Check: worst-case ISR cycles, interrupt arrival rate/nesting, peripheral acknowledge timing.
- Fix: acknowledge/capture minimal state, enqueue or notify deferred work using ISR-safe primitives, and bound queue overflow behavior.
- Verify: interrupt latency, event loss, nesting, overload and error paths.

### OPT-RT-02 — Long critical or interrupt-disabled section

- Trigger: critical sections contain loops, peripheral waits, logging, callbacks, or copies.
- Check: maximum duration and affected interrupt/task priorities.
- Fix: shrink protected state, move work outside, use double buffering or suitable atomic operations.
- Verify: worst-case latency and race correctness under contention.

### OPT-RT-03 — ISR/task or core/core data race

- Trigger: mutable state is shared without a valid synchronization and memory-ordering design.
- Check: access width atomicity, compiler reordering, core/cache coherence, interrupt preemption, RTOS API legality.
- Fix: critical section, atomic with justified ordering, queue/channel, mutex in task context, or ownership transfer. `volatile` is not synchronization; ordinary blocking mutexes are usually invalid in ISR context.
- Verify: stress/interleaving tests and platform memory-model requirements.

### OPT-RT-04 — Priority inversion or unbounded blocking

- Trigger: high-priority work waits on lower-priority work, a shared mutex, queue, allocation, or driver without a blocking bound.
- Check: priority inheritance/ceiling, lock order, critical duration, dependency graph.
- Fix: shorten ownership, use an appropriate protocol, server task, lock ordering, or architecture change.
- Verify: response-time analysis and forced-contention test.

### OPT-RT-05 — Excessive context switching or wakeups

- Trigger: high-frequency timers, one-item messages, task-per-stage design, or broadcast events dominate CPU/power.
- Check: RTOS trace, switch rate, run-queue behavior, cache impact.
- Fix: batch work, coalesce timers/events, direct notification, or combine stages when isolation is not required.
- Verify: latency, throughput, fairness, energy.

### OPT-RT-06 — Unbounded real-time operation

- Trigger: retries, waits, searches, parsing, allocation, recursion, or input-dependent loops lack a defensible bound on a deadline path.
- Check: worst valid input and failure states.
- Fix: explicit iteration/time limits, bounded containers, admission control, precomputation, or controlled degradation.
- Verify: adversarial inputs and deadline analysis.

## Cache, MMIO, and memory ordering

### OPT-MEM-01 — DMA cache-coherency defect

- Trigger: DMA accesses cacheable memory on a non-coherent target.
- Check: direction-specific clean/invalidate rules, cache-line alignment, partial-line sharing, descriptor rules, barriers.
- Fix: use coherent/noncacheable regions where appropriate or exact vendor-prescribed maintenance and ownership transitions.
- Verify: stress with varied sizes/alignments and unrelated data sharing boundary cache lines.

### OPT-MEM-02 — Misaligned or packed hot access

- Trigger: packed structs, byte buffers cast to wider types, or DMA descriptors violate alignment or cause repeated unaligned access.
- Check: architecture fault behavior, compiler code, ABI and wire format.
- Fix: explicit decode/encode with copies or aligned fields; separate wire layout from working layout.
- Verify: sanitizers where available, boundary alignment cases, target performance.

### OPT-MEM-03 — Incorrect MMIO access semantics

- Trigger: peripheral registers use ordinary memory, cached aliases, invalid read-modify-write, wrong access width, or missing ordering.
- Check: device header, reference manual, errata, barrier requirements.
- Fix: platform MMIO primitives and exact register sequence. Use `volatile` for required accesses, not for inter-thread synchronization.
- Verify: hardware trace and fault/recovery paths.

### OPT-MEM-04 — Poor locality or bus contention

- Trigger: profiling shows cache misses, flash wait stalls, SRAM-bank conflicts, or CPU/DMA contention.
- Check: memory map, access pattern, cache counters, bus matrix, linker placement.
- Fix: improve traversal/layout, separate contending buffers, place measured hot code/data in suitable memory, tune bursts.
- Verify: counters, latency tails, DMA throughput, section map.

## Power

### OPT-PWR-01 — Idle busy loop

- Trigger: the CPU spins when no immediate work is pending and wake sources can meet response requirements.
- Check: race between final event check and sleep, debug behavior, interrupt mask state, wake latency.
- Fix: event-based idle with the architecture/RTOS-approved wait instruction; use tickless idle for sufficiently long gaps.
- Verify: no lost wakeups, latency, idle current, timer correctness.

### OPT-PWR-02 — Unnecessary peripheral clocks or active blocks

- Trigger: unused or inactive peripherals, PLLs, oscillators, DMA, analog blocks, or buses remain enabled.
- Check: wake/startup time, shared clock dependencies, retention, errata.
- Fix: reference-count or state-manage clocks and power domains; restore configuration safely.
- Verify: all modes, wake paths, peripheral reinitialization, energy.

### OPT-PWR-03 — Unsafe or wasteful unused GPIO state

- Trigger: unconnected pins float or board-connected pins cause leakage/contention.
- Check: schematic, package pin, internal pulls, boot straps, analog capability, external circuitry. Analog mode is common but not universally correct.
- Fix: configure each unused pin to the board/vendor-recommended low-leakage state.
- Verify: sleep current across boards and reset/boot transitions.

### OPT-PWR-04 — Excessive wakeup, logging, or radio activity

- Trigger: energy trace is dominated by periodic ticks, telemetry, flash writes, sensor sampling, display, or radio transactions.
- Check: energy by subsystem and useful work per wakeup.
- Fix: coalesce work, reduce rate, batch transmissions/writes, cache state, or use autonomous peripheral modes.
- Verify: energy per completed task, latency, data-loss requirements, endurance.

## Build and verification

### OPT-BUILD-01 — Target flags do not match hardware

- Trigger: CPU/ISA/FPU/ABI/memory-model flags are missing or inconsistent across objects/libraries.
- Check: verbose build, ELF attributes, disassembly, linker diagnostics.
- Fix: set one validated target configuration and rebuild every incompatible object.
- Verify: clean build, ABI inspection, hardware functional tests.

### OPT-BUILD-02 — Optimization profile is unverified

- Trigger: debug/unoptimized builds are benchmarked, or release flags/LTO are changed without correctness and timing regression.
- Check: exact reproducible flags and generated artifacts.
- Fix: define performance and size profiles with controlled flags; retain symbols/trace needed for diagnosis.
- Verify: full tests, timing, size, stack, startup, debugging needs.

### OPT-BUILD-03 — No performance regression gate

- Trigger: a critical latency/throughput/size/power property has no repeatable benchmark or threshold.
- Check: workload stability, measurement noise, hardware variance.
- Fix: add a target benchmark or trace-based check with justified tolerance; keep functional assertions separate.
- Verify: repeated runs detect an intentional regression without flakiness.
