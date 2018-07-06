### Grabs all dlists and runs a message trace to see if there is content there. It then compares the list of dlists that received email and removes those from
### the $allGroups alias. $notUsed is an array of all the unused dlists.
$allGroups = Get-DistributionGroup -ResultSize 'Unlimited'
$usedGroups = $allGroups | %{Get-MessageTrace -RecipientAddress $_.PrimarySmtpAddress -StartDate ([DateTime]::Today.AddDays(-7)) -EndDate ([DateTime]::Today) ; `
    Start-Sleep -Milliseconds 500} | select 'RecipientAddress' -Unique

$notUsed = @()
foreach ($group in $allGroups){
    if ($usedGroups.RecipientAddress -notcontains $group.PrimarySmtpAddress) {
        $notUsed += $group.PrimarySmtpAddress
    }
}
### Compares the current list of unused dlists with the list from last week and checks to see if there is anything that has changed since it was last ran. It 
### first checks to see if there is anything on the current list of unused addresses that is not on the list from last week, and if there is it will write the
### new addresses into the json file. Then it checks the list of used addresses to the json file to ensure if anything changed there. If it see's a matching
### entry, it will remove the address from the json file. 
$testJson = Get-ChildItem "$path\unusedGroups.json" | Test-Path -ErrorAction SilentlyContinue
[System.Collections.ArrayList]$unusedJson = Get-Content -path "$path\unusedGroups.json" | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($testJson -eq "$true") {
    foreach ($address in $notUsed){
        if ($unusedJson -notcontains $address) {
            $unusedJson += $address
        }
    }
}
foreach ($list in $unusedJson){
    if ($usedGroups.RecipientAddress -contains $list){
        $unusedJson.Remove($list)
    }
}
$unusedJson | ConvertTo-Json | Out-File "$path\unusedGroups.json"
