# # parameters
# $characters = "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "_", "!", "#", "^", "~"

# $vmpassword = -join ($characters | Get-Random -Count 19)
# $vmusername = -join ($characters | Get-Random -Count 19)

# $sqlprodpassword = -join ($characters | Get-Random -Count 19)
# $sqlprodusername = -join ($characters | Get-Random -Count 19)

# $sqldevpassword = -join ($characters | Get-Random -Count 19)
# $sqldevusername = -join ($characters | Get-Random -Count 19)

# $location = Get-AzResourceGroup | select-object Location
# $loc = $location.Location

# $Randnumb = Get-Random -Minimum 1000 -Maximum 9999

# $kvname = "kv-secret-core-"+$Randnumb

# $rg = Get-AzResourceGroup | select-object resourceGroupName
# $resourcegroup = $rg.resourceGroupName
# Set-AzDefault -ResourceGroupName $resourcegroup

# $userId = Get-AzADUser -SignedIn | select-object Id
# $keyvaultojectId = $userId.Id

# # Outputs - Creates KeyVault, Generates Username and Password, then saves them to KeyVault

# New-AzKeyVault `
#   -VaultName $kvname `
#   -resourceGroup $resourcegroup `
#   -Location $loc `
#   -EnabledForTemplateDeployment

# #VM username and password

# $secretvmusernamevalue = ConvertTo-SecureString $vmusername -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "VMusername" -SecretValue $secretvmusernamevalue

# $secretvmpasswordvalue = ConvertTo-SecureString $vmpassword -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "VMpassword" -SecretValue $secretvmpasswordvalue

# #Prod SQL username and password

# $secretprodsqlusernamevalue = ConvertTo-SecureString $sqlprodusername -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "SQLprodusername" -SecretValue $secretprodsqlusernamevalue

# $secretprodsqlpasswordvalue = ConvertTo-SecureString $sqlprodpassword -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "SQLprodpassword" -SecretValue $secretprodsqlpasswordvalue

# #Dev SQL username and password

# $secretdevsqlusernamevalue = ConvertTo-SecureString $sqldevusername -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "SQLdevusername" -SecretValue $secretdevsqlusernamevalue

# $secretdevsqlpasswordvalue = ConvertTo-SecureString $sqldevpassword -AsPlainText -Force
# Set-AzKeyVaultSecret -VaultName $kvname -Name "SQLdevpassword" -SecretValue $secretdevsqlpasswordvalue

#run the bicep file

$UserName = az ad signed-in-user show --query * --output table | Select-Object -Index 4
new-AzResourceGroupDeployment -TemplateFile main.bicep -pDeployUserName $UserName

# -keyVaultName $kvname -keyVaultObjectId $keyvaultojectId 
