# Embedded Performance Optimization Rules

Use this reference selectively after the primary workflow in `SKILL.md`. Hardware manuals, compiler documentation, ABI rules, errata, and measurements for the actual target take precedence over these general rules.

## 1. Measurement and experiment design

- Define metrics before tuning: cycles or time per operation, interrupt latency, deadline miss rate, jitter percentiles, throughput, RAM/flash, stack high-water mark, bus utilization, and energy per task as applicable.
- Benchmark a realistic release build on the target. Control clock configuration, caches, wait states, thermal conditions, input data, peripheral state, and competing interrupts.
- Warm or deliberately cold-start caches and predictors according to the real workload. Report which condition was tested.
- Measure enough samples to expose tails. Report median and a high percentile or maximum for variable-latency paths.
- Account for probe effects: logging, semihosting, debugger attachment, instrumentation, and GPIO toggling can alter timing.
- Keep a small reproducible benchmark or trace capture with pass/fail thresholds. Prevent the compiler from deleting benchmark work, but do not pollute production code with fake `volatile` accesses.

## 2. Algorithm and data flow

- Reduce algorithmic complexity and the frequency of work before tuning instructions.
- Move invariant computation out of loops and callbacks. Precompute bounded tables when flash/RAM cost and interpolation error are acceptable.
- Batch work to amortize interrupt, syscall, bus transaction, lock, and wakeup overhead, while respecting latency limits.
- Eliminate redundant parsing, formatting, conversion, checksum, traversal, copying, and repeated peripheral register access.
- Prefer streaming or incremental processing when it reduces peak memory and copying without introducing excess per-item overhead.
- Apply early exits and fast paths only when common-case probability is measured and the added branching/code size does not harm the target.

## 3. CPU and arithmetic

- Match arithmetic to hardware: fixed point can outperform software floating point, but specify scale, rounding, saturation, overflow bounds, and error budget. Do not replace hardware floating point reflexively.
- Avoid division, modulo, transcendental functions, and wide arithmetic in hot paths when an equivalent, accurate, measured alternative exists. Constant divisors are often optimized by compilers; inspect output first.
- Select integer widths based on data range and native machine behavior. Narrow types may trigger extra extensions or packing operations; wider types may increase memory traffic.
- Help the compiler with clear aliasing and constness contracts only when they are true. Never use `restrict` or type punning to promise false properties.
- Prefer compiler intrinsics for saturating arithmetic, SIMD/DSP instructions, bit operations, and barriers. Use handwritten assembly only for demonstrated gaps, with ABI clobbers, constraints, and a maintainable fallback.
- Consider branch predictability, pipeline stalls, dependency chains, loop unrolling, and function inlining only after profiling. More inline code can increase I-cache pressure and flash size.

## 4. Memory layout, cache, and buses

- Improve locality by arranging hot data together, iterating in storage order, and separating frequently accessed fields from cold metadata when evidence supports it.
- Align buffers and descriptors to the requirements of the core, cache, DMA engine, and bus. Avoid packed structs for ordinary access; use explicit serialization for wire formats.
- Minimize pointer chasing and unpredictable accesses on cache-based systems. On small MCUs without cache, prioritize wait states, SRAM/flash placement, and bus contention instead.
- Place truly critical code/data in fast memory only after checking linker placement, capacity, startup copying, and contention with DMA or other masters.
- Treat memory-mapped I/O accesses as hardware operations. Preserve required ordering, access width, read-modify-write rules, and documented delays.
- Reduce false sharing and shared cache-line bouncing on multicore systems. Respect cache-line granularity in ownership and synchronization design.

## 5. DMA and zero-copy

- Use DMA when transfer size and concurrency amortize setup, completion, and cache-maintenance cost. Polling or interrupt-driven I/O can be better for short transfers.
- Define buffer ownership as a state machine. Prevent CPU/device access races and premature reuse.
- On non-coherent systems, clean or invalidate the correct cache range in the correct direction, including line alignment and memory barriers. Follow vendor rules for descriptors separately from payloads.
- Prefer scatter/gather, ping-pong, circular buffers, and chained descriptors when they reduce copies and gaps, but verify wraparound and overrun behavior.
- Ensure buffers meet addressability, lifetime, alignment, and memory-region restrictions. A zero-copy design is not valid if it silently shifts copies or forces expensive cache operations elsewhere.

## 6. Interrupts, concurrency, and RTOS

- Bound ISR execution and interrupt-disabled regions. Move parsing, allocation, logging, and bulk copies out of high-priority ISRs.
- Set interrupt priorities from latency requirements and hardware/RTOS constraints. Verify priority inversion rules, nesting, tail chaining, and APIs legal from ISR context.
- Reduce context switches, task wakeups, timer ticks, and lock contention by batching or event-driven design where deadlines allow.
- Use the lightest synchronization primitive that correctly expresses ownership and ordering. Measure contention; lock-free designs can be slower and less predictable.
- Avoid priority inversion with appropriate protocol or architecture. Check blocking time as part of response-time analysis.
- Size stacks from measured high-water marks plus justified margin across worst nesting, library calls, interrupts, and exceptional paths. Do not optimize RAM by erasing safety margin blindly.
- Prefer static allocation when deterministic lifetime and fragmentation matter. If dynamic allocation remains, characterize latency, failure behavior, fragmentation, and synchronization.

## 7. I/O and protocol paths

- Match transfer size, FIFO thresholds, baud/clock rates, chip-select behavior, and burst settings to peripheral and device limits.
- Avoid byte-at-a-time APIs in throughput paths when block operations exist. Combine transactions only when protocol semantics permit.
- Replace formatting-heavy logging in time-critical paths with deferred binary trace or rate-limited events. Measure production builds with the intended logging level.
- Apply backpressure explicitly. Define behavior for full queues, DMA overruns, dropped samples, and slow consumers.
- For networking or storage, distinguish CPU cost from peripheral latency, bus bandwidth, copying, checksums, and queueing before optimizing.

## 8. Compiler, linker, and build

- Compare optimization levels with functional and timing tests. Do not assume the highest level wins for code size, latency, or debuggability.
- Use target-correct CPU, ISA, FPU, ABI, and memory-model flags. A mismatched ABI or FPU setting is a correctness issue, not merely a missed optimization.
- Evaluate LTO and profile-guided optimization if supported by the embedded workflow; confirm compatibility with startup code, interrupts, linker scripts, debugging, and certification constraints.
- Enable function/data sections and linker garbage collection when suitable, then inspect the map to ensure required registration tables, vectors, and retained sections survive.
- Remove accidental debug checks and tracing from performance builds only when they are not safety requirements. Preserve assertions or diagnostics appropriate to the product risk.
- Inspect generated assembly for a small number of confirmed hot paths, not the entire codebase.

## 9. Flash, RAM, and stack

- Track text, read-only data, initialized data, zero-initialized data, heap, per-task stacks, DMA buffers, and reserved regions separately.
- Prefer removing unused features and duplicate libraries before compressing data structures manually.
- Trade computation for tables only with a whole-system budget. Tables can increase flash, cache misses, startup time, and energy.
- Store immutable data in flash/ROM when access cost is acceptable. Beware relocation or APIs that cause hidden RAM copies.
- Reuse buffers only with explicit lifetime analysis. Overlaying storage across asynchronous operations is a common corruption source.
- Treat recursion, variable-length arrays, large automatic objects, and library formatting functions as stack risks unless tightly bounded.

## 10. Real-time and worst-case behavior

- Distinguish throughput, average response, worst-case response, and jitter; optimize the metric tied to the requirement.
- Include interrupt interference, blocking, preemption, cache misses, flash wait states, DMA contention, bus arbitration, and critical sections in timing reasoning.
- Avoid unbounded loops, retries, queue waits, allocation, and input-dependent algorithms on hard-deadline paths unless a defensible bound exists.
- Check overload behavior. Graceful degradation, admission control, or controlled data loss can be safer than queue growth and cascading deadline misses.
- Re-run schedulability or response-time analysis after changing execution time, priorities, periods, blocking, or task structure.

## 11. Power and thermal performance

- Measure current over complete workload phases and calculate energy per useful operation. Include regulator and peripheral costs when relevant.
- Race-to-sleep works only when higher frequency/voltage and wake/sleep overhead produce lower total energy. Verify it on the board.
- Consolidate timers and wakeups, use tickless idle where suitable, and place peripherals into low-power states without breaking wake latency.
- Reduce radio, sensor, display, and flash activity before chasing CPU instruction savings when those dominate power.
- Confirm sustained performance under thermal limits and voltage/clock scaling; short benchmarks can hide throttling or battery constraints.

## 12. Change acceptance checklist

Accept an optimization only when the relevant items hold:

- Functional and numerical results remain within specified tolerances.
- The target metric improves under a reproducible representative workload.
- Tail latency and hard deadlines do not regress.
- RAM, flash, stack, power, thermal, and startup effects are understood.
- Concurrency, interrupt, DMA, cache, and memory-ordering behavior is correct.
- Supported compilers, configurations, and hardware variants still build and behave as required.
- The implementation explains target-specific assumptions and includes a regression benchmark or threshold where practical.
- The measured benefit justifies added complexity and portability cost.
