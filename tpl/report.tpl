---
## 🕒 Report: {{TIMESTAMP}}

{{#PROCESSED_FILES}}
### 📂 Processed Files
{{#files}}
- `{{.}}`
{{/files}}
{{/PROCESSED_FILES}}

{{#MISSING_TOOLS}}
### ⚠️ Missing Tools
{{#tools}}
- {{.}}
{{/tools}}
{{/MISSING_TOOLS}}

{{#LINT_ISSUES}}
### ❗ Lint Issues Found
{{#issues}}
- `{{.}}`
{{/issues}}
{{/LINT_ISSUES}}

{{^LINT_ISSUES}}
### ✅ No lint issues found.
{{/LINT_ISSUES}}
