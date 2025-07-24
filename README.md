# sanity_check 🌳

> "Structure isn't boring – it's your first line of clarity." — *You (probably during a cleanup)*

[![brew install](https://img.shields.io/badge/brew--install-success-green?logo=homebrew)](https://github.com/raymonepping/homebrew-sanity_check)
[![version](https://img.shields.io/badge/version-1.1.5-blue)](https://github.com/raymonepping/homebrew-sanity_check)

---

## 🧭 What Is This?

sanity_check is a Homebrew-installable, wizard-powered CLI.

---

## 🚀 Quickstart

```bash
brew tap 
brew install /sanity_check
sanity_check
```

---

Want to customize?

```bash
export FOLDER_TREE_HOME=/opt/homebrew/opt/..
```

---

## 📂 Project Structure

```
./
├── bin/
│   ├── CHANGELOG_sanity_check.md*
│   └── sanity_check*
├── Formula/
│   └── sanity-check-cli.rb
├── lib/
│   ├── check_bash.sh*
│   ├── check_compose.sh*
│   ├── check_docker.sh*
│   ├── check_markdown.sh*
│   ├── check_node.sh*
│   ├── check_python.sh*
│   ├── check_router.sh*
│   ├── check_terraform.sh*
│   ├── eslint.config.js*
│   ├── sanity_utils.sh*
│   └── tool_versions.sh*
├── tpl/
│   ├── readme_01_header.tpl
│   ├── readme_02_project.tpl
│   ├── readme_03_structure.tpl
│   ├── readme_04_body.tpl
│   ├── readme_05_quote.tpl
│   ├── readme_06_article.tpl
│   ├── readme_07_footer.tpl
│   └── report.tpl
├── .sanity.config.json
├── .version
├── reload_version.sh*
└── sanity_check.md

5 directories, 26 files
```

---

## 🧭 What Is This?

sanity-check-cli is a Homebrew-installable, wizard-powered CLI that automates code quality checks, linting, and basic sanity validation for your scripts and projects.
It’s built for anyone who wants a one-command way to keep their repos clean, compliant, and healthy.

Especially handy for:

- Developers and DevOps teams managing multi-language codebases
- Anyone preparing code for PRs, releases, or audits
- Automating code reviews and quality gates in CI/CD pipelines

---

## 🔑 Key Features

- Run sanity checks, linting, and formatting across Bash, Python, JavaScript, and Terraform files
- Instantly detect missing or outdated tools, format issues, or unsupported files
- Generate clean Markdown summaries (with stats and badges) for easy sharing or reporting
- Supports quick mode, quiet mode, and detailed reporting for CI or local use
- Modular, easily extendable, and designed for scripting/automation

---

### Run a full sanity check on your project

```bash
sanity_check --fix --lint --report
```

---

### ✨ Other CLI tooling available

✅ **brew-brain-cli**  
CLI toolkit to audit, document, and manage your Homebrew CLI arsenal with one meta-tool

✅ **bump-version-cli**  
CLI toolkit to bump semantic versions in Bash scripts and update changelogs

✅ **commit-gh-cli**  
CLI toolkit to commit, tag, and push changes to GitHub

✅ **folder-tree-cli**  
CLI toolkit to visualize folder structures with Markdown reports

✅ **radar-love-cli**  
CLI toolkit to simulate secret leaks and trigger GitHub PR scans

✅ **repository-audit-cli**  
CLI toolkit to audit Git repositories and folders, outputting Markdown/CSV/JSON reports

✅ **repository-backup-cli**  
CLI toolkit to back up GitHub repositories with tagging, ignore rules, and recovery

✅ **repository-export-cli**  
CLI toolkit to export, document, and manage your GitHub repositories from the CLI

✅ **self-doc-gen-cli**  
CLI toolkit for self-documenting CLI generation with Markdown templates and folder visualization

---

## 🧠 Philosophy

sanity_check 

> Some might say that sunshine follows thunder
> Go and tell it to the man who cannot shine

> Some might say that we should never ponder
> On our thoughts today ‘cos they hold sway over time

---

## 📘 Read the Full Medium.com article

📖 [Article](..) 

---

© 2025 Your Name  
🧠 Powered by self_docs.sh — 🌐 Works locally, CI/CD, and via Brew
