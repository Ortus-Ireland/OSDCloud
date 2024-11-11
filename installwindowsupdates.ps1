Set-executionpolicy bypass -scope process
Install-Module -Name PSWindowsUpdate -Force
Get-WUList
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
