$AttributeName = "extensionAttribute10"
$GroupName = "GRP_SecurePoint-VPN"

$vpnusers = Get-ADGroupMember -Identity $GroupName

foreach ($vpnuser in $vpnusers) {
$CurrentAttributeValue = (Get-ADUser -Identity $vpnuser -Properties *).$AttributeName
if ($CurrentAttributeValue -ne $null) {
    Write-Host $vpnuser.name "has value: $CurrentAttributeValue Will be skipped." -ForegroundColor Yellow
    } 
    else {
    Write-Host "$($vpnuser.name) has no value. Will be set"
    [String]$userkey = ""
    1..16 | % { $userkey += $(Get-Random -InputObject A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7) }
    Set-ADUser -Identity $vpnuser -Add @{ extensionAttribute10 = $userkey }
    Write-Host "$($vpnuser.name) Now has value: $userkey" -ForegroundColor Green
    }
    
}
