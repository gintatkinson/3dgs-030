<!-- Copyright Gint Atkinson, gint.atkinson@gmail.com -->

# Rule: Role Boundary Lock & Phase-Based Tool Enforcement

**ALWAYS enforce:** The agent must enforce strict role boundaries between specification phases and implementation phases. Coordinators must never directly write codebase files or specifications, and subagents must only write within their designated domain boundaries.

## Hard constraints

- **Coordinator Direct Writing & Research Lock**: The coordinator agent is strictly forbidden from directly writing or modifying target functional specifications (Epics, Features, User Stories, Use Cases) or codebase source files, and is locked from directly conducting technology stack research (Step 1.5). All codebase write and update operations must be delegated to spawned implementer subagents, and all tech stack research must be delegated to a dedicated research subagent (role: `Codebase Researcher`).
- **Specification Phase Boundary**: Spec workers and specification subagents are strictly forbidden from reading, writing, or referencing implementation profiles, implementation plans, or target source code files. They must operate strictly within logical, functional, and platform-independent boundaries.
- **Implementation Phase Boundary**: Implementation subagents and micro-task implementers are strictly forbidden from generating or directly modifying upstream specification files (Epics, Features, User Stories, Use Cases) unless explicitly authorized via a synchronized backlog reconciliation task.
- **Strict Subagent Tool Locking**: Spawned subagents must only execute tools that fall within their explicit domain (e.g., spec subagents do not run build/test commands or modify code, and implementation subagents do not edit high-level specifications).
- **Subagent Cleanup**: The coordinator MUST immediately terminate any spawned subagents using the `manage_subagents` tool once the subagent's task is completed and the work is integrated. Subagents must never be left in an idle or dormant state.
- **Mandatory Full Compilation Build**: Before completing any implementation phase, a full compilation build of the entire application (e.g. `flutter build` or `npm run build` as specified by the platform profile) must be executed to ensure the system compiles without errors and is completely ready to run.


## Why

To prevent context window bloat, avoid memory leakage across phases, and maintain the integrity of the two-tier project constitution by ensuring specification remains purely functional and separate from implementation.
