# Security Policy

## Supported Versions

Security fixes are provided for the latest released version.

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |

## Reporting a Vulnerability

Please report security issues privately instead of opening a public issue.

Use GitHub private vulnerability reporting if it is enabled for this repository, or contact the maintainer through GitHub:

- Maintainer: https://github.com/guojianghong0202
- Repository: https://github.com/guojianghong0202/project-kickoff-skill

When reporting, include:

- A short description of the issue.
- Affected files or workflow.
- Steps to reproduce, if applicable.
- Potential impact.
- Suggested fix, if you have one.

Expected response:

- Initial acknowledgement: within 7 days.
- Triage and severity assessment: within 14 days when enough information is provided.
- Fix or mitigation plan: best effort, depending on severity and project scope.

## Scope

This repository contains an AI skill, Markdown references, GitHub configuration, and a small Python scaffold script. Relevant security concerns include:

- Malicious or unsafe workflow configuration.
- Secrets accidentally committed to examples or references.
- Scaffold script behavior that overwrites or deletes user files.
- Prompt instructions that encourage unsafe project operations.

The scaffold script is designed to avoid overwriting files by default.
