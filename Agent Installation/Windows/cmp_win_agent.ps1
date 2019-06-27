# ========================================================================
# Name		= cmp_win_agent.ps1
# Company	= Exponential-e Ltd
# Purpose	= Configure Exponential-e's Cloud Management Platform Agent
# Date		= 07/02/2017
# Version	= 1.0
# ========================================================================

$apiKey = "add VM apiKey here"
$applianceUrl = "https://multicloud.exponential-e.com/""

$client = New-Object System.Net.WebClient
$client.DownloadFile($applianceUrl + "/msi/morpheus-agent/MorpheusAgentSetup.msi", "C:\Program Files (x86)\Common Files\MorpheusAgentSetup.msi")
Start-Sleep -Seconds 10
cd ${env:commonprogramfiles(x86)}
$serviceName = "Morpheus Windows Agent"
if(Get-Service $serviceName -ErrorAction SilentlyContinue) {
Stop-Service -displayname $serviceName -ErrorAction SilentlyContinue
Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
Start-Sleep -s 5
$serviceId = (get-wmiobject Win32_Product -Filter "Name = 'Morpheus Windows Agent'" | Format-Wide -Property IdentifyingNumber | Out-String).Trim()
cmd.exe /c "msiexec /x $serviceId /q"
}
[Console]::Out.Flush()
[gc]::collect()
try {
Write-VolumeCache C
}
Catch {
}
$MSIArguments= @(
"/i"
"MorpheusAgentSetup.msi"
"/qn"
"/norestart"
"/l*v"
"morpheus_install.log"
"apiKey=$apiKey"
"host=$applianceUrl"
"username=`".\LocalSystem`""
"vmMode=`"true`""
"logLevel=`"1`""
)
$installResults = Start-Process msiexec.exe -Verb runAs -Wait -ArgumentList $MSIArguments
[Console]::Out.Flush()
[gc]::collect()
try {
Write-VolumeCache C
}
Catch {
}
start-sleep -s 10
$attempts = 0
Do {
try {
        Get-Service $serviceName -ea silentlycontinue -ErrorVariable err
        if([string]::isNullOrEmpty($err)) {
                Break
        } else {
                start-sleep -s 10
                $attempts++
        }
}
Catch {
        start-sleep -s 10
        $attempts++
}
}
While ($attempts -ne 6)
Set-Service $serviceName -startuptype "automatic"
$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
if ($service -And $service.State -ne "Running") {Restart-Service -displayname $serviceName}
exit $installResults.ExitCode