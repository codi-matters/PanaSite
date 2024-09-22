## Test-BoundParams ## {{{1
<#
.SYNOPSIS
Check bound parameters and `--long` option equivalents.

.DESCRIPTION
Check for (some) common `CmdLetBinding` parameters. If passed the `$arg`
argument as well, it will check if that contains GNU-like common long
options like `--help`, `--version`, etc.

.PARAMETER bparm
Must be of type `$PSCmdLet.MyInvocation.BoundParameters`, and passed 
from the caller function.

.PARAMETER arg
A function or script argument that *may* contain `--help`, etc.
#>
function Test-BoundParams {
   param( [Parameter()]$bparm, [Parameter()]$arg )
   return @{
      verbose = $bparm.ContainsKey("Verbose") `
               -or ($arg -and $arg -imatch "--verbose")
      whatif  = $bparm.ContainsKey("WhatIf" )
      debug   = $bparm.ContainsKey("Debug"  ) `
               -or ($arg -and $arg -imatch "--debug")
      confirm = $bparm.ContainsKey("Confirm") `
               -or ($arg -and $arg -imatch "--confirm")
      help    = $bparm.ContainsKey("Help"   ) `
               -or ($arg -and $arg -imatch "--help")
      version = $bparm.ContainsKey("Version") `
               -or ($arg -and $arg -match "--version")
      }
   }

## Test-PanaSite ## { #{{{1
function Test-PanaSite {
   Write-Debug "TESTME"
   Write-Verbose "TESTME"
   }

## version ## {{{1
<#
.SYNOPSIS
A number of utility functions used by `New-PanaSite.ps1`.

.DESCRIPTION
This is sourced (`.`) early in `New-PanaSite.ps1`. The point is to
keep `New-PanaSite.ps1` as short as possible.
#>
function version {
<# Uses global variables set up by the parent script #>
Write-Output ("$script:MN — $($script:Version)")
}#function version


## Test-Cmd ## {{{1
function Test-Cmd {
param ( [Parameter(Mandatory)][string]$Command )
return -not -not (Get-Command $Command -ErrorAction SilentlyContinue)
}## function Test-Cmd


## Test-SubDir {{{1
function Test-SubDir {
param (
   [Parameter(Mandatory)][string]$Path,
   [Parameter(Mandatory)][string]$Root
   )
$fullPath = [IO.Path]::GetFullPath($Path)
$fullRoot = [IO.Path]::GetFullPath($Root)
return $fullRoot.StartsWith($fullPath)
}#function Test-SubDir


## Reset-GitHistory ## {{{1
function Reset-GitHistory {
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
   param (
      [string]$Message = "Clean start",
      [switch]$Force,
      [switch]$Push
      )

if (-not (Test-Path -Path ".git" -PathType Container)) {
   Write-Error "Not a Git repository (no './.git' folder)"
   return
   }

$branch = git symbolic-ref --short HEAD 2>&1
if ($LastExitCode -ne 0) {
   Write-Error "Unable to retrieve branch name. Aborting."
   return
   }
if (-not $Force) {
   if (-not $PSCmdlet.ShouldProcess(
         "Reset Git history on '$branch'. Sure?",
         "Reset-GitHistory")) {
      Write-Host "Operation canceled."
      return
      }
   }

Write-Verbose "Resetting history ..."
git checkout --orphan temp_branch 2>&1 | Out-Null  # New orphan branch.
git add --all                     2>&1 | Out-Null  # Add all files.
git commit -m $Message            2>&1 | Out-Null  # Commit with message.
git branch -D $branch             2>&1 | Out-Null  # Delete the old branch.
git branch -m $branch             2>&1 | Out-Null  # Rename to old branch.

if ($Push) {
   git push -f origin $branch   # Force push to the origin (only if -Push is set)
   Write-Verbose "Cleared history & pushed '$branch' to origin."
   }
else {
   Write-Verbose "Cleared history on branch '$branch' (no push)"
   }

}#function Reset-GitHistory

## Get-GitConfig #{{{1
function Get-GitConfig {
   param ( [string]$Key, [switch]$Global )

   $scope = if ($Global) { "--global" } else { "--local" }

   $configValue = git config $scope --get $Key 2>$null
   if ($configValue) {
      return $configValue
      }
   else {
      return $null
      <# Write-Error `
         "Key '$Key' not in $($Global ? 'global' : 'local') scope."
      #>
      }
   }

# Usage examples:
# Get-GitConfig -Key "user.name"
# Get-GitConfig -Key "user.email" -Global

<# Get-GitHubRepos {{{1
function Get-GitHubRepos {
   param ( [string]$User = $Env:GHUNM, [string]$Token = $Env:GHTKN )

   if (-not $User) {
      Write-Error "GitHub ``-User`` not provided and `$GHUNM not set."
      return
      }

   if (-not $Token) {
      Write-Error "GitHub ``-Token`` not provided and `$GHTKN not set."
      return
      }

   $headers = @{
      Authorization = "token $Token"
      UserAgent     = "PowerShellGitHubClient"
      }

   # $url = "https://api.github.com/users/$User/repos"

   $result = @()

   $url = "https://api.github.com/user/repos"
   try{
      $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
      Write-Output $reponse
      }
   catch {
      Write-Error "Failed to retrieve repos: $_"
      return
      }
   $result += $response

   $repos = @()
   foreach ($repo in $results) {
      $repos += [PSCustomObject]@{
         Name        = $repo.name
         Owner       = $repo.owner.login
         FullName    = $repo.full_name
         Description = $repo.description
         Visibility  = $repo.visibility
         UpdatedAt   = $repo.updated_at
         }
      }

   return $repos
   }

# Usage example
# Get-GitHubRepos
#>

function Get-GitHubRepos { # {{{1
   param (
      [string]$User = $Env:GHUNM,
      [string]$Token = $Env:GHTKN
      )

   if (-not $User) {
      Write-Error "GitHub username not provided and `$GHUNM not set."
      return
      }
   if (-not $Token) {
      Write-Error "GitHub token not provided and `$GHTKN not set."
      return
      }

   $headers = @{
      Authorization = "token $Token"
      UserAgent     = "PowerShellGitHubClient"
      }

   $repos = @()
   $page = 1

   do {
      $url = "https://api.github.com/user/repos?per_page=100&page=$page"

      try{
         $response = Invoke-RestMethod -Uri $url `
            -Headers $headers -Method Get
         }
      catch {
         Write-Error "Failed to retrieve repositories: $_"
         return
         }

      $repos += $response
      $page++
      }
   while ($response.Count -gt 0)

   $repos | ConvertTo-Json | Set-Content repos.json
   $result = @()
   foreach ($repo in $repos) {
      $result += [PSCustomObject]@{
         Name        = $repo.name
         FullName    = $repo.full_name
         Description = $repo.description
         Owner       = $repo.owner.login
         UpdatedAt   = $repo.updated_at
         Visibility  = $repo.visibility
         }
      }

   return $result
   }


## New-GitHubRepo # {{{1

<#
.SYNOPSIS
Creates a new GitHub repository for the current directory.

.DESCRIPTION
This function creates a new GitHub repository using the GitHub REST API. 
It requires a GitHub username and token for authentication. By default,
it creates a private repository, unless the -Public switch is specified.

.PARAMETER User
The GitHub username. Defaults to contents of the `$Env:GHUNM` variable.

.PARAMETER Token
The GitHub personal access token. Defaults to the value of the
`$Env:GHTKN` environment variable.

.PARAMETER Repo
The name of the repository to create. If not provided, the function uses
the base name of the current directory as the repository name.

.PARAMETER Public
Creates a public repository when this switch is specified. By default,
the repository is private.

.PARAMETER Description
A description for the new repository.

.PARAMETER Force
Bypasses the confirmation prompt before creating the repository.

.INPUTS
None. This function does not take pipeline input.

.OUTPUTS
System.String. A success message with the URL of the created repository.

.EXAMPLE
New-GitHubRepo -Repo "MyNewRepo" -Public

Creates a new public GitHub repository named `MyNewRepo` using the
credentials in the environment variables `$Env:GHUNM` and `$Env:GHTKN`.

.EXAMPLE
New-GitHubRepo -Force

Creates a new private GitHub repository using the base name of the current directory 
as the repository name, without asking for confirmation.

.NOTES
The current directory must be a Git-managed repository. It also requires
a valid GitHub personal access token with 'repo' scope for authentication.
#>
function New-GitHubRepo { # {{{1
   [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
   param (
      [Parameter(Position=0)][Alias("r")]
         [string]$Repo = (Get-Item -Path ".").BaseName,
      [Parameter(Position=1)][ValidateNotNullOrEmpty()][Alias("d")]
         [string]$Description,
      [Parameter()]
         [Alias("u")][string]$User = $Env:GHUNM,
      [Parameter()]
         [Alias("t")][string]$Token = $Env:GHTKN,
      [Parameter()]
         [Alias("p")][switch]$Public,
      [Parameter()]
         [Alias("f")][switch]$Force
      )

   if (-not $User) {
      Write-Error "GitHub username not provided and \$Env:GHUNM not set."
      return
      }
   if (-not $Token) {
      Write-Error "GitHub token not provided and \$Env:GHTKN not set."
      return
      }
   if (-not (Test-Path ".git")) {
      Write-Error "Current directory is not a Git-managed repository."
      return
      }

   if (-not $Repo) {
      $Repo = (Get-Item -Path ".").BaseName
      }

   $url = "https://api.github.com/user/repos"
   $payload = @{
      name        = $Repo
      description = "$Description"
      private     = -not $Public
      } | ConvertTo-Json

   $headers = @{
      Authorization = "token $Token"
      UserAgent     = "PowerShellGitHubClient"
      }

   if ($PSCmdlet.ShouldProcess(
         "GitHub repository '$Repo' for user '$User'", "Create")) {
      try{
         $response = Invoke-RestMethod -Uri $url -Headers $headers `
            -Method Post -Body $payload -ContentType "application/json"
         Write-Output( "SUCCESS: Repository '$Repo' created " +
                       "at $($response.html_url)")
         }
      catch {
         Write-Error "Failed to create repository: $_"
         }
      }
   }

## Set-GitHubRepoDesc # {{{1

function Set-GitHubRepoDesc { # {{{1
   [CmdletBinding(SupportsShouldProcess=$true)]
   param (
      [Parameter()][Alias("r")]
         [string]$Repo = (Get-Location | Split-Path -Leaf),
      [Parameter()][Alias("d")]
         [string]$Description,
      [Parameter()][Alias("u")]
         [string]$User = $Env:GHUNM,
      [Parameter()][Alias("t")]
         [string]$Token = $Env:GHTKN
      )

   $VerbosePreference = $PSCmdLet.MyInvocation.BoundParameters.
      ContainsKey("Verbose") ? "Continue" : "SilentlyContinue"

   if (-not $User) {
      Write-Error "GitHub username not provided and `$Env:GHUNM not set."
      return
      }
   if (-not $Token) {
      Write-Error "GitHub token not provided and `$Env:GHTKN not set."
      return
      }
   if (-not $Repo) {
      Write-Error "Repository name required."
      return
      }

   $url = "https://api.github.com/repos/$User/$Repo"
   $payload = @{
      description = $Description
      } | ConvertTo-Json

   $headers = @{
      Authorization = "token $Token"
      UserAgent     = "PowerShellGitHubClient"
      }

   try{
      $verb = $VerbosePreference
      $VerbosePreference = "SilentlyContinue"
      $resp = Invoke-RestMethod -Uri $url -Headers $headers `
         -Method Patch -Body $payload -ContentType "application/json"
      $VerbosePreference = $verb 
      Write-Verbose("'$Repo' description updated to " +
         "``$($resp.description)``")
      }
   catch {
      Write-Error "Failed to update repository description: $_"
      }
   }
<#
# Usage example
Set-GitHubRepoDesc -Repo "your-repo" -Description "Description"

or with `curl`:
curl -X PATCH -u "<user›:‹token›" `
   https://api.github.com/repos/‹user›/‹repo› `
   -d '{"description":"A New Description"}'
#>

<# {{{1
Generate the private ‹token› from GitHub:

 * Go to GitHub Settings → Developer settings → Personal access tokens.
 * Click "Tokens (classic)" → Generate new token 
      → Generate new token (classic).
 * Select scopes like `repo` for repository access.
 * Click Generate token and copy it.

Store the ‹token› securely, as it won’t be shown again. You can use the
GitHub REST API with `curl`, for example, to create new repository:

```sh
$ curl -u "‹user›:‹token›" https://api.github.com/user/repos \
‥    -d '{"name":"‹new-repo-name›"}'

```

★ Note the `user/repos` endpoint. It's verbatim. Do not replace it.

Or, using the official `gh` CLI:

```sh
$ gh repo create ‹new-repo-name› --public --source=. --push
```

To see only public repositories, the URL must be something like, the
following, and no authentication (token) is required:

```ps1
$url = "https://api.github.com/users/$User/repos"
```

With `curl`: `curl https://api.github.com/users/codi-matters/repo` The
result is in JSON format.

To retrieve only private repositories as well, use a `user/repos` URL:

```ps1
$url = "https://api.github.com/user/repos"
```
#>

# vim: et ts=3 sts=3 sw=3 fdm=marker :
#
