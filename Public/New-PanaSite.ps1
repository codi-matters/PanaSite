param ( $TT ) # must be passed by ‘sourcer’ or caller.

Set-Alias pns-new New-PanaSite

<#
.SYNOPSIS
Create a new Pandoc static website

.DESCRIPTION
Create a Pandoc-driven static website. The conversions are handled by
PowerShell scripts, Pandoc, and some Lua filters like `panda.lua`.

.PARAMETER Path
Name of the directory that will contain the markdown and other files. If
omitted, will use the current directory. Confirmation is required if an
existing directory is specified.

.PARAMETER Base
Base directory for the markdown sources inside `-Path`. If a relative
path or absolute path is given, only the basename (last part) will be
used. This directory must always be inside the `-Path` directory. The
default is `src` (for ‘source’). You only have to pass this option if
you do not like the default.

.PARAMETER Force
Use with care. This will cause existing directories to be deleted.

The structure inside ‹-Base›, will be replicated inside the `-Root`
directory. So that: ‹-Path›/‹-Base›/‹sub-dir›, will be reflected as:
‹-Root›/‹sub-dir>. Here is a more visual explanation of the structure:

   ‹-Path›
     ├─‹-Base›                ‹-Root›
     │ ├─‹dir-1›              ├─‹dir-1›
     │ │ ├‹dir-1.1›           │ ├‹dir-1.2›
     │ │ │ └─ file1.md        │ │ └─ file1.html
     │ │ ├‹dir-1.2›           │ ├‹dir-1.3›
     │ ├─‹dir-2›              ├─‹dir-2›
     ┊ ├─index.md             ├─ index.html

This will happen automatically when you convert Markdown to HTML. The
‹-Root› directory will become the *root* of you website (`/`).

.PARAMETER Root
Name of the directory in which the static website will be published. By
default, a `pub` subdirectory of `-Path` will be used. Confirmation is
required if an existing directory is specified. This become the root
directory if you serve or publish the site.

The default is `"pub"` (for ‘publish’), inside the ‹-Path› directory.
You only have to pass this option if you do not like the default.

If `-Root` does not contain directory separators, it will be taken as
relative to `-Path`. Otherwise, it will be considered absolute, or
relative to the current working directory.

.PARAMETER Git
Initialise the `-Path` as a repository. The `git` command must be on
your PATH, otherwise the creation will fail. It will also create a
`.gitignore` file in the root.

.INPUTS
None
.OUTPUTS
None
#>
function New-PanaSite {

[CmdletBinding(SupportsShouldProcess=$true)] #{{{1
param (
   # [Parameter(ValueFromRemainingArguments=$true)]
   [Parameter(Mandatory=$false,Position=0)][Alias("p")]
      [string]$Path = $null,
   [Parameter(Mandatory=$false)][Alias("b")]
      [string]$Base = "src",
   [Parameter()][Alias("r")]
      [string]$Root = "pub",
   [Parameter()][Alias("g")]
      [switch]$Git = $false,
   [Parameter()][Alias("fo")]
      [switch]$Force = $false,
   [Parameter()][Alias("h")]
      [switch]$Help = $false,
   [Parameter()][Alias("vers")]
      [switch]$Version = $false,
   [Parameter(Mandatory=$false,Position=-1,ValueFromRemainingArguments=$true)]
      [string[]]$ArgX = $null
   )
# Deal with help and other standard options ## {{{1
#
$opts = Test-BoundParams $PSCmdLet.MyInvocation.BoundParameters "$Path $ArgX"
if ($opts.verbose) { $VerbosePreference = "Continue" }
if ($opts.confirm) { $ConfirmPreference = "High"     }
if ($opts.debug)   { $DebugPreference   = "Continue" }
if ($opts.whatif)  { $WhatIfPreference  = $true      }
$opts.force = $Force ? $true : $false

Write-Debug "$TT..."
Write-Debug "Function: $($MyInvocation.MyCommand.Name)"
if ($opts.debug -and $Path) { Write-Debug "Args: $Path $ArgX" }
Write-Debug("verbose=$($opts.verbose), whatif=$($opts.whatif), " +
            "debug=$($opts.debug), version=$($opts.version), " +
            "help=$($opts.help), confirm=$($opts.confirm), " +
            "force=$($opts.force)")
if ($opts.version) {
   Write-Host "${script:MN} - Version $script:Version"
   }
if ($opts.help) {
   $def = $MyInvocation.MyCommand.Name
   if ($opts.verbose) { Get-Help $def -Full   }
   else               { Get-Help "about_$def" }
   }

# Error-check paths and convert all to absolute paths. {{{1
#
[IO.Directory]::SetCurrentDirectory("$(Get-Location)") #NB! NB! NB! NB!
$other = ($opts.version -or $opts.help -or $opts.verbose -or $opts.debug)
if (-not $Path) {
   Write-Error "One argument required. Try: ``-Help``"
   if (-not $other) { return }
   }
if (-not $Path -or ($Path -match '^--?[a-zA-Z]+')) {
   $ArgX = "$Path $ArgX"
   $Path = "$(Get-Location)"
   }
$Path = [IO.Path]::GetFullPath($Path)

if ($Base -match "[/\\]") {
   $Base = Split-Path $Base -Leaf
   }
$Base = "$Path${script:DS}$Base"

if (-not ($Root -match "[/\\\.]")) {
   $Root = Join-Path $Path -ChildPath $Root
   }
else {
   $Root = [IO.Path]::GetFullPath(
      "$($Root ? "$Root" : (Join-Path $Path "pub"))")
   }

Write-Verbose "-Path `"$Path`""
Write-Verbose "-Base `"$Base`""
Write-Verbose "-Root `"$Root`""

if ($opts.version -or $opts.help) { return }

$s = Join-Path "$script:MD" "Scripts/Make-SiteDirs "
$cmd = "$s `"$Path`" `"$Root`" `"$Base`""
$o  = $opts.verbose ? " -Verbose" : ""
$o += $opts.confirm ? " -Confirm" : ""
$o += $opts.debug   ? " -Debug"   : ""
$o += $opts.whatif  ? " -WhatIf"  : ""
$o += $opts.force   ? " -Force"   : ""
$cmd += $o
Write-Debug "CMD: $cmd"
$ret = Invoke-Expression $cmd
if ($ret -ne 0) { return }

$s = Join-Path "$script:MD" "Scripts/Make-GitSite"
$cmd = "$s `"$Path`" `"$Root`" `"$Base`" $o"
Write-Debug "CMD: $cmd"
Invoke-Expression $cmd

if ($opts.verbose -and (Test-Cmd "lsd")) {
   lsd $Path --tree --group-directories-first --all `
      --ignore-glob ".git" --ignore-glob ".git/*"
   }

}#function New-PanaSite

# vim: et ts=3 sts=3 sw=3 fdm=marker :
