# Create Feature Specification
<!-- Template Version: 11 | ContextKit: 0.1.0 | Updated: 2025-09-26 -->

> [!WARNING]
> **👩‍💻 FOR DEVELOPERS**: Do not edit the content above the developer customization section - changes will be overwritten during ContextKit updates.
>
> For project-specific customizations, use the designated section at the bottom of this file.
>
> Found a bug or improvement for everyone? Please report it: https://github.com/FlineDev/ContextKit/issues

## Description
Initialize feature specification by validating setup, confirming feature naming, copying specification template, and executing template workflow with progress tracking.

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

### Phase 1: Setup Validation & Prerequisites

1. **Check Project Setup**
   - Use `Glob` tool to verify Context.md exists: `Glob . Context.md`
   - If Context.md missing:
     ```
     ❌ ContextKit not initialized in this project!

     Run /ctxk:proj:init first to setup ContextKit in this project.
     This command requires project context to detect tech stack and apply
     appropriate constitutional principles.
     ```
     → END (exit with error)

### Phase 2: Interactive Feature Definition & Naming

2. **Check Git Status**
   ```bash
   git status --porcelain || echo "⚠️ Git not available - continuing without version control"
   ```
   - If uncommitted changes exist:
     ```
     ⚠️  Uncommitted changes detected!

     You have uncommitted changes in your working directory.
     It's recommended to commit these changes before creating a new feature branch.

     Run: git add . && git commit -m "Your commit message"

     Continue anyway? (y/N):
     ```
     - Wait for user confirmation
     - If "N" or no response: EXIT (recommend committing first)
     - If "y": Continue with warning logged

3. **Get Feature or App Description from User**
   - Ask user for feature/app description using consistent format (see User Input Format section)
   - Wait for user input
   - **CRITICAL**: Store description exactly verbatim for specification Input field - do NOT summarize or paraphrase
   - Continue with description-based processing

4. **Discover Available Components and Ask User Which Are Affected**
   - Use `Bash` tool to check for multi-component structure:
     ```bash
     find . -maxdepth 3 -name ".git" -type d
     ```
   - Use `Bash` tool to check for submodules:
     ```bash
     ls -la .gitmodules 2>/dev/null || echo "No .gitmodules file found"
     ```
   - **If multiple components found**: List all discovered repositories/components and ask user:
     ```
     ═══════════════════════════════════════════════════
     ║ ❓ AFFECTED COMPONENTS SELECTION
     ═══════════════════════════════════════════════════
     ║
     ║ Which components will be affected by this feature?
     ║
     ║ Available components:
     ║ • Root workspace: [current directory name]
     ║ • [List discovered submodules/components]
     ║
     ║ Options:
     ║ • "root" - Root workspace repository only
     ║ • "all" - All discovered components
     ║ • Specific names - Space-separated (e.g., "root MyApp-iOS")
     ║
     ║ Response: Enter your selection
     ```
     - **WAIT for user response before proceeding**
     - Parse user response and store affected components list for later use
   - **If single repository**: Automatically set affected components to "root" only

5. **Generate Names**
   - Parse user description for key concepts
   - Create PascalCase name (e.g., "user authentication" → "UserAuthentication", "recipe app" → "RecipeApp")
   - Create kebab-case name for branch suffix (e.g., "user-authentication", "recipe-app")
   - Focus on user value, not implementation details

6. **Interactive Name Confirmation**
   - Display generated names to user for confirmation:
     ```
     ═══════════════════════════════════════════════════
     ║ ❓ FEATURE NAMING CONFIRMATION
     ═══════════════════════════════════════════════════
     ║
     ║ Generated names based on your description:
     ║ • Feature folder: [XXX]-[PascalCaseName] (XXX = next sequential number)
     ║ • Git branch: feature/[XXX]-[kebab-case-name]
     ║
     ║ Are these names correct? (y/N) or provide alternative description:
     ```
   - Wait for user confirmation or alternative description
   - If alternative provided: regenerate names and ask again
   - Continue only after user approval
   - Store confirmed names for subsequent steps

### Phase 3: Template Setup & Execution

7. **Generate Sequential Feature Number & Create Workspace**
   ```bash
   # Find next sequential number by counting existing feature directories
   NEXT_NUM=$(printf "%03d" $(($(ls -1d Context/Features/???-* 2>/dev/null | wc -l) + 1)))
   NUMBERED_FEATURE_NAME="${NEXT_NUM}-[ConfirmedFeatureName]"
   mkdir -p Context/Features/${NUMBERED_FEATURE_NAME}
   echo "✅ Created feature directory: Context/Features/${NUMBERED_FEATURE_NAME}"
   ```
   - Store the numbered directory name for use in subsequent steps and success message

8. **Copy Feature Template**
   ```bash
   cp ~/.ContextKit/Templates/Features/Spec.md Context/Features/[numbered-feature-directory]/Spec.md
   echo "✅ Copied specification template"
   ```

9. **Create Git Branch in Current Directory**
    ```bash
    git checkout -b feature/${NEXT_NUM}-[confirmed-kebab-case-name] || echo "⚠️ Git branch creation failed - continuing without branch"
    echo "✅ Created git branch: feature/${NEXT_NUM}-[confirmed-kebab-case-name]"
    ```

10. **Create Branches in Additional Components (AI Manual Step)**
    - **For each additional component selected by user in Step 5** (if any beyond "root"):
      - Use `Bash` tool to change to component directory and create branch:
        ```bash
        cd [component-directory] && git checkout -b feature/${NEXT_NUM}-[confirmed-kebab-case-name] && echo "✅ Created branch in [component-directory]" && cd - || echo "⚠️ Branch creation failed in [component-directory]"
        ```
      - Repeat for each selected component
    - **If user selected "all" in Step 5**: Execute above for every discovered component
    - **If user selected "root" only in Step 5**: Skip this step entirely

11. **Execute Specification Template**
    - Use `Read` tool to read the copied Spec.md: `Read Context/Features/[numbered-feature-directory]/Spec.md`
    - Follow the **system instructions** section (boxed area) step by step
    - The template contains specification generation logic and progress tracking
    - Use tools (`Read`, `Edit`) as directed by the template instructions
    - **Template execution**: The copied Spec.md handles all context reading, guidelines loading, constitutional validation, and content generation
    - **Progress tracking**: User can see checkboxes being completed in the copied file

12. **Extract and Resolve Clarification Points Interactively**
    - Use `Grep` tool to find clarification markers in final Spec.md: `Grep "🚨 \\[NEEDS CLARIFICATION:" [numbered-feature-directory]/Spec.md`
    - If clarification points found:
      - Parse each clarification point to extract the specific question and line context
      - **FOR EACH CLARIFICATION (one at a time)**:
        - Present the specific question to user using User Input Format:
          ```
          ═══════════════════════════════════════════════════
          ║ ❓ SPECIFICATION CLARIFICATION NEEDED
          ═══════════════════════════════════════════════════
          ║
          ║ [Specific extracted question from 🚨 [NEEDS CLARIFICATION: ...]]
          ║
          ║ Please provide your answer to resolve this specification requirement:
          ```
        - **WAIT for user response** (execution MUST stop until user answers)
        - Use `Edit` tool to replace the 🚨 [NEEDS CLARIFICATION: ...] marker with the user's answer
        - Continue to next clarification point only after current one is resolved
      - After all clarifications resolved: confirm all markers removed from Spec.md

13. **Display Success Message** (see Success Messages section)

## Error Conditions

- **"Context.md not found"** → User must run `/ctxk:proj:init` to initialize ContextKit
- **"Feature template not found"** → Ensure template files are available
- **"Directory creation failed"** → Check permissions and disk space
- **"Template copy failed"** → Check file permissions
- **"Template execution failed"** → Verify Spec.md template contains system instructions section

## Validation Gates

- Project Context.md exists (ContextKit project setup complete)?
- User confirmation obtained for feature naming?
- Feature workspace directory created successfully?
- Specification template copied to feature directory?
- Template system instructions executed successfully?
- System instructions section removed from final Spec.md?
- Clarification points resolved interactively one at a time?
- User informed to review and commit specification before proceeding?

## Integration Points

- **Global ContextKit**: Uses Templates/Features/Spec.md template for specification generation
- **Project Setup**: Requires Context.md created by /ctxk:proj:init for project detection and context
- **Template Execution**: Delegates all specification logic to copied Spec.md template (follows init-workspace pattern)
- **Development Workflow**: Creates foundation for /ctxk:plan:2-research-tech technical planning phase
- **Team Collaboration**: Creates committed specification for team review and stakeholder validation
- **Git Integration**: Establishes feature branch for systematic development workflow
- **Workspace Integration**: Template inherits coding standards and constitutional overrides from workspace Context.md

## Success Messages

### Specification Created Successfully
```
🎉 Specification created successfully!

📁 Feature: [numbered-feature-directory-name]
✅ Created: [numbered-feature-directory]/Spec.md
✅ Git branch: feature/[XXX]-[confirmed-kebab-case-name]
✅ Branch created in selected affected components
✅ Applied constitutional principles from project guidelines
✅ All mandatory sections completed with project-specific content

✅ All specification clarifications resolved interactively during generation

🔗 Next Steps:
1. Review [numbered-feature-directory]/Spec.md to ensure it matches your intent
2. [If clarifications needed:] Edit the spec file to answer marked questions
3. When satisfied with the spec: commit your changes with git
4. Run /ctxk:plan:2-research-tech to proceed with technical research and architecture planning

💡 Specification ready for your review and approval before technical planning!
```

════════════════════════════════════════════════════════════════════════════════
👩‍💻 DEVELOPER CUSTOMIZATIONS - EDITABLE SECTION
════════════════════════════════════════════════════════════════════════════════

This section is preserved during ContextKit migrations and updates.
Add project-specific instructions, examples, and overrides below.

## Custom Feature Examples
<!-- Add examples of feature/app descriptions that work well with your project type -->

## Naming Overrides
<!-- Document project-specific naming conventions or automatic name generation rules -->

## Validation Rules
<!-- Add extra specification validation steps or quality gates specific to your project -->