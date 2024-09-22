# ToDo List

 * Create `README.md` during setup, and fill with some text. Maybe
   read from `PanaSite/Assets/README.md`.

## Environment Config

During the `‹site›` creation process, add a configuration file with
code that will perform some actions like:

 * Save current `$Env:PATH`
 * Set new `$Env:PATH` to `‹site›/bin` etc.
 * Import the PanaSite module.
 * Device a way to restore the previous environment (like `deactive`
   with Python's **`venv`**). Open a new PowerShell session / window?
 * Set encoding of the environment, as well as default parameters to
   UTF-8 encoding. A reason why we may want a new session / windows. We
   do not want to affect user main settings (if any).
 * Maybe add an option to run Browser-Sync immediately.

## Git

 * Maybe add some `/.git/config` options, like LF-only (possible?).
 * Find a way to display `git` repo options, for `-Verbose`/`-Debug`.

## New PowerShell Window

 * See if we can set the title.

## Miscellaneous

 * See if we should use [**`Import-PowerShellDataFile`**][ps-utl-ipsdf].
   Can be used instead of a `.ini`, `.yaml`, `.json`, configure file.

[ps-utl-ipsdf]:
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-powershelldatafile
    "PowerShell — Import-PowerShellDataFile"
