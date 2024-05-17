# Usage
This Script is intendet to be run on the domaincontroller
1. Download and open the .ps1 file and configure the parameters to your needs
     a. $AttributeName -> Active Directory Attribute that is being used to store the totp secret
     b. $GroupName -> Active Directory Group of which members get a totp secret configured
     c. $issuer -> TOTP Issuer or Title the generated QR-Code will use
2. Run the script
3. verify

# Parameters
## -genqr
QR-Codes are only being generated if this parameter is set. To generate QR-Codes the Powershell module QRCodeGenerator is being used. https://www.powershellgallery.com/packages/QRCodeGenerator

## -gencrt
Certificates are only being generated if this parameter is set. If this option is used the correct Login Credentials have to be set in the .ps1 script
