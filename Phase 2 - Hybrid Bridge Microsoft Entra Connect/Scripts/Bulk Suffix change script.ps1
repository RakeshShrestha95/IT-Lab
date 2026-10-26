# Define your new domain suffix
$newSuffix = "inprogress7415.onmicrosoft.com"   
$staffOU = "OU=Staff,OU=InProgress,DC=inprogress,DC=local"

# Fetch the users from the target OU
$users = Get-ADUser -Filter * -SearchBase $staffOU

# Loop through and update each user
foreach ($user in $users) {
    $newUPN = "$($user.SamAccountName)@$newSuffix"
    Set-ADUser -Identity $user.DistinguishedName -UserPrincipalName $newUPN
    Write-Host "Updated $($user.SamAccountName) to $newUPN"
}