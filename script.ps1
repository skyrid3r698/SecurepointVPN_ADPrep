$vpnusers = Get-ADGroupMember -Identity "GRP_SecurePoint-VPN"
$AttributeName = "extensionAttribute10"
foreach ($vpnuser in $vpnusers) {
if ((Get-ADUser -Identity $vpnuser -Properties *).$AttributeName) {
    Write-Host $vpnuser "has value. Will be skipped." -ForegroundColor Green
    } 
    else {
    Write-Host $vpnuser "has no value. Will be set"
    [String]$userkey = ""
    1..16 | % { $userkey += $(Get-Random -InputObject A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7) }
    Set-ADUser -Identity $vpnuser -Add @{ extensionAttribute10 = $userkey }
    }

}
