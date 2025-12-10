$AttributeSecret = "extensionAttribute10"
$GroupName = "GRP_SecurePoint-VPN"
$vpnusers = Get-ADGroupMember -Identity $GroupName
$CurrentAttributeValue = (Get-ADUser -Identity $vpnuser -Properties *).$AttributeSecret
$issuer = "MCOMP_VPN"


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

Write-Host "QR Codes werden in C:\Users\$env:username\Desktop\QR-Codes\ gespeichert"
foreach ($vpnuser in $vpnusers) {
$CurrentAttributeValue = (Get-ADUser -Identity $vpnuser -Properties *).$AttributeSecret
Write-Host "Generiere QR-Code für $($vpnuser.name)"
New-QRCodeText -Text "otpauth://totp/$($vpnuser.name)?secret=$CurrentAttributeValue&issuer=$issuer&algorithm=SHA1&digits=6&period=30" -OutPath "C:\Users\$env:username\Desktop\QR-Codes\$($vpnuser.name).png"

}
