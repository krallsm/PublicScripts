param (
    [Parameter(Mandatory = $true)]
    [string]$appName,

    # [Parameter(Mandatory = $true)]
    [string]$appDescription = "Azure DevOps Service Connection for $appName",

    [Parameter(Mandatory = $true)]
    [string]$devOpsProjectName,

    [Parameter(Mandatory = $true)]
    [string]$tenantName,

    # [Parameter(Mandatory = $true)]
    [boolean]$deployFederatedCredential = $true,

    [SecureString]$federatedIdentityCredentialIssuer,

    [SecureString]$federatedIdentityCredentialSubject
)

$appName = "DevOps-$devOpsProjectName-$tenantName-$appName"

if(!($myApp = Get-AzADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction Stop))
{
    $myApp = New-AzADApplication -DisplayName $appName -Description $appDescription
    New-AzADServicePrincipal -ApplicationId $myapp.AppId
}

if ($deployFederatedCredential -and $myApp)
{
    if (!$federatedIdentityCredentialIssuer)
    {
        $federatedIdentityCredentialIssuer = Read-Host -AsSecureString "Enter the issuer of the federated identity credential"
    }

    if (!$federatedIdentityCredentialSubject)
    {
        $federatedIdentityCredentialSubject = Read-Host -AsSecureString "Enter the subject of the federated identity credential"
    }

    $federatedIdentityCredential = @{
        Name = $appName
        Issuer = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($federatedIdentityCredentialIssuer)))
        Subject = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($federatedIdentityCredentialSubject)))
        Description = $appDescription
        Audience = @("api://AzureADTokenExchange")
    }

    New-AzADAppFederatedCredential `
        -ApplicationObjectId $myapp.Id `
        -Issuer $federatedIdentityCredential.Issuer `
        -Subject $federatedIdentityCredential.Subject `
        -Description $federatedIdentityCredential.Description `
        -Audience $federatedIdentityCredential.Audience `
        -Name $federatedIdentityCredential.Name
}