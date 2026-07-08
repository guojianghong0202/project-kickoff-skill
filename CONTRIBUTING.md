# Contributing

Thanks for improving Project Kickoff Skill.

## Rules

- Keep `SKILL.md` concise. Move detailed templates, examples, and methodology notes into supporting files.
- Keep the frontmatter `description` trigger-focused.
- Add or update an example when changing output format.
- Add or update eval prompts when changing trigger behavior.
- Do not make the workflow heavier for S-sized projects.
- Do not add hidden assumptions to templates. Use `TBD（负责人 / 截止日）` when information is missing.

## Local checks

Run the scaffold script syntax check:

```bash
python -m py_compile scripts/scaffold.py
```

Manually test the prompts in `evals/prompts.md` in a fresh session before publishing a release.
