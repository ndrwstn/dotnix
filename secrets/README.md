# Secrets

This directory stores encrypted `.age` files committed to git and
plaintext `.json` files that are gitignored for local editing.

## General shared secrets

- Encrypted: `secrets/general.age`
- Plaintext (gitignored): `secrets/general.json`

Schema (example):

```json
{
  "printers": {
    "brother_mfc_l8900": {
      "uri": "ipp://printer.example.local:631/ipp/print"
    }
  }
}
```

Workflow:

1. Edit `secrets/general.json` locally.
2. Re-encrypt into `secrets/general.age`:

```bash
age -e -r "<recipient-1>" -r "<recipient-2>" -o secrets/general.age secrets/general.json
```

3. Commit only the `.age` file. The `.json` file is gitignored.
