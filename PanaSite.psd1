# Module manifest for module 'PanaSite' # 2024/09/14
@{
RootModule             = 'PanaSite.psm1'
ModuleVersion          = '0.0.1'
CompatiblePSEditions   = @('Desktop', 'Core')
GUID                   = 'ca594493-55fc-4971-b6eb-33789fdbbf7f'
Author                 = 'Codi Matters'
CompanyName            = 'Incus Data'
Copyright              = '© Codi Matters'
Description            = 'Pandoc-driven static website creator'
DotNetFrameworkVersion = '8.0'
FunctionsToExport      = @(
                         'New-PanaSite',
                         'Reset-GitHistory',
                         'Get-GitConfig',
                         'Get-GitHubRepos',
                         'Set-GitHubRepoDesc',
                         'New-GitHubRepo',
                         'Test-PanaSite',
                         'Test-SubDir',
                         'Test-Cmd' )
AliasesToExport        = @('pns-new')
# CmdletsToExport      = '*'
# VariablesToExport    = '*'
# PowerShellVersion    = '7'
}
