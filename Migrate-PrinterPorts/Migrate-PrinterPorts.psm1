function Migrate-PrinterPorts
{
   param (
      $servers = (Get-ADGroupMember Terminal_Servers).Name,
      $printers = [ordered]@{
         <# Example Printer
         0 = @{                                     # This is the key for the printer hashtable. Its value must be unique. If using numbers start at 0.
            PrinterName = "Printer";                # This is a string representing the name of the printer displayed to users
            PortName = "Port";                      # This is a string representing the name of the port
            PortIP = "1.1.1.1";                     # This is a string representing the ip address of the port
            PortNumber = 9100;                      # This is a integer representing the number of the port
            SNMPIndex = 1;                          # This is a integer representing the index number of the snmp community
            SNMPCommunity = "public";               # This is a string representing the name of the snmp community
         }
         #>
         0 = @{
            PrinterName = "Printer 1";
            PortName = "127.0.0.1:9100";
            PortIP = "127.0.0.1";
            PortNumber = 9100;
            SNMPIndex = 1;
            SNMPCommunity = "public";
         }
         1 = @{
            PrinterName = "Printer 2";
            PortName = "127.0.0.2:9102";
            PortIP = "127.0.0.2";
            PortNumber = 9102;
         }
      }
   )

   ForEach ($server in $servers)
   {
      Write-Host "Processing printers/ports for server `"$server`""
      ForEach ($key in $printers.Keys)
      {
         $PrinterPortArgs = @{
            ComputerName = $server
            Name = $printers[$key].PortName
            ErrorAction = "SilentlyContinue"
         }
         $printerPort = Get-PrinterPort @PrinterPortArgs
         if (-not $printerPort)
         {
            $PrinterPortArgs.Add("PrinterHostAddress", $printers[$key].PortIP)
            $PrinterPortArgs.Add("PortNumber", $printers[$key].PortNumber)
            if ($printers[$key].SNMPIndex)
            {
               $PrinterPortArgs.Add("SNMPIndex", $printers[$key].SNMPIndex)
            }
            if ($printers[$key].SNMPCommunity)
            {
               $PrinterPortArgs.Add("SNMPCommunity", $printers[$key].SNMPCommunity)
            }
            $PrinterPortArgs.ErrorAction = "Stop"
            try
            {
               Write-Host "Adding printer port `"$($PrinterPortArgs.Name)`" to server `"$server`"." -ForegroundColor 'Yellow' -BackgroundColor 'Black'
               Add-PrinterPort @PrinterPortArgs -Verbose
            }
            catch
            {
               Write-Host "Error: Couldn't add printer port `"$($PrinterPortArgs.Name)`" to server `"$server`"." -ForegroundColor 'Red' -BackgroundColor 'Black'
               continue
            }
         }
         elseif ($printerPort)
         {
            Write-Host "Printer port `"$($PrinterPortArgs.Name)`" has already been added to server `"$server`"." -ForegroundColor 'Yellow' -BackgroundColor 'Black'
         }
         else
         {
            Write-Host "Something went horribly wrong. Entering debug mode"
            $Host.EnterNestedPrompt()
         }
         $PrinterArgs = @{
            ComputerName = $server
            Name = $printers[$key].PrinterName
            ErrorAction = "SilentlyContinue"
         }
         $printer = Get-Printer @PrinterArgs
         if ($printer -and ($printer).PortName -ne $printers[$key].PortName)
         {
            $PrinterArgs.Add("PortName", $printers[$key].PortName)
            $PrinterArgs.ErrorAction = "Stop"
            try
            {
               Write-Host "Changing port for printer `"$($PrinterArgs.Name)`" from `"$($printer.PortName)`" to `"$($PrinterArgs.PortName)`"." -ForegroundColor 'Yellow' -BackgroundColor 'Black'
               Set-Printer @PrinterArgs -Verbose
               try
               {
                  Write-Host "Removing port `"$($printer.PortName)`"" -ForegroundColor 'Yellow' -BackgroundColor 'Black'
                  Remove-PrinterPort -ComputerName $server -Name "$($printer.PortName)"
               }
               catch
               {
                  Write-Host "Error: Couldn't remove port `"$($printer.PortName)`"" -ForegroundColor 'Red' -BackgroundColor 'Black'
                  continue
               }
            }
            catch
            {
               Write-Host "Error: Couldn't add printer `"$($PrinterArgs.Name)`" to server `"$server`"." -ForegroundColor 'Red' -BackgroundColor 'Black'
               continue
            }
         }
         elseif (-not $printer)
         {
            Write-Host "Error: Printer `"$($PrinterArgs.Name)`" does not exist on server `"$server`"." -ForegroundColor 'Red' -BackgroundColor 'Black'
         }
         elseif ($printer -and ($printer).PortName -eq $printers[$key].PortName)
         {
            Write-Host "Port for printer `"$($PrinterArgs.Name)`" has already been changed on server `"$server`"." -ForegroundColor 'Yellow' -BackgroundColor 'Black'
         }
         else
         {
            Write-Host "Something went horribly wrong. Entering debug mode"
            $Host.EnterNestedPrompt()
         }
      }
   }
}
