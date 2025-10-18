# 🧠 MindMentor – Version Control Best Practices

## 📘 Purpose

This document provides a clear and consistent **version control strategy** for the MindMentor Salesforce project. It ensures organized development, easy collaboration, and safe deployment practices as the project grows.

## 🧭 How to Use This Guide

* Follow the branching and commit conventions for all updates.
* Always work on feature branches — never directly on `main`.
* Use this document as your reference before creating a new branch, committing, or merging changes.

---

### 🧩 Branching Strategy

**1. Main Branch Rules**

* `main` (or `master`) always contains **production-ready code**.
* Never commit directly to `main`.
* Protect the branch in GitHub:

  * ✅ Require Pull Requests before merging.
  * ✅ Require at least one review approval.
  * ✅ Restrict who can push to it.
  * ✅ Include administrators.

---

**2. Branch Types**

| Branch Type | Purpose                               | Example                           |
| ----------- | ------------------------------------- | --------------------------------- |
| `feature/`  | New feature or enhancement            | `feature/ai-chat`                 |
| `bugfix/`   | Fixes for defects in existing code    | `bugfix/questionnaire-navigation` |
| `refactor/` | Code cleanup or structure improvement | `refactor/apex-controller`        |
| `docs/`     | Documentation updates                 | `docs/update-readme`              |
| `hotfix/`   | Critical production fix               | `hotfix/fix-deployment-error`     |

---

### 🧱 Workflow Summary

```bash
# Create a new branch
git checkout -b feature/<branch-name>

# Stage & commit changes
git add .
git commit -m "feat: add new LWC for mood tracking"

# Push to GitHub
git push --set-upstream origin feature/<branch-name>

# Create a Pull Request into main
# Review → Approve → Merge → Delete branch
```

---

### 🧠 Commit Message Convention

Follow the **Conventional Commits** style for consistency:

```
<type>: <short description>
```

**Types:**

* `feat` → New feature
* `fix` → Bug fix
* `refactor` → Code restructuring
* `docs` → Documentation change
* `style` → Formatting or style-only change
* `test` → Adding or updating tests
* `chore` → Build or maintenance task

**Examples:**

```
feat: add onboarding questionnaire component
fix: retain answers when navigating back
refactor: clean up Apex controller logging
docs: update README with project badges
```

---

### ⚙️ PR (Pull Request) Guidelines

* Create a **PR from your feature branch** into `main`.
* Use a **clear PR title** matching your main commit message.
* In the PR description:

  * Explain the purpose and the change.
  * Mention related issues if applicable.
* Get at least one review before merging (even if it’s your own self-review).
* Delete the branch after merging.

---

### 🧪 Code Quality & Review

* Run tests before committing (`sfdx force:source:deploy -p force-app` or sandbox deployment).
* Keep changes **atomic** — one logical change per PR.
* Avoid committing temporary debug logs or org-specific metadata.
* Use `.gitignore` to exclude:

  * `.sfdx/`
  * `.idea/`
  * `node_modules/`
  * `*.log`
  * Local config files

---

### 🧱 Optional (For Larger Teams)

If the team expands, adopt:

```
feature → develop → main
```

* `develop` becomes a staging branch for integration testing.
* Merge tested features into `develop`, then periodically release to `main`.

---

### ✅ Summary

* Protect `main` and avoid direct pushes.
* Use clear, consistent branch names and commit messages.
* Review PRs before merging.
* Keep commits small and meaningful.
* Sync often (`git pull origin main`) to avoid conflicts.