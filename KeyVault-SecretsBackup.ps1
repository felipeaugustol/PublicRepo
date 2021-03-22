<#
Author:     Felipe Augusto - Date: 25/02/2021
Version:    1.0 - This script will maintain secrets synced from Origin to Destination KeyVault, comparitive operation is handled in memory.

Requirements:
- Requires PowerShell 7 
#>

Param([Parameter(Mandatory = $true)][string] $origin,
	[Parameter(Mandatory = $true)][string] $destination)


Write-Host = "Checking if $($destination) KeyVault contain all latest secrets from $($origin) KeyVault..."
$secretNames = (Get-AzKeyVaultSecret -VaultName $origin | Where-Object {$_.ContentType -notlike "application/*"} ).Name
foreach ($secretName in $secretNames) {
    $checkdestination = Get-AzKeyVaultSecret -VaultName $destination -Name $secretName
    if (!$checkdestination) {
        Write-Host "Secret $($secretName) not found on $($destination) KeyVault, creating..." 
        Set-AzKeyVaultSecret -VaultName $destination -Name $secretName `
            -SecretValue (Get-AzKeyVaultSecret -VaultName $origin -Name $secretName).SecretValue `
            -ContentType (Get-AzKeyVaultSecret -VaultName $origin -Name $secretName).ContentType
    }
    else {
        $checkSecretValueOrigin = (Get-AzKeyVaultSecret -VaultName $origin -Name $secretName).SecretValue | ConvertFrom-SecureString -AsPlainText
        $checkSecretValueDestination = (Get-AzKeyVaultSecret -VaultName $destination -Name $secretName).SecretValue | ConvertFrom-SecureString -AsPlainText
        if ($checkSecretValueOrigin -ne $checkSecretValueDestination) {
            Write-Host "Secret $($secretName) outdated on $($destination) KeyVault, pushing latest..." 
           Set-AzKeyVaultSecret -VaultName $destination -Name $secretName `
                -SecretValue (Get-AzKeyVaultSecret -VaultName $origin -Name $secretName).SecretValue `
                -ContentType (Get-AzKeyVaultSecret -VaultName $origin -Name $secretName).ContentType
        }
        else {
            Write-Host "Secret for $($secretName) is equal on both KeyVaults, no chages required..." 
        }
    }
}