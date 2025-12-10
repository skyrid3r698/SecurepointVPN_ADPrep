Param(
    [switch]$genqr,
    [switch]$gencrt
)

$gencrt = $true

$AttributeSecret = "extensionAttribute10"
$AttributeCrt = "extensionAttribute12"
$SPIP = ((Get-NetIpConfiguration).IPv4DefaultGateway).NextHop
$SPName = "mc-admin"
$SPPass = '9w$M9JFg2gLAD#'
$SpPass = $SpPass | ConvertTo-SecureString -AsPlainText -Force
$global:SpCred = New-Object System.Management.Automation.PSCredential -ArgumentList "$SpName", $SpPass
$GroupName = "GRP_SecurePoint-VPN"
$issuer = "MCOMP_VPN"
$vpnusers = Get-ADGroupMember -Identity $GroupName

#defining variables
$global:totalcount > $null
$global:CACleanOutput > $null
$global:SshSession > $null
$global:Cert > $null


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

if ($gencrt -eq $true) {
    $FormatEnumerationLimit = 100
if((Get-Module -Name "Posh-SSH" -ListAvailable) -eq $null) {
    Write-Host "Posh-SSH module is not installed! Please follow the install"
    Install-Module Posh-SSH
    Import-Module Posh-SSH
    if ((get-module "Posh-SSH") -eq $null) {
            Write-Host "Posh-SSH install failed! Usercertificates will not be generated"
            $gencrt = $false
            }
}

$global:SshSession = New-SSHSession -ComputerName $SPIP -Credential $global:SpCred -AcceptKey -ErrorAction Stop

function New-CA {
    $NewCAName = Read-Host "Type the Name of your new CA"
    $NewCAValidity = Read-Host "Type the time the new CA will be valid for in years(default=10)"
    if ($NewCAValidity -eq "") { $NewCAValidity = "10"}
    $NewCAValidity = (Get-Date).AddYears($NewCAValidity).ToString('yyyy-MM-dd-00-00-00')
    $CAs = Invoke-SSHCommand -SSHSession $global:SshSession -Command "cert new name $NewCAName common_name $NewCAName bits 4096 valid_since $(Get-Date -Format yyyy-MM-dd-00-00-00) valid_till $NewCAValidity"
}

function Get-CA ([switch]$silent){
$CAID = Invoke-SSHCommand -SSHSession $global:SshSession -Command "cert get"
$CAID = ($CAID | findstr "KEY,CA").Replace(" ", "").Replace("-","").Replace("+","").Replace(",","")
$global:totalcount = $($CAID.count)
$count = -1
$global:CACleanOutput = New-Object System.Collections.ArrayList
foreach($CA in $CAID) {
    $count ++
    if ($CA.StartsWith("|")) {
        if ($silent -ne $true) {
            Write-Host "Nr.$count" $CA.Substring(1)
        }
        $CACleanOutput.Add($CA.Substring(1)) > $null
    }
    else {
        if ($silent -ne $true) {
            Write-Host "Nr.$count" $CA
        }
        $CACleanOutput.Add($CA) > $null
    }
    }
}

function New-UserCert([string]$NewCertName) {
    $NewCertValidity = Read-Host "Type the time the new Certs will be valid for in years(default=5)"
    if ($NewCertValidity -eq "") { $NewCertValidity = "5"}
    $NewCertValidity = (Get-Date).AddYears($NewCertValidity).ToString('yyyy-MM-dd-00-00-00')
    $global:Cert = Invoke-SSHCommand -SSHSession $global:SshSession -Command "cert new name $NewCertName-RW bits 4096 valid_since $(Get-Date -Format yyyy-MM-dd-00-00-00) valid_till $NewCertValidity issuer_id $CACleanSelection flags KEY signature_algo sha256WithRSAEncryption"
}

Write-Host "The following $global:totalcount CAs were found on your Firewall:"
Get-CA
$CASelection = Read-Host "Please select the number of the CA you want to use to generate the VPN User Certs with. To create a new CA type: new"


if ($CASelection -eq "new") {
    Write-Host "A new CA will be created, please follow the Setup:"
    New-CA
    Get-CA -silent
    $CASelection = $global:totalcount -1
}
else {
    Write-Host "Selected: $($global:CACleanOutput[$CASelection])"
}
$CACleanSelection = (($global:CACleanOutput[$CASelection]) -split '\|')[0]

}

foreach ($vpnuser in $vpnusers) {
$CurrentAttributeValue = (Get-ADUser -Identity $vpnuser -Properties *).$AttributeSecret
if ($CurrentAttributeValue -ne $null) {
    Write-Host $vpnuser.name "has value: $CurrentAttributeValue Will be skipped." -ForegroundColor Yellow
    if ($genqr -eq $true) {
        New-QRCodeText -Text "otpauth://totp/$($vpnuser.name)?secret=$CurrentAttributeValue&issuer=$issuer&algorithm=SHA1&digits=6&period=30" -OutPath "C:\Users\$env:username\Desktop\QR-Codes\$($vpnuser.name).png"
        }
    if ($gencrt -eq $true) {
        New-UserCert -NewCertName "$vpnuser"
        Set-ADUser -Identity $vpnuser -Add @{ $AttributeCrt = "$vpnuser-RW" }
        }
    }
    else {
    Write-Host "$($vpnuser.name) has no value. Will be set"
    [String]$userkey = ""
    1..16 | % { $userkey += $(Get-Random -InputObject A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7) }
    Set-ADUser -Identity $vpnuser -Add @{ $AttributeSecret = $userkey }
    Write-Host "$($vpnuser.name) Now has value: $userkey" -ForegroundColor Green
    if ($genqr -eq $true) {
        New-QRCodeText -Text "otpauth://totp/$($vpnuser.name)?secret=$userkey&issuer=$issuer&algorithm=SHA1&digits=6&period=30" -OutPath "C:\Users\$env:username\Desktop\QR-Codes\$($vpnuser.name).png"
        }
    if ($gencrt -eq $true) {
        New-UserCert -NewCertName "$vpnuser"
        Set-ADUser -Identity $vpnuser -Add @{ $AttributeCrt = "$vpnuser-RW" }
        }
    }
}
if ($genqr -eq $true) {
    explorer.exe "C:\Users\$env:username\Desktop\QR-Codes\"
    }

Remove-SSHSession -SSHSession $SshSession > $null
