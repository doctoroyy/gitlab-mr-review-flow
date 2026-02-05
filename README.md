# GitLab MR Review Flow Skill

A standardized AI Agent skill that automates the workflow of **Retrieving Engineering Norms**, **Implementing Changes**, and **Creating/Reviewing Merge Requests** on GitLab.

This skill is designed to prevent "Bad Code" by injecting engineering norms (via QMD) directly into the agent's context *before* it writes code, and enforcing those norms during the AI Code Review step.

## Features

-   **🔍 Contextual Norm Retrieval**: Uses `qmd` (Quick Markdown Search) to find relevant engineering guidelines keywods before coding.
-   **🛡️ Policy Enforcement**: Explicitly checks the code against retrieved norms during the review phase.
-   **🦊 GitLab Integration**: Automates MR creation and inline code discussions using GitLab MCP (Model Context Protocol).
-   **💬 Inline Reviews**: Automatically posts line-level comments on specific violations in the diff.

## Prerequisites

-   **QMD**: Installed and configured with your engineering norms.
    -   `bun install -g https://github.com/tobi/qmd`
-   **GitLab MCP**: A Model Context Protocol server for GitLab.
    -   `npx -y @zereight/mcp-gitlab`
-   **GitLab Token**: configured in your environment.

## Usage

1.  Install the skill into your agent's skill library:
    ```bash
    npx skills add ./gitlab-mr-review-flow
    ```

2.  Trigger it in your agent session:
    > "Help me fix the login bug, but make sure to check our API guidelines first."

## Workflow

1.  **Search Norms**: Agent searches `qmd` for "API guidelines".
2.  **Plan & Code**: Agent implements the fix.
3.  **Push & MR**: Agent pushes code and opens a GitLab MR.
4.  **Review**: Agent reviews the diff against the "API guidelines".
5.  **Comment**: Agent posts inline comments if any norms are violated.
