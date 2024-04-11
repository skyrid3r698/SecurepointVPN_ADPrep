Param(
    [switch]$genqr
)

$AttributeName = "extensionAttribute10"
$GroupName = "GRP_SecurePoint-VPN"
$issuer = "MCOMP_VPN"
$vpnusers = Get-ADGroupMember -Identity $GroupName

if ($genqr -eq $true) {
    if ((test-path "C:\Users\$env:username\Desktop\QR-Codes\") -eq $false) {
        mkdir "C:\Users\$env:username\Desktop\QR-Codes\"
        }
    if ((get-module qrcodegenerator) -eq $null) {
         Write-Host "QRCodeGenerator module is not installed! Please follow the install"
        Install-Module QRCodeGenerator
        Import-Module QRCodeGenerator
        if ((get-module qrcodegenerator) -eq $null) {
            Write-Host "QRCodeGenerator install failed! QR-Codes will not be generated"
            $genqr = $false
            }
        }
    }

foreach ($vpnuser in $vpnusers) {
$CurrentAttributeValue = (Get-ADUser -Identity $vpnuser -Properties *).$AttributeName
if ($CurrentAttributeValue -ne $null) {
    Write-Host $vpnuser.name "has value: $CurrentAttributeValue Will be skipped." -ForegroundColor Yellow
    if ($genqr -eq $true) {
        New-QRCodeText -Text "otpauth://totp/$($vpnuser.name)?secret=$CurrentAttributeValue&issuer=$issuer&algorithm=SHA1&digits=6&period=30" -OutPath "C:\Users\$env:username\Desktop\QR-Codes\$($vpnuser.name).png"
        }
    }
    else {
    Write-Host "$($vpnuser.name) has no value. Will be set"
    [String]$userkey = ""
    1..16 | % { $userkey += $(Get-Random -InputObject A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7) }
    Set-ADUser -Identity $vpnuser -Add @{ extensionAttribute10 = $userkey }
    Write-Host "$($vpnuser.name) Now has value: $userkey" -ForegroundColor Green
    if ($genqr -eq $true) {
        New-QRCodeText -Text "otpauth://totp/$($vpnuser.name)?secret=$userkey&issuer=$issuer&algorithm=SHA1&digits=6&period=30" -OutPath "C:\Users\$env:username\Desktop\QR-Codes\$($vpnuser.name).png"
        }
    }
}
if ($genqr -eq $true) {
    explorer.exe "C:\Users\$env:username\Desktop\QR-Codes\"
    }
