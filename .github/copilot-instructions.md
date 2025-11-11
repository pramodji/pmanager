## Repo snapshot

- Two PowerShell utilities live at the repository root:
  - `PasswordManager.ps1` — console-based, full keyboard-driven UI. Stores entries in a JSON file referenced by `pwdmgr.config` (default `./passwords.dat`). Uses functions: `Initialize-Config`, `Get-Passwords`, `Save-Passwords`, `Add-Password`, `View-Passwords`.
  - `PasswordManager1.ps1` — WPF-based GUI (XAML) with DPAPI encryption. Persists to a CSV (`RetroPasswordKeeper.csv` by default in My Documents) via `Load-Entries` / `Save-Entries`. Uses `Protect-String` / `Unprotect-String` to encrypt password data with DPAPI (CurrentUser scope).

## High-level guidance for AI coding agents

- Focus changes on the script matching the UI: console features (keyboard/hotkeys, console color/RawUI calls) live in `PasswordManager.ps1`. GUI features and DPAPI usage live in `PasswordManager1.ps1`.
- Data storage differs between the two scripts:
  - `PasswordManager.ps1` stores JSON objects (not encrypted) at the path set by `$script:DataFile` and `pwdmgr.config` (see `Initialize-Config`). Example accessors: `Get-Passwords`, `Save-Passwords`.
  - `PasswordManager1.ps1` uses CSV with encrypted password column `PasswordEnc` and helper functions `Protect-String` / `Unprotect-String`. Prefer reusing those helpers when modifying encryption behavior.

## Practical patterns & conventions to follow

- Function naming: PascalCase (e.g., `Add-Password`, `Initialize-DataFile`). Keep exported helpers named the same.
- Script-scoped config variables use the `$script:` scope (e.g., `$script:ConfigFile`, `$script:DataFile`) — update those rather than creating new global vars.
- UI state is often kept in-memory (e.g., `$Entries` list in `PasswordManager1.ps1` and `$passwords` arrays in `PasswordManager.ps1`). Persist with the existing Save/Load helpers.
- Console UI uses direct Console/Host manipulations: `Host.UI.RawUI.ReadKey`, `SetCursorPosition`, and manual color switching. Small refactors must preserve those calls to avoid breaking navigation/hotkeys.
- Secure entry: `PasswordManager.ps1` converts SecureString -> plain via Marshal for storing; be explicit when changing this (it currently writes plaintext JSON). The WPF script uses DPAPI — if you add encryption to the console script, reuse DPAPI helpers from the WPF script.

## Build / run / debug (developer workflows)

- These are PowerShell scripts — no build step. Use Windows PowerShell (5.1) for full WPF support. Example run commands:

```powershell
# Console UI (any modern PowerShell)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\PasswordManager.ps1

# WPF GUI (Windows PowerShell 5.1 recommended for PresentationFramework)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\PasswordManager1.ps1
```

- Editing tips: when testing the WPF script, reload the XAML by re-running the script (session-loaded Add-Type/XAML bindings are not easily live-reloadable).

## Integration & extension notes

- Config file: `pwdmgr.config` is JSON with a `DataFile` key. Update the config via `Initialize-Config` in the console script; respect its format.
- If adding encryption to `PasswordManager.ps1`, prefer using DPAPI helper logic from `PasswordManager1.ps1` (`Protect-String` / `Unprotect-String`) to avoid creating multiple incompatible storage formats.

## Security caveats (important)

- `PasswordManager.ps1` currently writes plain JSON entries to the data file. Treat that file as sensitive when modifying or migrating data.
- `PasswordManager1.ps1` stores encrypted passwords using DPAPI (CurrentUser); migrating between formats requires a careful conversion plan that preserves or re-encrypts secrets.

## Quick examples to reference

- Load passwords (console): `Get-Passwords` -> returns array; `Save-Passwords -Passwords $arr` to persist.
- DPAPI helpers (WPF): `Protect-String "mypassword"` and `Unprotect-String $entry.PasswordEnc`.

## When to ask the human

- Before changing the on-disk format of stored passwords (JSON <-> CSV, encrypted <-> plaintext).
- Before modifying hotkey/keyboard behavior in `PasswordManager.ps1` (these are UX-critical and index-based).

If anything above is unclear or you'd like me to include additional examples (for unit testing, conversion scripts, or an entry-migration tool), tell me which area to expand and I'll iterate.
