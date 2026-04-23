param(
    [switch]$lld,
    [string]$user
)

$recyclePath = 'C:\$Recycle.Bin'
$data = @()

$excludeUsersPatterns = @(
    '^NT AUTHORITY\\SYSTEM$',
    '^BUILTIN\\Users$',
    '^DefaultAccount$',
    '^WDAGUtilityAccount$'
)

if (Test-Path $recyclePath) {
    Get-ChildItem -Path $recyclePath -Force | Where-Object {$_.PSIsContainer} | ForEach-Object {
        $sid = $_.Name
        $size = 0

        try {
            $username = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
        } catch {
            $username = $sid
        }

        if ($excludeUsersPatterns | Where-Object { $username -match $_ }) { return }

        Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer -and $_.Name -like '$R*' } |
        ForEach-Object { $size += $_.Length }

        $sizeBytes = $size
        $usernameKey = $username -replace '\\','_'

        if ($user -and $usernameKey -ne $user) { return }

        $data += [PSCustomObject]@{
           USERNAME    = $username
           USERNAMEKEY = $usernameKey
           SIZE_BYTES  = $sizeBytes
        }
    }
}

if ($lld) {
    $lldData = @{data = @()}
    foreach ($entry in $data) {
        $lldData.data += @{
            "{#USERNAME}" = $entry.USERNAMEKEY
        }
    }
    $lldData | ConvertTo-Json -Compress
} elseif ($user) {
    $entry = $data | Where-Object { $_.USERNAMEKEY -eq $user }
    if ($entry) { $entry.SIZE_BYTES } else { 0 }
} else {
    $lldData = @{data = @()}
    foreach ($entry in $data) {
        $lldData.data += @{
            "{#USERNAME}" = $entry.USERNAMEKEY
        }
    }
    $lldData | ConvertTo-Json -Compress
}
