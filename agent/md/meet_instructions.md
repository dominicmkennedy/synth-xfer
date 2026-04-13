You synthesize KnownBits transfer functions in MLIR for operation <OP> (file: <OP_FILE>).

You are running in **meet mode**: your candidate will be combined with all previously accepted solutions via the meet operator. You do not need to cover every input — focus on inputs that existing solutions miss. A candidate that is sound globally and precise on a new subset of inputs will improve the collective solution set even if it is imprecise elsewhere.

**IMPORTANT — how the solution set works across rounds:**
- Each time you are invoked counts as one round. You are called repeatedly across multiple rounds to incrementally improve the solution set.
- The solution set is updated after each round: if your candidate improved the set, it is permanently added before the next round begins.
- Your previous round's solution is therefore already in the solution set. Submitting the same logic again will produce Updated == Previous (no improvement) because your candidate is already subsumed.
- You must design a genuinely different candidate each round, targeting the inputs that are STILL imprecise after all existing solutions are combined.

Use tools to fetch all materials; do not assume they are in this message:
- get_task_bundle(): concrete op MLIR
- get_program_templates(): output templates
- get_available_primitives(): allowed operators
- list_examples()/search_examples()/get_example(): reference implementations
- list_library_functions()/get_library_function(): retrieve available library functions
- get_existing_solutions(): view the MLIR of all solutions already in the solution set
- run_eval_improve(mlir): evaluate your candidate combined with existing solutions via meet; returns two lines — "Previous" (current solution set) and "Updated" (after adding your candidate)

Make liberal use of run_eval_improve — eval early and eval often. Do not wait until you think your solution is complete; use it to check partial ideas and intermediate candidates as well.

Workflow:
1. **Call get_existing_solutions() first — this is mandatory.** Read the MLIR of every existing solution carefully. Understand what logic each one encodes, and what input patterns it covers precisely. Do not skip this step.
2. Study the imprecise counterexamples shown (from the previous round's eval output, or from an early run_eval_improve call). Identify patterns in the inputs that the current solution set handles imprecisely — e.g., "when %0 is all-unknown and %1 has known high bits, the result should propagate %1's high bits."
3. Reason step-by-step about what logic would cover those specific imprecise cases, without reproducing logic already present in existing solutions.
4. If the library is not empty, call list_library_functions() early and check for functions that match or closely approximate what you need.
5. Write your candidate, then immediately call run_eval_improve to test it. Use the feedback to iterate.

**What to do when Updated == Previous (no improvement):**
- This means your candidate is already subsumed by the existing solution set — it adds no new precision.
- Do NOT return this candidate. You must try a different approach.
- Go back to the counterexamples and pick a specific imprecise case. Ask: what is the minimum logic needed to exactly match `best` for that case? Write a candidate specialized for that pattern but still globaly sound and test it.
- Keep iterating with different strategies until you find one that improves Exact % or lowers Dist.

Rules:
- You must call run_eval_improve with your MLIR before returning. If it returns a parse error, fix the MLIR and call again.
- If the Updated line shows Sound % < 100, you must fix the soundness issue and call eval again before returning.
- If the Updated line shows Sound % = 100 and Exact % is higher than the Previous line (or Dist is lower), you have made a valid improvement and may return.
- **CRITICAL: Do not return a candidate that does not improve Exact % (or lower Dist) compared to the Previous line. Updated == Previous means failure — try a different candidate.**

Output contract:
- Return ONLY MLIR func.func @kb_<op>. Do not wrap it in a module.
- One operation per line; SSA form; no explanations.
- Each line of MLIR must be exactly one operation from the allowed ops; do not write alias assignments like `%x = %y : !transfer.integer`
