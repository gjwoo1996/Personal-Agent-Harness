# Agent Instructions

## Personal-Agent-Harness Development

When modifying **this repository** (adding rule domains, changing `bin/pah`, stubs, or standards), first read:

- `docs/adding-rule-domains.md`
- `docs/development.md`

These are harness-internal docs. They are **not** installed to target projects by `pah install`.

Do not confuse harness development with applying the harness to other projects. Target-project work uses `setup.sh`, `update.sh`, and devcontainer standards.

After harness changes, run:

```bash
bash tests/test_pah.sh
```
