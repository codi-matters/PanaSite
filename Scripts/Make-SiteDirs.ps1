<#
## Make-SiteDirs ## {{{1
.SYNOPSIS
Create PanaSite directories

.DESCRIPTION
Create `-Path`, `-Root`, `-Base` and other directories.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
   [Parameter(Mandatory=$true)][string]$Path,
   [Parameter(Mandatory=$true)][string]$Root,
   [Parameter(Mandatory=$true)][string]$Base,
   [Parameter()][switch]$Force
   )

$verbose = $PSCmdLet.MyInvocation.BoundParameters.ContainsKey("Verbose")
$exist = Test-Path $Path -ErrorAction SilentlyContinue
$empty = -not (Get-ChildItem $Path -ErrorAction SilentlyContinue)
$ok = ($exist -and $empty) -or (-not $exist)
Write-Debug "empty=$empty exist=$exist force=$Force"

if (-not $ok -and -not $Force) {
   Write-Error "`"$Path`" exists and is not empty. Aborting."
   exit 1
   }
elseif (-not $ok -and $Force) {
   Write-Verbose "`"$Path`" exists & will be overwritten."
   }
if (-not $ok) {
   Write-Verbose "`"$Path`" and sub-directories deleted."
   Remove-Item -Recurse -Force "$Path" -ErrorAction SilentlyContinue
   }

$dirs = @($Path, $Base,
   (Join-Path $Path "bin"),
   (Join-Path $Path "cfg"), $Root)
foreach ($dir in $dirs) {
   if ($dir -eq $Root -and (Test-Path $Root -PathType Container)) {
      Write-Verbose "Ignoring `"$Root`" outside of `"$Path`" tree"
      continue
      }
   Write-Verbose "Creating `"$dir`""
   New-Item -ItemType Directory -Path $dir | Out-Null
   }
New-Item -ItemType File -Path (Join-Path $Path README.md) | Out-Null

return 0

# vim: et ts=3 sts=3 sw=3 fdm=marker :
