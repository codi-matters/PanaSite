<#
## Make-GitSite ##{{{1

.SYNOPSIS
Make the PanaSite `-Path` a Git repository.

.DESCRIPTION
Will initialise the `-Path` of the PanaSite as a Git repository. Will
also create an example `.gitignore` file, with entries appropriate for
the PanaSite directory.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
   [Parameter(Mandatory)][string]$Path,
   [Parameter(Mandatory)][string]$Root,
   [Parameter(Mandatory)][string]$Base,
   [Parameter()][switch]$Force = $false
   )

$verbose = $PSCmdLet.MyInvocation.BoundParameters.ContainsKey("Verbose")
$hasgit = -not -not (Get-Command git -ErrorAction SilentlyContinue)
$dogit = $true
if ($hasgit) {
   if ($PSCmdLet.MyInvocation.BoundParameters.ContainsKey("Confirm")) {
      $yn = Read-Host "Create Git repository at `"$Path`" (y/n)?"
      $dogit = $yn -ieq "y"
      }
   if ($dogit) {
      Write-Verbose "GIT: Init `"$Path`""
      git init -b main "$Path" | Out-Null
      Push-Location "$Path"
      Write-Verbose "GIT: Config"
      # :FIX: some configuration here, maybe?
      git config core.autocrlf false
      Write-Verbose "GIT: Add .gitignore"
      $gif = Resolve-Path "$PSScriptRoot/../Assets/gitignore.txt"
      Copy-Item $gif ".gitignore"
      if (Test-SubDir -Path $Path -Root $Root) {
         $pub = [IO.Path]::GetRelativePath($Path, $Root)
         "# Site/ publish directory" | Add-Content ".gitignore"
         "/" + $pub.Replace("\\", "/") | Add-Content ".gitignore"
         Write-Verbose "GIT: Add '$pub' to .gitignore"
         }
      Write-Verbose "GIT: Config"
      git config core.autocrlf false
      git config core.eol lf

      Write-Verbose "GIT: Add *"
      git add --all | Out-Null

      Write-Verbose "GIT: Commit"
      git commit -m `
         "New PanaSite ‘$(Split-Path $Path -Leaf)’ repository" `
         | Out-Null
      if ($verbose) {
          git log `
             --pretty=format:"%C(auto)%h %C(green)%ad %C(auto)%s" `
             --date=format:"%Y-%m-%d" --color
         }
      Pop-Location
      }
   }
else {
   Write-Error "``git`` command not available on your PATH."
   exit 1
   }

# vim: et ts=3 sts=3 sw=3 fdm=marker :
