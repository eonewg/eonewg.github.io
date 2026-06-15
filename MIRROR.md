# Custom-domain mirror

Canonical source repo:

```text
eonewg/eonewg.github.io -> https://eonewg.github.io/
```

Custom-domain mirror repo:

```text
eonewg/eeeone.me -> https://eeeone.me/
```

Why split them:

GitHub Pages redirects `eonewg.github.io` to the custom domain when `CNAME` is stored in the user-site repo. Keeping `eeeone.me` in a separate mirror repo lets `https://eonewg.github.io/` remain a stable fallback if the custom domain is not renewed later.

Sync after editing the main repo:

```bash
./scripts/sync-custom-domain-mirror.sh
```

Dry/local-only push prevention:

```bash
./scripts/sync-custom-domain-mirror.sh --no-push
```

Rules:

- Edit `eonewg.github.io` first.
- Do not add `CNAME` to `eonewg.github.io`.
- Keep `CNAME` only in `eeeone.me`, with content `eeeone.me`.
- The sync script refuses to run if either repo has uncommitted changes.
