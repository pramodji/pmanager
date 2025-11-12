<#
.SYNOPSIS
    Interactive console tool to display computer information with formatted, color-coded output.
    Shows an animated spinner and a progress bar while information is collected in the background.

.PARAMETER ComputerName
    Name of the computer to query. Defaults to local computer if not specified.

USAGE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\computerinfo.ps1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\computerinfo.ps1 -ComputerName "COMPUTERNAME"
#>

param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]
        $Credential = $null
)

#region Helpers

function Write-Section {
        param(
                [string]$Title
        )
        $line = '-' * ($Title.Length + 2)
        Write-Host ""
        Write-Host " $Title " -ForegroundColor Cyan
        Write-Host " $line" -ForegroundColor DarkGray
}

function Write-KV {
        param(
                [string]$Key,
                [string]$Value,
                [ConsoleColor]$KeyColor = 'Gray',
                [ConsoleColor]$ValueColor = 'White'
        )
        $pad = 26
        $k = $Key.PadRight($pad)
        Write-Host ("{0}" -f $k) -NoNewline -ForegroundColor $KeyColor
        Write-Host ("{0}" -f $Value) -ForegroundColor $ValueColor
}

function Format-Bytes {
        param([double]$bytes)
        if ($bytes -ge 1PB) { "{0:N2} PB" -f ($bytes/1PB) }
        elseif ($bytes -ge 1TB) { "{0:N2} TB" -f ($bytes/1TB) }
        elseif ($bytes -ge 1GB) { "{0:N2} GB" -f ($bytes/1GB) }
        elseif ($bytes -ge 1MB) { "{0:N2} MB" -f ($bytes/1MB) }
        elseif ($bytes -ge 1KB) { "{0:N2} KB" -f ($bytes/1KB) }
        else { "$bytes B" }
}

# thresholds helpers -> choose color based on percent free
function Get-ColorByPercent {
        param([double]$percentFree)
        if ($percentFree -lt 15) { return 'Red' }
        elseif ($percentFree -lt 30) { return 'Yellow' }
        else { return 'Green' }
}

#endregion

#region Background collector
# Pre-check remote access and optionally prompt for credentials
## prefer a provided credential for non-interactive use
$providedCred = $Credential
if ($ComputerName -and $ComputerName -ne $env:COMPUTERNAME) {
        try {
                if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
                        if ($providedCred) {
                                Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $providedCred -ErrorAction Stop | Out-Null
                        } else {
                                Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop | Out-Null
                        }
                } else {
                        if ($providedCred) {
                                Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -Credential $providedCred -ErrorAction Stop | Out-Null
                        } else {
                                Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop | Out-Null
                        }
                }
        } catch {
                $msg = $_.Exception.Message
                if ($msg -match 'Access is denied' -or $_.Exception -is [System.UnauthorizedAccessException]) {
                        Write-Host ("Access denied to {0}. Please provide administrator credentials." -f $ComputerName) -ForegroundColor Yellow
                        # Only prompt interactively if no credential was supplied
                        if (-not $providedCred) {
                                $providedCred = Get-Credential -Message ("Enter admin credentials for {0}" -f $ComputerName)
                        } else {
                                Write-Host "Using provided credential to attempt access." -ForegroundColor Yellow
                        }
                        try {
                                if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
                                        Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $providedCred -ErrorAction Stop | Out-Null
                                } else {
                                        Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -Credential $providedCred -ErrorAction Stop | Out-Null
                                }
                        } catch {
                                Write-Host ("Credential validation failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
                                exit 1
                        }
                } else {
                        Write-Host ("Error contacting {0}: {1}" -f $ComputerName, $msg) -ForegroundColor Red
                        exit 1
                }
        }
}

# Use a background job to gather system information while the main thread shows an animated progress bar
$job = Start-Job -Name "Collect-SystemInfo" -ScriptBlock {
        param($TargetComputer, $TargetCred)
        try {
                $result = [ordered]@{}
                $cimParams = @{ ErrorAction = 'Stop' }
                if ($TargetComputer -and $TargetComputer -ne $env:COMPUTERNAME) {
                        $cimParams['ComputerName'] = $TargetComputer
                }
                if ($TargetCred) { $cimParams['Credential'] = $TargetCred }

                # Basic info
                $os = Get-CimInstance @cimParams -ClassName Win32_OperatingSystem
                $cs = Get-CimInstance @cimParams -ClassName Win32_ComputerSystem

                $result.ComputerName = if ($cimParams.ContainsKey('ComputerName')) { $TargetComputer } else { $env:COMPUTERNAME }
                $result.UserName     = $env:USERNAME
                $result.OS           = "$($os.Caption) ($($os.Version))"
                $result.Build        = $os.BuildNumber
                $result.Architecture = (Get-CimInstance @cimParams -ClassName Win32_Processor | Select-Object -First 1).AddressWidth
                $result.Domain       = $cs.Domain
                $result.LastBootUp   = $os.LastBootUpTime

                # Uptime
                if ($os.LastBootUpTime -is [DateTime]) {
                        $boot = $os.LastBootUpTime
                } else {
                        $boot = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
                }
                $uptime = (Get-Date) - $boot
                $result.Uptime = @{
                        BootTime = $boot
                        Days     = $uptime.Days
                        Hours    = $uptime.Hours
                        Minutes  = $uptime.Minutes
                }

                # CPU
                $cpu = Get-CimInstance @cimParams -ClassName Win32_Processor | Select-Object -First 1
                $result.CPU = @{
                        Name = $cpu.Name.Trim()
                        Cores = $cpu.NumberOfCores
                        LogicalProcessors = $cpu.NumberOfLogicalProcessors
                        MaxClockMHz = $cpu.MaxClockSpeed
                        LoadPercent = ($cpu.LoadPercentage -as [int])
                }

                # Memory
                $totalKb = [double]$os.TotalVisibleMemorySize
                $freeKb  = [double]$os.FreePhysicalMemory
                $totalBytes = $totalKb * 1KB
                $freeBytes  = $freeKb  * 1KB
                $percentFreeMem = if ($totalBytes -gt 0) { [math]::Round(($freeBytes / $totalBytes) * 100, 1) } else { 0 }
                $result.Memory = @{
                        TotalBytes = $totalBytes
                        FreeBytes  = $freeBytes
                        FreePercent = $percentFreeMem
                }

                # Logical disks (fixed drives)
                $disks = Get-CimInstance @cimParams -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
                        [PSCustomObject]@{
                                DeviceID = $_.DeviceID
                                VolumeName = $_.VolumeName
                                FileSystem = $_.FileSystem
                                SizeBytes = if ($_.Size) { [double]$_.Size } else { 0 }
                                FreeBytes = if ($_.FreeSpace) { [double]$_.FreeSpace } else { 0 }
                                FreePercent = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { 0 }
                        }
                }
                $result.Disks = $disks

                # Network adapters with IP
                $nics = Get-CimInstance @cimParams -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | ForEach-Object {
                        [PSCustomObject]@{
                                Description = $_.Description
                                MACAddress  = $_.MACAddress
                                IPAddresses = ($_.IPAddress -join ', ')
                                DefaultIPGateway = ($_.DefaultIPGateway -join ', ')
                                DNSServers = ($_.DNSServerSearchOrder -join ', ')
                        }
                }
                $result.Network = $nics

                # Services summary via WMI (remote-friendly)
                $svcs = Get-CimInstance @cimParams -ClassName Win32_Service | Group-Object -Property State | ForEach-Object {
                        [PSCustomObject]@{ Status = $_.Name; Count = $_.Count }
                }
                $result.Services = $svcs

                # Installed hotfixes via WMI (remote-friendly)
                $hotfixes = Get-CimInstance @cimParams -ClassName Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 10
                $result.HotFixes = $hotfixes

                # Return the assembled object
                return $result
        } catch {
                return @{ Error = $_.Exception.Message }
        }
} -ArgumentList $ComputerName, $providedCred
#endregion

#region Show animated progress while job runs
$spinner = @('|','/','-','\')
$spinIndex = 0
$sw = [Diagnostics.Stopwatch]::StartNew()
$maxWaitSec = 20  # soft cap to allow progress animation to move even if job is slow
$percent = 0

while ($job.State -eq 'Running') {
        # simple heuristic: increase percent slowly over time but never to 100% until the job completes
        if ($percent -lt 95) {
                $percent += Get-Random -Minimum 1 -Maximum 4
                if ($percent -gt 95) { $percent = 95 }
        }

        $status = ("Collecting system info {0}" -f $spinner[$spinIndex % $spinner.Length])
        $sub = ("Elapsed: {0}s" -f [int]$sw.Elapsed.TotalSeconds)
        Write-Progress -Activity "Computer Info" -Status $status -PercentComplete $percent -CurrentOperation $sub

        Start-Sleep -Milliseconds 140
        $spinIndex++

        # safety: if too long, show some movement to reassure user
        if ($sw.Elapsed.TotalSeconds -gt $maxWaitSec) {
                $percent = [math]::Min(95, $percent + 1)
                $maxWaitSec += 5
        }

        # refresh job state
        $job = Get-Job -Id $job.Id
}

# finalize progress
Write-Progress -Activity "Computer Info" -Status "Finalizing..." -PercentComplete 100
Start-Sleep -Milliseconds 250
#endregion

#region Receive results and display formatted output
$result = Receive-Job -Job $job -Wait -AutoRemoveJob

Clear-Host

if ($null -eq $result) {
        Write-Host "No result returned from collector job." -ForegroundColor Red
        exit 1
}
if ($result -is [hashtable] -and $result.ContainsKey('Error')) {
        Write-Host "Error collecting system info: $($result.Error)" -ForegroundColor Red
        exit 1
}

# Header
$title = "Computer Information"
Write-Host ""
Write-Host ("{0}" -f $title) -ForegroundColor Magenta
Write-Host ("{0}" -f ('=' * $title.Length)) -ForegroundColor DarkGray

# Basic
Write-Section "Basic"
Write-KV "Computer Name" $result.ComputerName
Write-KV "User" $result.UserName
Write-KV "Operating System" $result.OS
Write-KV "Build" $result.Build
Write-KV "Architecture" ("{0}-bit" -f $result.Architecture)
Write-KV "Domain" $result.Domain
if ($result.LastBootUp -is [DateTime]) {
        $bootTime = $result.LastBootUp
} else {
        $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($result.LastBootUp)
}
Write-KV "Last Boot" ($bootTime.ToString("yyyy-MM-dd HH:mm:ss"))
$upt = $result.Uptime
Write-KV "Uptime" ("{0}d {1}h {2}m" -f $upt.Days, $upt.Hours, $upt.Minutes) -ValueColor White

# CPU
Write-Section "CPU"
Write-KV "Name" $result.CPU.Name
Write-KV "Cores / Logical" ("{0} / {1}" -f $result.CPU.Cores, $result.CPU.LogicalProcessors)
Write-KV "Max Clock (MHz)" $result.CPU.MaxClockMHz
$cpuLoad = $result.CPU.LoadPercent
$cpuColor = if ($cpuLoad -ge 85) { 'Red' } elseif ($cpuLoad -ge 60) { 'Yellow' } else { 'Green' }
Write-KV "Load (%)" ("{0}%" -f $cpuLoad) 'Gray' $cpuColor

# Memory
Write-Section "Memory"
$mem = $result.Memory
Write-KV "Total" (Format-Bytes $mem.TotalBytes)
Write-KV "Free"  (Format-Bytes $mem.FreeBytes) 'Gray' (Get-ColorByPercent $mem.FreePercent)
Write-KV "Free (%)" ("{0}%" -f $mem.FreePercent) 'Gray' (Get-ColorByPercent $mem.FreePercent)

# Disks
Write-Section "Disks"
if ($result.Disks.Count -eq 0) {
        Write-KV "Drives" "No fixed drives found" 'Gray' 'Yellow'
} else {
        foreach ($d in $result.Disks) {
                $color = Get-ColorByPercent $d.FreePercent
                $label = if ($d.VolumeName) { "$($d.DeviceID) - $($d.VolumeName)" } else { "$($d.DeviceID)" }
                Write-Host ""
                Write-Host (" {0}" -f $label) -ForegroundColor Cyan
                Write-KV "  FileSystem" $d.FileSystem
                Write-KV "  Size" (Format-Bytes $d.SizeBytes)
                Write-KV "  Free" (Format-Bytes $d.FreeBytes) 'Gray' $color
                Write-KV "  Free (%)" ("{0}%" -f $d.FreePercent) 'Gray' $color
        }
}

# Network
Write-Section "Network"
if ($result.Network.Count -eq 0) {
        Write-KV "Adapters" "No IP-enabled adapters found" 'Gray' 'Yellow'
} else {
        foreach ($n in $result.Network) {
                Write-Host ""
                Write-Host (" {0}" -f $n.Description) -ForegroundColor Cyan
                Write-KV "  MAC" $n.MACAddress
                Write-KV "  IP" $n.IPAddresses
                Write-KV "  Gateway" $n.DefaultIPGateway
                Write-KV "  DNS" $n.DNSServers
        }
}

# Services summary
Write-Section "Services (summary)"
foreach ($s in $result.Services) {
        $sc = switch ($s.Status) {
                'Running' { 'Green' }
                'Stopped' { 'DarkGray' }
                'Paused'  { 'Yellow' }
                default   { 'White' }
        }
        Write-KV $s.Status ($s.Count) 'Gray' $sc
}

# Hotfixes
Write-Section "Recent Hotfixes (top 10)"
if ($result.HotFixes.Count -eq 0) {
        Write-KV "Hotfixes" "None found" 'Gray' 'Yellow'
} else {
        foreach ($hf in $result.HotFixes) {
                Write-Host (" {0} - {1}" -f $hf.HotFixID, $hf.InstalledOn.ToString("yyyy-MM-dd")) -ForegroundColor White
                Write-Host ("   Description: {0}" -f $hf.Caption) -ForegroundColor DarkGray
        }
}

Write-Host ""
Write-Host "Completed." -ForegroundColor Green
# keep console open if run double-clicked
if ($Host.Name -eq 'ConsoleHost') {
        Write-Host ""
        Read-Host -Prompt "Press Enter to exit"
}
#endregion