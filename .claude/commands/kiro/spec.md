---
allowed-tools: TodoWrite, TodoRead, Read, Write, MultiEdit, Bash(mkdir:*), Grep, Glob, Task
description: Start Specification-Driven Development workflow for enhancement or bug fix tasks
---

## Context

- Task description: $ARGUMENTS

## Your task

Execute the Specification-Driven Development workflow adapted for existing feature enhancements or bug fixes:

### 1. Initial Analysis

- Determine task type: bug fix, minor enhancement, or major enhancement
- For bug fixes: prioritize quick understanding and minimal changes
- For enhancements: assess scope and impact on existing code

### 2. Setup

- Determine next directory number in `docs/kiro_specs/`
- Create new themed directory: `docs/kiro_specs/XXX_theme_name/`
- Analyze existing codebase to understand current implementation

### 3. Workflow Selection

#### For Bug Fixes (simple issues):
- Skip directly to minimal requirements and task list
- Focus on understanding the bug and fix approach
- Create lightweight documentation

#### For Minor Enhancements (1-2 days work):
- Execute `/requirements` for focused analysis
- Simplified design focusing on integration points
- Compact task list

#### For Major Enhancements (3+ days work):
- Full workflow: requirements → design → tasks
- Comprehensive documentation
- Detailed impact analysis

### 4. Stage Execution

Based on task type, execute appropriate stages:
- Stage 1: Requirements analysis → `001_requirements.md`
- Stage 2: Design → `002_design.md`
- Stage 3: Task breakdown → `003_tasks.md`
- Stage 4: Summary → `004_summary.md`

**Get user approval at key decision points**

All documents should be created in the themed directory:
`docs/kiro_specs/XXX_theme_name/`

### 5. Implementation Readiness

Provide:
- Clear next steps for implementation
- Identified files to modify
- Testing approach
- Risk assessment

## Important Notes

- Adapt documentation depth to task complexity
- Prioritize understanding existing code
- Focus on minimal, safe changes
- Consider backward compatibility
- Include regression testing in planning
- For urgent fixes, streamline the process appropriately

think hard
