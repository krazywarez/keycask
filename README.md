# keycask

Command-line password manager. One passphrase-encrypted vault file.
Swift, runs on macOS, Linux, and Windows.

## install

```sh
swift build -c release
cp .build/release/keycask ~/.local/bin/
```

## use

```sh
keycask init
keycask add github -u cmc --url https://github.com --tag dev --generate
keycask add mail --words 6
keycask add bank                     # prompts for the password
keycask show github                  # password masked
keycask show github --reveal
keycask show github --field password # raw value, for scripts
keycask clip github                  # clipboard, clears after 45s
keycask ls --tag dev
keycask find example
keycask edit github --tag work --untag dev
keycask rm github --yes
keycask generate --words 5 --copy
```

Every read command takes `--json`. Passwords are masked unless `--reveal`.

Names are labels and may repeat. Every command that takes a name also
takes the entry's 8-character id, which `ls` and `add` print. An
ambiguous name lists the candidates.

## files

| what | default | override |
|---|---|---|
| vault | `$XDG_DATA_HOME/keycask/vault.kc`, else `~/.local/share/keycask/vault.kc` (`%LOCALAPPDATA%\keycask\vault.kc` on Windows) | `KEYCASK_VAULT`, `--vault` |
| passphrase | prompted | `KEYCASK_PASSPHRASE` |

The vault is a JSON envelope: PBKDF2-HMAC-SHA256 (600000 rounds) over
the passphrase, ChaCha20-Poly1305 over the entries. Writes are atomic.

## exit codes

0 ok, 1 failure, 2 usage, 3 not found, 4 cannot decrypt, 5 ambiguous name.

## develop

```sh
swift build
swift test
swift format lint --strict --recursive Sources Tests
```

Design: `docs/superpowers/specs/2026-09-17-keycask-design.md`.
