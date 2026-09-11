---
name: embedded-performance-optimizer
description: Analyze, review, and optimize embedded firmware performance, including CPU time, latency, memory, flash, cache, DMA, interrupts, RTOS scheduling, I/O throughput, and energy. Use for performance investigations, code reviews, optimization plans, or implementation work on MCU, DSP, SoC, bare-metal, or RTOS projects. Do not use for general correctness-only debugging without a performance objective.
---

# Embedded Performance Optimizer

Improve performance without trading away correctness, timing safety, or maintainability invisibly.

## Operating method

1. Establish the target and constraints before changing code. Identify the platform, core/clock, compiler and flags, memory map, RTOS or bare-metal environment, deadline/throughput target, RAM/flash/power budget, and reproducible workload. If important facts are unavailable, state assumptions and propose measurements rather than inventing hardware behavior.
2. Preserve a baseline. Record the exact build, input, measurement method, and relevant metrics. Prefer hardware counters, trace, GPIO timing, logic analyzers, RTOS trace, map files, stack high-water marks, and representative release builds over intuition or debugger-stepped timings.
3. Locate the dominant bottleneck. Separate compute, memory/cache, bus/peripheral, synchronization, scheduling, interrupt, and algorithmic costs. Optimize the critical path and common case; use Amdahl's law to reject work whose maximum possible gain is negligible.
4. Apply the highest-leverage safe change. Prefer reducing work, data movement, copies, contention, wakeups, and algorithmic complexity before instruction-level tuning. Make one conceptual change at a time when practical.
5. Verify on the target. Compare before/after distributions, not only averages. Check worst-case latency, jitter, deadlines, memory use, code size, stack, energy, numerical accuracy, functional tests, and behavior across supported build configurations.
6. Report evidence. State the bottleneck, change, mechanism, measured result, tradeoffs, test conditions, and remaining risk. Clearly distinguish measured facts, static-analysis findings, and hypotheses.

## Rules that always apply

- Correctness and hard real-time deadlines are constraints, not optimization variables. Preserve observable behavior unless the user authorizes a change.
- Never assume `volatile` provides atomicity, ordering between cores, or thread synchronization. Use the platform's atomics, barriers, critical sections, or RTOS primitives as appropriate.
- Treat interrupt service routines as bounded critical paths: do the minimum required work, acknowledge hardware correctly, and defer non-urgent processing. Do not shorten an ISR in a way that loses events or violates peripheral timing.
- Do not add caches, DMA, zero-copy, packed data, alignment attributes, intrinsics, assembly, or unsafe aliasing until their coherency, ownership, alignment, lifetime, and portability consequences are handled explicitly.
- Avoid undefined behavior and reliance on unspecified integer width, signed overflow, alignment, aliasing, or evaluation order. Use fixed-width types when hardware layout or arithmetic width matters.
- Evaluate optimization flags, LTO, section garbage collection, and architecture-specific options with the actual toolchain and target. Inspect warnings, map/disassembly where useful, and retain debug/release reproducibility.
- In real-time work, report WCET-relevant evidence or a defensible upper bound; an improved mean does not prove a deadline is safe.
- In low-power systems, optimize energy per completed task and wakeup behavior, not CPU cycles alone. A faster implementation can consume more energy, and a slower one can prevent sleep.
- Document target-specific assumptions close to target-specific code. Keep a clear portable path when the maintenance value justifies it.

## Choose the relevant review depth

- For a quick review, identify the top risks and the measurements needed to rank them. Do not present generic checklists as confirmed problems.
- For a full audit, code review, or refactor, read [references/audit-rule-catalog.md](references/audit-rule-catalog.md). Report applicable rule IDs; do not flag a conditional rule until its trigger is established.
- For C, C++, or Rust implementation work, also read [references/language-guidance.md](references/language-guidance.md). Apply only the section for the language in use.
- For system-level diagnosis and experiment design, read [references/optimization-rules.md](references/optimization-rules.md) and apply only the sections relevant to the target and symptoms.
- When source and build artifacts are available, inspect hot loops, call paths, linker map, section sizes, stack usage, compiler output, RTOS configuration, interrupt priorities, DMA/cache maintenance, and peripheral transfer patterns as relevant.

## Audit procedure

1. Inventory source language, target MCU/SoC, FPU/DSP/cache capabilities, memory regions, RTOS, compiler, optimization flags, linker script, and relevant peripheral paths.
2. Select applicable rules from the catalog. Mark each finding as `confirmed`, `likely`, or `needs measurement`; never infer missing hardware facts from source code alone.
3. Cite the exact rule ID and code location. Explain the observed pattern, why it matters on this target, and what evidence would confirm impact.
4. When the user asks for changes, provide or implement the smallest correctness-preserving refactor. Include overflow, alignment, ownership, concurrency, timing, and failure-path handling.
5. Rebuild and run available tests. Give a target-side verification plan when hardware measurements cannot be executed locally.

## Expected output

Prioritize findings by expected impact, confidence, effort, and risk. For each proposed change include:

- evidence or measurement that motivates it;
- expected mechanism and bounded benefit;
- correctness and real-time hazards;
- an implementation sketch or patch when requested;
- a target-side benchmark and regression check.

Use this compact finding shape when reviewing code:

```text
[severity] RULE-ID — short title
Location: file:line
Status: confirmed | likely | needs measurement
Evidence: observed code/build/hardware fact
Impact: affected metric and mechanism
Fix: concrete safe change
Verify: build/test/measurement and acceptance threshold
```

Reject folklore optimizations when the compiler already performs them, the target does not support the assumed feature, or measurement shows no meaningful gain.
