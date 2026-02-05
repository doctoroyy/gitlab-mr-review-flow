import os
import subprocess
import json
import sys

# Requirements:
# pip install requests openai (Configured in Dockerfile)
# Environment:
# GITLAB_PERSONAL_ACCESS_TOKEN
# OPENAI_API_KEY (Optional, for LLM check)
# CI_MERGE_REQUEST_IID (Provided by GitLab CI)
# CI_PROJECT_DIR

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}")
        print(e.stderr)
        return ""

def get_mr_diff():
    # In a real scenario, fetch via GitLab API using CI_MERGE_REQUEST_IID
    # For this scaffold, we assume we are inside the git repo checked out by Runner
    # and we want to diff origin/master...HEAD
    # Note: GitLab CI checkouts can be detached.
    return run_command("git diff origin/main...HEAD")

def qmd_search(query):
    # Assumes qmd is installed and norms are indexed
    # We might need to re-index or assume persistent volume
    # For CI, we can "add" the local docs folder on the fly
    run_command("qmd collection add ./docs --name ci-notes --mask '**/*.md' || true")
    run_command("qmd embed || true")
    return run_command(f"qmd search '{query}'")

def llm_review(diff, norms):
    # MOCK implementation for the scaffold
    # Real implementation would call OpenAI/Gemini API
    print("🤖 Analyzing diff against norms...")
    violations = []
    
    # Simple heuristic for demo purposes (mimics the Agent's finding)
    if "print(" in diff and "No Print Statements" in norms:
        # Find line number (rough logic)
        for i, line in enumerate(diff.split('\n')):
            if "+ " in line and "print(" in line:
                # Need to map back to file and line number
                # This is complex parsing logic, simplified here:
                violations.append({
                    "file": "bad_code.py", # Detected file
                    "line": 1, # Detected line
                    "msg": "❌ **Norm Violation**: Production code must not contain `print()`."
                })
    return violations

def post_comment(file, line, msg):
    script_path = "./scripts/post_comment.sh"
    cmd = f"{script_path} '{file}' {line} '{msg}'"
    run_command(cmd)

def main():
    print("🚀 Auto-Review Bot Starting...")
    
    # 1. Search Norms (Generic Search or Keyword extraction)
    norms = qmd_search("coding standards")
    print(f"📚 Loaded Norms Context: {len(norms)} chars")
    
    # 2. Get Diff
    diff = get_mr_diff()
    print(f"📝 Diff Size: {len(diff)} chars")
    
    # 3. Analyze
    violations = llm_review(diff, norms)
    
    # 4. Post Comments
    if violations:
        print(f"⚠️ Found {len(violations)} violations.")
        for v in violations:
            post_comment(v['file'], v['line'], v['msg'])
    else:
        print("✅ No violations found.")

if __name__ == "__main__":
    main()
