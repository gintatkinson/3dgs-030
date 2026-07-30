<!-- Copyright Gint Atkinson, gint.atkinson@gmail.com -->

---
name: spec-orchestrator
description: "Orchestrates end-to-end multi-agent protocol specification engineering. Use when you need to transform a protocol standard (IETF, 3GPP, IEEE, CAMARA) into a complete GitHub-tracked Agile backlog of Epics, Features, User Stories, and Use Cases."
compatibility: "Requires gh CLI and git. Works with Claude Code, Gemini CLI, Cursor, Copilot, Cascade."
metadata:
  title: "Autonomous Specification Orchestrator (Master Command)"
  category: orchestration
  risk: medium
  source: custom
  version: "2.0"
---

# Autonomous Specification Orchestrator (Master Command)

This skill enables you to act as the **Master Orchestrator Agent**. You are responsible for executing an end-to-end "Digital Engineering Pipeline" that systematically transforms a protocol standard (e.g., IETF, 3GPP, IEEE, CAMARA) into a deterministic GitHub repository matrix using UML OOA/OOD methodologies.

You will accomplish this by coordinating the sequential execution of three specialized Worker skills.

> [!NOTE]
> This orchestrator handles **specification generation** (Phases 1-5). For **feature implementation**, use the separate `feature-driven-implementation` skill which provides subagent-driven TDD execution discipline.

## Error Recovery
If any phase fails (worker error, GitHub API failure, validation gate failure):
1. **Do not proceed** to the next phase.
2. **Log the exact error** (stderr, exit code, GitHub API response).
3. **Attempt remediation:** Re-run the failed step once.
4. **Automated Upstream Reporting**: If the step fails again and you suspect the failure is due to a bug or limitation in the pipeline tooling (such as linter or reconciler scripts), you MUST automatically file a GitHub issue to the upstream repository before halting:
   ```bash
   gh issue create --repo gintatkinson/digital-pipeline-repo --title "Tooling Bug: [Command] failed" --body-file [payload_path] --label "bug"
   ```
5. Escalate to the user with the full error context and the link to the created upstream issue.
6. **Never skip a validation gate.** If a gate cannot be satisfied, the pipeline is halted until manually resolved.

## Pre-Flight Git Repository Verification
Before performing any orchestration steps, the agent MUST run `git ls-files` on:
1. `.pipeline/constitution.md`
2. `skills/`
3. `rules/`
4. `scripts/`

If any of these verification checks fail (i.e. the files are untracked or missing), the agent MUST halt and instruct the operator to add, commit, and push them first:
```bash
git add .pipeline/ skills/ rules/ scripts/ app_flutter/
git commit -m "chore: bootstrap pipeline infrastructure"
git push
```

## Pre-Flight Checklist
Before beginning orchestration, verify you have:
1. The target specification identifier (e.g., RFC 8345, 3GPP TS 23.501).
2. The path(s) to the associated structural schemas (e.g., `*.yang`, `*.yaml`, `*.proto`).
3. *(Optional)* A project constitution at `.pipeline/constitution.md`. If present, read it and apply platform/domain constraints to all worker dispatches.

## Item-Level Subagent Context Isolation

To prevent context drift, contamination, and confirmation bias, **every individual specification item (Epic, Feature, User Story, and Use Case) MUST be processed by a new, fresh subagent with an isolated context.**

Additionally:
- **Mandatory Subagent Dispatch for Specification Phases**: The Master Orchestrator (Coordinator) MUST dispatch Phase Worker subagents (TypeName: `self`) for Phase 1, Phase 2, and Phase 3:
  * Phase 1: `Structural Spec Worker`
  * Phase 2: `Behavioral Spec Worker`
  * Phase 3: `System Interaction Spec Worker`
- **Coordinator Direct Writing Lock**: The Coordinator is strictly forbidden from directly performing schema parsing, drafting, or issue uploads in its main conversation context. All such operations must be delegated to the Worker subagents.

When executing a phase, the worker agent must follow this lifecycle:
1. **Decomposition**: Parse the input schema or specification text to identify the distinct list of items to be created.
2. **Subagent Dispatch**: For each identified item, invoke a fresh subagent with its own clean context. Pass only:
   - The relevant schema node(s) or specification paragraph(s) for that item.
   - The specific skill instructions (e.g., Feature, User Story, or Use Case template guidelines).
   - Core project rules and the constitution.
   - Do **NOT** pass the history of other items generated in the same run.
3. **Drafting**: The subagent drafts only the target markdown file for that single item.
4. **Registration**: The worker agent aggregates the outputs, links them, and registers them sequentially in the issue tracker. All spec issues (Epics, Features, User Stories, Use Cases) MUST be created with their full body contents (via `--body-file <local-md-file>` and immediate post-creation verification) during Phases 1, 2, and 3. An immediate post-creation verification check must be run (e.g., `gh issue view <ID> --json body`) to ensure the tracker body is not a stub and is fully populated at the time of creation.

## Parallel Dispatch Convention

Phases marked with **`[P]`** may be dispatched in parallel when:
- The runtime supports parallel subagent dispatch (Claude Code, Gemini CLI)
- There are no data dependencies between the parallel phases
- Each parallel worker operates on independent schema modules

Phases NOT marked `[P]` are strictly sequential — the validation gate of phase N must pass before phase N+1 begins.

> **Single-agent runtimes (Cascade/Windsurf/Devin):** Ignore `[P]` markers and execute all phases sequentially. Even in single-agent environments, item-level subagent isolation must be simulated by manually resetting/clearing prior context (e.g., providing explicit instructions to ignore previous items and focus only on the current target's schema/text) for each item drafted.

## Phase 0: Pre-Flight / Pre-computation
1. **YANG Compilation (conditional)**: If `.yang` files are present in the schema directory, run the YANG-to-LUI compiler to generate the UI layout:
   ```bash
   python3 scripts/compile_yang.py --input schema/model.yang --output app_flutter/assets/logical-layout.json
   ```
   The compiler extracts hierarchy from `container`/`list` nesting, attributes from `leaf` definitions with type/range/enum constraints, and merges them into `logical-layout.json`. Detailed mapping reference is in `docs/operations/yang-compiler-guide.md`.

## Phase 1: Structural Extraction (Worker A)
1. **Trigger / Dispatch**: The Coordinator MUST invoke a fresh subagent (TypeName: `self`, Role: `Structural Spec Worker`) with the `schema-specification-engineering` skill and the path to the target structural schema files, appending the keyword `PROCEED` to authorize execution.
2. **Execution**: The `Structural Spec Worker` subagent parses the schema and identifies all Epics and Features. It dispatches a fresh context-isolated subagent for each Feature/Epic to draft its specification. Before committing, pushing, or creating issues, it MUST execute the local validation check (`./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only --allow-missing-specs`) and fix all reported errors until the linter passes with exit code 0. It registers Features first using `gh issue create --title "<Extract_Title_From_YAML_Metadata>" --body-file <local-md-file>`, runs an immediate verification check (`gh issue view <ID> --json body`) to ensure the tracker is fully populated, then injects their Issue IDs into the Epic checklists, registers Epics using `gh issue create --title "<Extract_Title_From_YAML_Metadata>" --body-file <local-md-file>`, verifies their bodies immediately, and commits/pushes the changes.
3. **Wait & Verify**: The Coordinator waits for the subagent to report completion, reads its final report, and:
   a. Query the `git diff` to identify the generated file paths.
   b. Run a file read check (`view_file`) on a random sample (at least 1-2 files) of the newly generated files to verify formatting compliance (such as BDD syntax, UML diagrams format).
   c. Run the linter locally over the newly added files to double-check that the validation gate is fully satisfied:
      ```bash
      ./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only
      ```
4. **Validation Gate**: You MUST wait for the Phase 1 execution to fully complete. The agent must successfully create all Feature issues FIRST, capture their IDs, inject them into the Epic markdown, and then create the Epic issue. Query GitHub (`gh issue list --limit 1000 --state all --json number,title,state,labels`) to verify the new Epics and Features exist and are properly interlinked. Do not proceed to Phase 2 until the structural foundation is verified.

## Phase 2 `[P]`: Behavioral Extraction - User Stories (Worker B)
1. **Trigger / Dispatch**: The Coordinator MUST invoke a fresh subagent (TypeName: `self`, Role: `Behavioral Spec Worker`) with the `spec-user-story-engineering` skill and the text/path of the target specification document, appending the keyword `PROCEED` to authorize execution.
2. **Execution**: The `Behavioral Spec Worker` subagent parses operational scenarios and identifies required User Stories (including calculations and transitions). It dispatches a fresh context-isolated subagent for each User Story to write its specification file. Before committing, pushing, or creating issues, it MUST execute the local validation check (`./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only --allow-missing-specs`) and fix all reported errors until the linter passes with exit code 0. The subagent registers the User Stories in the tracker using `gh issue create --title "<Extract_Title_From_YAML_Metadata>" --body-file <local-md-file>`, runs immediate verification check (`gh issue view <ID> --json body`) to ensure their bodies are fully populated in the tracker, and commits/pushes the changes.
3. **Wait & Verify**: The Coordinator waits for the subagent to report completion, reads its final report, and:
   a. Query the `git diff` to identify the generated file paths.
   b. Run a file read check (`view_file`) on a random sample (at least 1-2 files) of the newly generated files to verify formatting compliance (such as BDD syntax, UML diagrams format).
   c. Run the linter locally over the newly added files to double-check that the validation gate is fully satisfied:
      ```bash
      ./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only
      ```
4. **Validation Gate**: Verify that the `user-story` issues have been created in GitHub and that their tasklists successfully render the intersecting `#IssueID`s generated during Phase 1.

## Phase 3 `[P]`: System Interaction Extraction - UML Use Cases (Worker C)
1. **Trigger / Dispatch**: The Coordinator MUST invoke a fresh subagent (TypeName: `self`, Role: `System Interaction Spec Worker`) with the `spec-usecase-engineering` skill and the text/path of the target specification document, appending the keyword `PROCEED` to authorize execution.
2. **Execution**: The `System Interaction Spec Worker` subagent identifies required System Use Cases and dispatches a fresh context-isolated subagent for each Use Case. Before committing, pushing, or creating issues, it MUST execute the local validation check (`./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only --allow-missing-specs`) and fix all reported errors until the linter passes with exit code 0. The subagent registers the completed Use Cases in the tracker using `gh issue create --title "<Extract_Title_From_YAML_Metadata>" --body-file <local-md-file>`, runs immediate verification check (`gh issue view <ID> --json body`) to ensure their bodies are fully populated in the tracker, cross-links them to stories and features, and commits/pushes the changes.
3. **Wait & Verify**: The Coordinator waits for the subagent to report completion, reads its final report, and:
   a. Query the `git diff` to identify the generated file paths.
   b. Run a file read check (`view_file`) on a random sample (at least 1-2 files) of the newly generated files to verify formatting compliance (such as BDD syntax, UML diagrams format).
   c. Run the linter locally over the newly added files to double-check that the validation gate is fully satisfied:
      ```bash
      ./skills/spec-orchestrator/scripts/verify_model_coverage.py --spec-only
      ```
4. **Validation Gate**: Verify that the `use-case` issues have been created in GitHub and that the Realization Matrix successfully links back to User Stories and Features.

> **`[P]` Note:** Phases 2 and 3 are marked parallel-capable because Worker C queries GitHub for User Story Issue IDs (created by Worker B) via `gh issue list`. If both are dispatched simultaneously, Worker C will find the User Story issues as soon as Worker B creates them. On single-agent runtimes, execute Phase 2 first, then Phase 3.

## Phase 4: Reconciliation & Automated Verification (Worker D & Coverage Check)
1. **Trigger Backlog Reconciliation**: Run the automated backlog reconciliation script:
   ```bash
   ./skills/spec-orchestrator/scripts/reconcile_backlog.py
   ```
2. **Trigger Model Coverage & UML Conformance Verification**: Run the automated UML compliance and coverage linter tool:
   ```bash
   ./skills/spec-orchestrator/scripts/verify_model_coverage.py [schema_dir] [features_dir] --spec-only
   ```
   If `schema_dir` and `features_dir` are omitted, the script defaults to `$SCHEMA_DIR` / `$FEATURES_DIR` environment variables, or `<repo_root>/schema` (or the configured schema directory) and `<repo_root>/docs/features`.

   > [!WARNING]
   > The `--spec-only` flag is mandatory during specification phases to prevent the verifier from checking implementation coverage (i.e. verifying that features are implemented in codebase source directories such as `app_flutter/` or `web_react/`).
3. **Execution**: 
   - The backlog script parses frontmatter using PyYAML to prevent block erasure, performs dependency issue hallucination checks, queries GitHub issues, syncs checkbox states in local markdown, and automatically closes completed Epics, User Stories, and Use Cases.
     > [!IMPORTANT]
     > **Canonical Source of Truth & Phase 4 Scope**: The tracker is the canonical source of truth and must remain fully populated at all times during the specification lifecycle. Phase 4 backlog reconciliation is a secondary verification gate (syncing checkbox lists, cross-links, and closing completed items), rather than a deferred publisher of primary issue bodies. Do not defer the publishing of primary issue bodies to Phase 4.
   - The coverage linter parses raw schemas, builds class/sequence/use-case diagram symbol tables from Mermaid blocks, verifies 100% schema coverage within those class diagrams, and validates OMG UML 2.5.1 metamodel conformance and cross-view semantic rules (isolated classes, standard primitives, lifeline aliases, open return arrow assignments, system boundary use cases, undirected actor links, correct extend arrow directionality, etc.).
4. **Validation Gate**: Both scripts must execute successfully with exit code 0. Ensure that all completed tasks have been correctly updated/synced to GitHub, all UML diagrams are validated as fully compliant, and the overall model coverage is verified at exactly 100%.

## Phase 5: Final Reporting
1. Summarize the end-to-end pipeline execution for the user.
2. Provide direct links to the generated Epics, Features, User Stories, and Use Case tracking matrices.
3. Declare the protocol module "Fully Specification-Engineered and Verified."

