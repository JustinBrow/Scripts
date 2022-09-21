<#
.SYNOPSIS
This script is for setting/updating the RDS certs via Certify The Web

.LINK
https://diverse.services/secure-an-rd-gateway-using-lets-encrypt/
#>

using namespace System.Security.Principal

param ($result)

if ($result)
{
   $pfxpath = $result.ManagedItem.CertificatePath

   if (Test-Path $pfxpath)
   {
      if ([WindowsPrincipal]::new([WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator))   
      {
         Import-Module RemoteDesktop

         if (Get-Module RemoteDesktop)
         {
            Set-RDCertificate -Role RDPublishing -ImportPath $pfxpath -Force
            Set-RDCertificate -Role RDWebAcces -ImportPath $pfxpath -Force
            Set-RDCertificate -Role RDGateway -ImportPath $pfxpath -Force
            Set-RDCertificate -Role RDRedirector -ImportPath $pfxpath -Force
         }
      }
   }
}
