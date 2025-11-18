# Begin Development with Context
<!-- Template Version: 10 | ContextKit: 0.1.0 | Updated: 2025-09-26 -->

> [!WARNING]
> **👩‍💻 FOR DEVELOPERS**: Do not edit the content above the developer customization section - changes will be overwritten during ContextKit updates.
>
> For project-specific customizations, use the designated section at the bottom of this file.
>
> Found a bug or improvement for everyone? Please report it: https://github.com/FlineDev/ContextKit/issues

## Description
Begin systematic development with context-aware setup, task analysis, and guided implementation initiation based on completed planning phases.

## User Input Format

```
═══════════════════════════════════════════════════
║ ❓ USER INPUT REQUIRED - [Topic]
═══════════════════════════════════════════════════
║
║ [Question and context]
║
║ [Response instruction]
```

## Execution Flow (main)

### Phase 1: Prerequisites & Feature Detection

1. **Check Project Setup**
   - Use `Glob` tool to verify Context.md exists: `Glob . Context.md`
   - If Context.md missing:
     ```
     ❌ ContextKit not initialized in this project!

     Run /ctxk:proj:init first to setup ContextKit in this project.
     This command requires project context for systematic development.
     ```
     → END (exit with error)

2. **Detect Current Feature from Git Branch**
   ```bash
   git branch --show-current || echo "⚠️ Not in git repository or no current branch"
   ```
   - If branch format is `feature/[prefix]-[kebab-case-name]`:
     - Extract full name from branch (e.g., `feature/001-visionos26-modernization` → `001-visionos26-modernization`)
     - Set FEATURE_NAME variable for directory matching
   - If not on feature branch:
     ```
     ⚠️ Not on a feature branch!

     Current branch: [current_branch_name]

     Expected: feature/[prefix]-[feature-name] branch from /ctxk:plan:1-spec

     Switch to feature branch or create one with /ctxk:plan:1-spec
     Continue anyway? (y/N):
     ```
     - Wait for user confirmation
     - If "N" or no response: EXIT
     - If "y": Ask user to specify feature name manually

3. **Validate Feature Planning Completion**
   - Use `Bash` tool to find numbered feature directory with flexible matching:
     ```bash
     # Try exact full name match first
     FEATURE_DIR=$(ls -d Context/Features/*/ | grep -i "[FEATURE_NAME]" | head -1)
     # If no match, try number-based matching (extract prefix number)
     if [[ -z "$FEATURE_DIR" ]]; then
       PREFIX=$(echo "[FEATURE_NAME]" | cut -d'-' -f1)
       FEATURE_DIR=$(ls -d Context/Features/${PREFIX}-*/ 2>/dev/null | head -1)
     fi
     ```
   - Expected format: `Context/Features/###-FeatureName/` (e.g., `001-VisionOS26Modernization/`)
   - Handles variations between prefixed kebab-case branch names and numbered PascalCase directory names
   - Use `Read` tool to check each required file exists and has content:
     ```bash
     ls -la [numbered-feature-directory]/Spec.md && echo "✅ Spec.md exists"
     ls -la [numbered-feature-directory]/Research.md && echo "✅ Research.md exists"
     ls -la [numbered-feature-directory]/Tech.md && echo "✅ Tech.md exists"
     ls -la [numbered-feature-directory]/Steps.md && echo "✅ Steps.md exists"
     ```
   - Use `Read` tool to verify Steps.md contains task breakdown (not empty placeholder)
   - If any file missing or empty:
     ```
     ❌ Feature planning incomplete!

     Missing or empty files detected:
     [List missing files]

     Complete the planning phases first:
     1. /ctxk:plan:1-spec - Business requirements (creates Spec.md)
     2. /ctxk:plan:2-research-tech - Technical research and architecture (creates Research.md and Tech.md)
     3. /ctxk:plan:3-steps - Implementation tasks (creates Steps.md)

     Cannot proceed with development until planning is complete.
     ```
     → END (exit with error)

### Phase 2: Context Loading & Environment Setup

4. **Load Development Context**
   - Use `Read` tool to read project Context.md: `Read Context.md`
   - **DEEP ANALYSIS REQUIRED**: Understand project type, architecture patterns, coding standards, and constitutional principles
   - Use `Bash` tool to check for workspace context:
     ```bash
     cd .. && find . -name "Context.md" -path "*/Context.md" | head -1 || echo "No workspace context found"
     ```
   - If workspace Context.md found: Use `Read` tool to load workspace-specific overrides
   - **CRITICAL**: This context forms the foundation for understanding how to execute all Steps.md tasks

5. **Verify Development Environment**
   ```bash
   git status --porcelain || echo "⚠️ Git not available"
   ```
   - If uncommitted changes exist:
     ```
     ⚠️ Uncommitted changes detected!

     You have uncommitted work that might be overwritten during development.
     Commit or stash changes before starting new development work.

     Continue anyway? (y/N):
     ```
     - Wait for user confirmation
     - If "N": EXIT (recommend committing first)
     - If "y": Continue with warning


### Phase 3: Steps.md-Driven Development Execution

6. **Load Complete Feature Context - DEEP UNDERSTANDING REQUIRED**
   - Use `Read` tool to read all planning files for complete understanding:
     ```
     Read [numbered-feature-directory]/Spec.md       # Business requirements and user stories
     Read [numbered-feature-directory]/Research.md   # Technical research findings and decisions
     Read [numbered-feature-directory]/Tech.md       # Technical architecture and decisions
     Read [numbered-feature-directory]/Steps.md      # PRIMARY TASK LIST - Implementation breakdown
     ```
   - **CRITICAL - DEEP ANALYSIS REQUIRED**:
     - **From Spec.md**: Fully understand feature purpose, ALL user stories, ALL acceptance criteria, user experience requirements
     - **From Research.md**: Completely understand technology research findings, API constraints, integration patterns, external dependencies
     - **From Tech.md**: Thoroughly understand architecture decisions, technology choices, ALL constraints, design patterns
     - **From Steps.md**: **THIS IS THE PRIMARY TASK LIST** - Parse ALL S001-S999 numbered tasks, [P] parallel markers, dependencies, file paths, acceptance criteria
   - **Parse Steps.md as Primary Task List**:
     - Identify ALL tasks with their exact S### numbers
     - Parse completion status (checked/unchecked boxes) for each task
     - Extract dependencies for each task
     - Note which tasks have [P] parallel markers
     - Extract file paths and specific requirements for each task

7. **Execute Steps.md Tasks Sequentially - NO SHORTCUTS ALLOWED**
   - **PRIMARY OBJECTIVE**: Follow Steps.md step-by-step as the definitive task list
   - Find the **first uncompleted task** in S001, S002, S003... sequence from Steps.md
   - **ABSOLUTE REQUIREMENT**: Do NOT skip tasks, do NOT choose "easier" tasks, do NOT take shortcuts
   - **ABSOLUTE REQUIREMENT**: Do NOT assume tasks are complete - follow the plan exactly
   - Check dependencies are satisfied:
     - Extract "Dependencies: S001, S002" from task description in Steps.md
     - Verify all dependency tasks are completed (checked boxes in Steps.md)
     - If dependencies not met: Display which specific tasks need completion first
   - **CRITICAL RULE**: Steps.md is the master plan - follow it religiously, never deviate
   - **NEVER SPEED UP**: Do NOT execute multiple steps at once - handle ONE task at a time
   - **NEVER ASSUME**: Do NOT assume tasks are simple or can be batched - follow each step individually
   - **NEVER AUTOMATE THE PROCESS**: Each step requires individual attention and execution
   - If no valid next task available: Display completion status and guide user to next phase
   - **Steps.md drives everything** - it's not just a reference, it's the execution plan

8. **Execute Current Task from Steps.md - Follow the Plan Exactly**

   **CRITICAL**: The current task comes directly from Steps.md - execute exactly as specified, no shortcuts

   **For MANUAL REQUIRED Tasks** (marked with ⚠️ MANUAL REQUIRED in Steps.md):

   **CRITICAL**: Always use the standardized user input box format below - never use custom formatting:

   ```
   ═══════════════════════════════════════════════════
   ║ 👤 MANUAL TASK REQUIRED - [TaskNumber from Steps.md]
   ═══════════════════════════════════════════════════
   ║
   ║ 📋 TASK FROM STEPS.md: [Exact task description from Steps.md]
   ║ 📂 Files: [Exact file paths from Steps.md]
   ║ 🛠️ Manual steps required:
   ║ [Extract detailed manual instructions from Steps.md task notes]
   ║
   ║ 📝 FULL CONTEXT (from planning files):
   ║ • Feature purpose: [Complete understanding from Spec.md]
   ║ • Technical approach: [Complete understanding from Tech.md]
   ║ • Why this task: [Reason from Steps.md context]
   ║ • Current progress: [completed_tasks]/[total_tasks] tasks done in Steps.md
   ║
   ║ Please complete this manual task exactly as specified, then return here.
   ║
   ║ Options:
   ║ ✅ 'done' - I completed the manual task (will mark as ✅ in Steps.md)
   ║ ⏭️  'skip' - Skip this task for now (breaks planned sequence)
   ║ ❓ 'help' - Show more detailed instructions from Steps.md
   ║ 🔙 'back' - Return to task selection
   ║
   ║ Status:
   ```

   **For AUTOMATED Tasks** (no manual markers in Steps.md):

   **CRITICAL**: Execute exactly as specified in Steps.md - no shortcuts or assumptions:
   ```
   ═══════════════════════════════════════════════════
   ║ 🚀 AUTOMATED TASK - [TaskNumber from Steps.md]
   ═══════════════════════════════════════════════════
   ║
   ║ 📋 TASK FROM STEPS.md: [Exact task description from Steps.md]
   ║ 📂 Files to modify: [Exact file paths from Steps.md]
   ║ 🎯 Acceptance criteria: [Criteria from Steps.md]
   ║ 🔗 Dependencies: [Dependencies listed in Steps.md]
   ║
   ║ 📝 FULL CONTEXT FOR IMPLEMENTATION:
   ║ • Feature specification: [Complete understanding from Spec.md]
   ║ • Technical architecture: [Complete understanding from Tech.md]
   ║ • Research findings: [Complete understanding from Research.md]
   ║ • Current progress: [completed_tasks]/[total_tasks] tasks done in Steps.md
   ║
   ║ 🔧 IMPLEMENTATION APPROACH:
   ║ [How this will be implemented based on complete context understanding]
   ║
   ║ Ready to execute this Steps.md task? (Y/n):
   ```

   **IMPORTANT**:
   - Task details come DIRECTLY from Steps.md - never modify or interpret
   - Use complete context from Spec.md, Tech.md, Research.md for implementation
   - Do NOT skip steps or take shortcuts - follow Steps.md exactly
   - Wait for user confirmation before proceeding
   - If "n": Ask for clarification but emphasize Steps.md must be followed

### Phase 4: Task Execution with Steps.md as Central Progress Tracker

9. **Execute Task Implementation with Complete Context**
   - **For Manual Tasks**: User delegation complete, immediately mark as done in Steps.md
   - **For Automated Tasks**: Implement using complete context understanding:
     - **Use ALL context from planning files**: Apply complete understanding from Spec.md, Tech.md, Research.md
     - Extract detailed task information from Steps.md: file paths, acceptance criteria, dependencies
     - Use `Read` tool to examine target files if they exist
     - Use `Glob` tool to discover available guidelines: `Glob Context/Guidelines *.md`
     - For each found guideline file, use `Read` tool to load and apply content
     - Apply constitutional principles relevant to task type (UI, models, services, etc.)
     - **Execute exactly as planned in Steps.md** - no shortcuts, no assumptions
     - Ensure implementation meets all criteria specified in Steps.md

10. **Update Steps.md Progress Tracking - CENTRAL TO WORKFLOW**
    - **IMMEDIATELY after task completion**: Use `Edit` tool to mark completed task as checked in Steps.md:
      ```
      OLD: - [ ] **S001** [task description]
      NEW: - [x] **S001** [task description]
      ```
    - **Add completion timestamp**: Update task notes with completion time
    - **This is critical**: Steps.md serves as the definitive progress tracker
    - Verify the checkbox update was successful before proceeding

11. **Continue Sequential Execution - No Exit Until All Done**
    - **IMMEDIATELY after updating Steps.md**: Check for next sequential task
    - **Do NOT exit** - continue with next task in sequence according to Steps.md
    - Display progress update based on Steps.md status:
    ```
    ✅ Task [TaskNumber] completed and marked in Steps.md!

    📊 Progress: [completed_tasks+1]/[total_tasks] tasks done per Steps.md
    🔄 Loading next task from Steps.md...
    ```
    - Return to Phase 3, Step 7 to determine next task from Steps.md
    - **Only exit when**:
      - ALL Steps.md tasks completed (all checkboxes checked)
      - Dependency blocking prevents any task execution
      - User explicitly requests to stop
    - **The goal**: Complete the entire Steps.md task list systematically

12. **Quality Assurance Integration with Targeted Context**
    - **After completing any step or significant changes**: Run systematic quality validation with targeted file analysis
    - **Context Passing**: Provide recently modified files and line ranges to focus agent analysis

    **Example Agent Calls**:
    ```
    Use Task tool with build-project:
    "Execute project build and report status."

    <!-- TODO: check-* agents currently disabled (untested, need rework to read-only)
    Use Task tool with check-modern-code:
    "Check for outdated patterns in recent code.

    FILES:
    - Sources/Services/AuthService.swift:23-89,145-201
    - Sources/Models/User.swift:45-78
    - Sources/Views/LoginView.swift

    Focus analysis on these specific areas only."

    Use Task tool with check-accessibility:
    "Check accessibility issues in recent UI changes.

    FILES:
    - Sources/Views/ProfileView.swift:34-156
    - Sources/Components/CustomButton.swift

    Focus analysis on these specific areas only."
    -->
    ```

    - **Execution Order** (run sequentially, stop and fix if any fail):
      1. `build-project` - Verify compilation (project-wide)
      <!-- TODO: check-* agents incomplete - need rework to read-only reporting
      2. `check-modern-code` - Modernize APIs (recent files only) [INCOMPLETE]
      3. `check-error-handling` - Validate error patterns (recent files only) [INCOMPLETE]
      4. `check-accessibility` - Check UI accessibility (recent UI files only) [INCOMPLETE]
      5. `check-localization` - Verify localization (recent UI files only) [INCOMPLETE]
      6. `check-code-debt` - Clean up artifacts (recent files only) [INCOMPLETE]
      -->

    - **Optional Testing Agents** (use when working on tests or before releases):
      - `run-specific-test` - When debugging a failing test or validating new test code
      - `run-test-suite` - Before package releases or after significant changes to verify full test coverage

    - **File Context Rules**:
      - Include entire function ranges for significant modifications (60%+ changed)
      - Provide full file paths for new or completely rewritten files
      - Merge nearby line ranges (e.g., 23-25,27-29 → 23-29)
      - Focus agents only on recently modified code, not entire codebase

    - **When to run**: After completing views, features, models with user-facing content, or any substantial code changes
    - **If agents fail**: Focus on fixing the specific issue before continuing, then re-run the failed agent to verify the fix

## Error Conditions

- **"Context.md not found"** → User must run `/ctxk:proj:init` to initialize ContextKit
- **"Not on feature branch"** → Create feature branch with `/ctxk:plan:1-spec` or switch to existing one
- **"Planning phases incomplete"** → Complete `/ctxk:plan:1-spec` (creates Spec.md), `/ctxk:plan:2-research-tech` (creates Research.md + Tech.md), `/ctxk:plan:3-steps` (creates Steps.md) sequence
- **"No feature directory found"** → Feature name detection failed, verify branch name format
- **"Steps.md empty"** → Run `/ctxk:plan:3-steps` to create implementation breakdown
- **"Build environment broken"** → Resolve dependency issues before starting development
- **"All tasks complete"** → No pending work, consider `/ctxk:impl:commit-changes` or new feature

## Validation Gates

**Prerequisites:**
- ContextKit project setup complete?
- Git repository with feature branch active?
- All planning phases completed (Spec.md, Research.md, Tech.md, Steps.md)?
- Development environment verified and functional?

**Context Loading:**
- Project and workspace context loaded successfully?
- Constitutional principles identified for project type?
- Development patterns and standards accessible?

**Task Selection:**
- Implementation plan parsed successfully?
- Valid task selected with clear acceptance criteria?
- Task dependencies satisfied and ready for execution?

**Development Ready:**
- Quality assurance hooks enabled?
- Relevant guidelines referenced for task type?
- Development guidance displayed and ready to proceed?
- User confirmation received for selected task and approach?

## Integration Points

- **Planning Commands**: Requires completed `/ctxk:plan:1-spec` (Spec.md), `/ctxk:plan:2-research-tech` (Research.md + Tech.md), `/ctxk:plan:3-steps` (Steps.md) workflow
- **Project Setup**: Uses Context.md from `/ctxk:proj:init` for project type detection and standards
- **Quality Agents**: Integrates with `build-project`, `run-test-*` agents (ready). `/run check-*` agents incomplete - pending rework
- **Workspace Context**: Inherits client-specific requirements from workspace-level Context.md files
- **Git Workflow**: Works within feature branch structure established by planning commands
- **Development Hooks**: Enables PostToolUse formatting and SessionStart version checking
- **Task Tracking**: Updates Steps.md progress tracking for systematic development workflow

## Success Messages

### Development Session Started
```
🚀 Development session started for [FeatureName]

📋 Current Task: [TaskNumber] [TaskDescription]
📂 Files to modify: [file_paths]
📖 Guidelines: [List of available guidelines from Context/Guidelines/]

⚡ Quality validation runs automatically after substantial changes:
   build-project → [check-* agents incomplete pending rework]

💡 Ready to implement!
```

### All Tasks Complete
```
🎉 Feature [FeatureName] implementation complete!

🔗 Next steps:
   1. Quality validation will run automatically
   2. Test functionality manually
   3. Commit: /ctxk:impl:commit-changes
   4. Release: /ctxk:impl:release-app [version]
```

════════════════════════════════════════════════════════════════════════════════
👩‍💻 DEVELOPER CUSTOMIZATIONS - EDITABLE SECTION
════════════════════════════════════════════════════════════════════════════════

This section is preserved during ContextKit migrations and updates.
Add project-specific instructions, examples, and overrides below.

## Custom Task Selection Logic
<!-- Override automatic task selection with project-specific priority rules -->

## Additional Environment Checks
<!-- Add project-specific dependency or tool verification steps -->

## Custom Constitutional Reminders
<!-- Add project-specific architectural principles or coding standards -->