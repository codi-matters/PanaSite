<#
.SYNOPSIS
Create, maintain and publish a Pandoc-driven static website.

.DESCRIPTION
Create a Pandoc-driven static website from scratch. Conversions are
handled by PowerShell scripts, Pandoc, and Lua filters like `panda.lua`.

.NOTES
   Author: Codi Matters
   Requires: PowerShell 7
#>

# Define and initialise some module-global variables visible to all the
# functions exported by this module.
#
$script:DS = [IO.Path]::DirectorySeparatorChar
$script:PS = [IO.Path]::PathSeparatorChar
$script:TT = $MyInvocation.MyCommand.Path
$script:MN = Split-Path $MyInvocation.MyCommand.Path -LeafBase
$script:MD = Split-Path $MyInvocation.MyCommand.Path -Parent

# The “current directory” in PowerShell is not the same as the current
# directory in the .NET framework, so if we use `GetFullPath`, it will
# be taken relative to some other directory, often you home directory!
# So we ‘fix’ this with the following command-line (statement):
#
[IO.Directory]::SetCurrentDirectory("$(Get-Location)") #NB! NB! NB! NB!

# Obtain the module version directly from the `.psd1` file. Also define
# a module-global `Version` variable. Access with `$script:Version`, or
# expand inside a string, with `"…${script:Version}…"`.
#
$manifest = Join-Path -Path $PSScriptRoot -ChildPath "${script:MN}.psd1"
$modmfest = Import-PowerShellDataFile -Path $manifest
$script:Version = $modmfest.ModuleVersion
Remove-Variable manifest, modmfest # don't need them anymore.

Write-Verbose "$script:MN} version $script:Version"

# ‘Import’ utilities and exported functions.
#
. "$PSScriptRoot${DS}Private${DS}PanaSite-Util.ps1"
. "$PSScriptRoot${DS}Public${DS}New-PanaSite.ps1" $TT

# vim: et ts=3 sts=3 sw=3 fdm=marker :
