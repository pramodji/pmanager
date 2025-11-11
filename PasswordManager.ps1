# FoxPro-Style Password Manager with Enhanced UI
# Full keyboard control with TAB navigation and hotkeys

# Configuration
$script:ConfigFile = ".\pwdmgr.config"
$script:DataFile = ".\passwords.dat"

# Hide/Show cursor
function Hide-Cursor {
    [Console]::CursorVisible = $false
}

# Help screen
function Show-Help {
    Draw-MainHeader
    Hide-Cursor
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                              HELP / SHORTCUTS                              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Common keys:" -ForegroundColor Yellow
    Write-Host "    A  - Add new password" -ForegroundColor White
    Write-Host "    V  - View stored passwords (use arrows + Enter for details)" -ForegroundColor White
    Write-Host "    S  - Search by service/username/URL" -ForegroundColor White
    Write-Host "    E  - Edit a password by ID" -ForegroundColor White
    Write-Host "    D  - Delete a password by ID" -ForegroundColor White
    Write-Host "    X  - Exit the application" -ForegroundColor White
    Write-Host "    H/?- Show this help screen" -ForegroundColor White
    Write-Host ""
    Write-Host "  Tips:" -ForegroundColor Yellow
    Write-Host "    - Use TAB to move between fields in forms." -ForegroundColor White
    Write-Host "    - In forms, press F2 to save (Add/Edit screen)." -ForegroundColor White
    Write-Host "    - Passwords in the console app are stored as plaintext in the JSON file by default." -ForegroundColor Red
    Write-Host "    - For encrypted storage see the WPF app (`PasswordManager1.ps1`) which uses DPAPI." -ForegroundColor White
    Write-Host ""
    Write-Host "  Press any key to return to the main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return
}

function Show-Cursor {
    [Console]::CursorVisible = $true
}

# Initialize configuration
function Initialize-Config {
    if (Test-Path $script:ConfigFile) {
        $config = Get-Content $script:ConfigFile -Raw | ConvertFrom-Json
        $script:DataFile = $config.DataFile
    } else {
        $config = @{ DataFile = $script:DataFile }
        $config | ConvertTo-Json | Out-File $script:ConfigFile
    }
}

# Initialize data file
function Initialize-DataFile {
    if (-not (Test-Path $script:DataFile)) {
        @() | ConvertTo-Json | Out-File $script:DataFile
    }
}

# Load passwords from file
function Get-Passwords {
    if (Test-Path $script:DataFile) {
        $content = Get-Content $script:DataFile -Raw
        if ($content) {
            try {
                return $content | ConvertFrom-Json
            } catch {
                return @()
            }
        }
    }
    return @()
}

# Save passwords to file
function Save-Passwords {
    param($Passwords)
    $Passwords | ConvertTo-Json | Out-File $script:DataFile
}

# Clear screen
function Clear-Screen {
    Clear-Host
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
}

# Draw gradient-style header
function Draw-MainHeader {
    Clear-Screen
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║     ██████╗  █████╗ ███████╗███████╗██╗    ██╗ ██████╗ ██████╗ ██████╗  ║" -ForegroundColor Yellow
    Write-Host "║     ██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔═══██╗██╔══██╗██╔══██╗ ║" -ForegroundColor Yellow
    Write-Host "║     ██████╔╝███████║███████╗███████╗██║ █╗ ██║██║   ██║██████╔╝██║  ██║ ║" -ForegroundColor Yellow
    Write-Host "║     ██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║   ██║██╔══██╗██║  ██║ ║" -ForegroundColor Yellow
    Write-Host "║     ██║     ██║  ██║███████║███████║╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝ ║" -ForegroundColor Yellow
    Write-Host "║     ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝  ║" -ForegroundColor Yellow
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║                  ⚡ Secure Password Management System ⚡                  ║" -ForegroundColor Green
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Main menu with enhanced UI
function Show-MainMenu {
    $menuItems = @(
        @{ Label = "Add New Password"; Hotkey = "A"; Icon = "+" }
        @{ Label = "View Passwords"; Hotkey = "V"; Icon = "*" }
        @{ Label = "Search"; Hotkey = "S"; Icon = "?" }
        @{ Label = "Edit"; Hotkey = "E"; Icon = "~" }
        @{ Label = "Delete"; Hotkey = "D"; Icon = "X" }
        @{ Label = "Exit"; Hotkey = "X"; Icon = "!" }
    )
    
    $selectedIndex = 0
    
    while ($true) {
        Draw-MainHeader
        Hide-Cursor
        
        # Menu box
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                                                                           ║" -ForegroundColor Green
        Write-Host "║                            MAIN MENU                                      ║" -ForegroundColor Yellow
        Write-Host "║                                                                           ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        for ($i = 0; $i -lt $menuItems.Count; $i++) {
            $item = $menuItems[$i]
            $selected = ($i -eq $selectedIndex)
            
            Write-Host "  " -NoNewline
            
            if ($selected) {
                # Selected item with highlight
                Write-Host "┌───────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
                Write-Host "  │ " -ForegroundColor Yellow -NoNewline
                $Host.UI.RawUI.BackgroundColor = "DarkYellow"
                $Host.UI.RawUI.ForegroundColor = "Black"
                Write-Host (" {0}  [{1}]  {2,-52}" -f $item.Icon, $item.Hotkey, $item.Label) -NoNewline
                $Host.UI.RawUI.BackgroundColor = "Black"
                $Host.UI.RawUI.ForegroundColor = "White"
                Write-Host " │" -ForegroundColor Yellow
                Write-Host "  └───────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
            } else {
                # Normal item
                Write-Host "│ " -ForegroundColor Cyan -NoNewline
                Write-Host (" {0}  [{1}]  {2,-52}" -f $item.Icon, $item.Hotkey, $item.Label) -ForegroundColor White -NoNewline
                Write-Host " │" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║ UP/DOWN: Navigate  │  ENTER: Select  │  HOTKEY: Quick Access  │  ?/H: Help │  ESC: Exit ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selectedIndex = ($selectedIndex - 1)
                if ($selectedIndex -lt 0) { $selectedIndex = $menuItems.Count - 1 }
            }
            40 { # Down arrow
                $selectedIndex = ($selectedIndex + 1) % $menuItems.Count
            }
            13 { # Enter
                switch ($selectedIndex) {
                    0 { Add-Password }
                    1 { View-Passwords }
                    2 { Search-Password }
                    3 { Edit-Password }
                    4 { Delete-Password }
                    5 { return "EXIT" }
                }
            }
            27 { # ESC
                return "EXIT"
            }
            default {
                # Check for hotkeys
                $char = $key.Character.ToString().ToUpper()
                switch ($char) {
                    "A" { Add-Password }
                    "V" { View-Passwords }
                    "S" { Search-Password }
                    "E" { Edit-Password }
                    "D" { Delete-Password }
                    "H" { Show-Help }
                    "?" { Show-Help }
                    "X" { return "EXIT" }
                }
            }
        }
    }
}

# Add password with enhanced form UI
function Add-Password {
    Draw-MainHeader
    
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                                                           ║" -ForegroundColor Magenta
    Write-Host "║                        ADD NEW PASSWORD                                   ║" -ForegroundColor Yellow
    Write-Host "║                                                                           ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    $fields = @{
        Service = ""
        Username = ""
        Password = ""
        URL = ""
        Notes = ""
    }
    
    $fieldNames = @("Service", "Username", "Password", "URL", "Notes")
    $fieldLabels = @("Service/Website", "Username", "Password", "URL (optional)", "Notes (optional)")
    $currentField = 0
    
    while ($true) {
        # Redraw form
        [Console]::SetCursorPosition(0, 13)
        Hide-Cursor
        
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $fieldNames.Count; $i++) {
            $fname = $fieldNames[$i]
            $flabel = $fieldLabels[$i]
            $selected = ($i -eq $currentField)
            
            if ($selected) {
                Write-Host "  ║ " -ForegroundColor Cyan -NoNewline
                Write-Host ">> " -ForegroundColor Yellow -NoNewline
                $Host.UI.RawUI.BackgroundColor = "DarkCyan"
                $Host.UI.RawUI.ForegroundColor = "White"
                Write-Host ("{0,-18}" -f $flabel) -NoNewline
                $Host.UI.RawUI.BackgroundColor = "Black"
                Write-Host " : " -ForegroundColor Cyan -NoNewline
                
                if ($fname -eq "Password" -and $fields[$fname]) {
                    Write-Host ("{0,-45}" -f ("*" * [Math]::Min(45, $fields[$fname].Length))) -ForegroundColor Green -NoNewline
                } else {
                    Write-Host ("{0,-45}" -f $fields[$fname]) -ForegroundColor White -NoNewline
                }
                Write-Host " ║" -ForegroundColor Cyan
            } else {
                Write-Host "  ║    " -ForegroundColor Cyan -NoNewline
                Write-Host ("{0,-18}" -f $flabel) -ForegroundColor DarkGray -NoNewline
                Write-Host " : " -ForegroundColor Cyan -NoNewline
                
                if ($fname -eq "Password" -and $fields[$fname]) {
                    Write-Host ("{0,-45}" -f ("*" * [Math]::Min(45, $fields[$fname].Length))) -ForegroundColor DarkGreen -NoNewline
                } else {
                    Write-Host ("{0,-45}" -f $fields[$fname]) -ForegroundColor Gray -NoNewline
                }
                Write-Host " ║" -ForegroundColor Cyan
            }
        }
        
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
        Write-Host "║ TAB: Next │ SHIFT+TAB: Previous │ ENTER: Edit Field │ F2: Save │ ESC: Cancel ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            9 { # TAB
                if ($key.ControlKeyState -band 0x0010) { # Shift key pressed
                    $currentField = ($currentField - 1)
                    if ($currentField -lt 0) { $currentField = $fieldNames.Count - 1 }
                } else {
                    $currentField = ($currentField + 1) % $fieldNames.Count
                }
            }
            13 { # Enter - Edit field
                $fname = $fieldNames[$currentField]
                $flabel = $fieldLabels[$currentField]
                Write-Host ""
                Write-Host "  ┌─────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
                Write-Host "  │ " -ForegroundColor Yellow -NoNewline
                Show-Cursor
                Write-Host "Enter $flabel" -ForegroundColor White -NoNewline
                Write-Host ": " -ForegroundColor Yellow -NoNewline
                
                if ($fname -eq "Password") {
                    $securePass = Read-Host -AsSecureString
                    $fields[$fname] = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
                } else {
                    $fields[$fname] = Read-Host
                }
                Hide-Cursor
                Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
            }
            113 { # F2 - Save
                if ([string]::IsNullOrWhiteSpace($fields["Service"])) {
                    Write-Host ""
                    Write-Host "  ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
                    Write-Host "  ║  ERROR: Service name is required!                              ║" -ForegroundColor Red
                    Write-Host "  ╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                $passwords = Get-Passwords
                $maxId = 0
                if ($passwords -and $passwords.Count -gt 0) {
                    $maxId = ($passwords | Measure-Object -Property ID -Maximum).Maximum
                }
                
                $newEntry = [PSCustomObject]@{
                    ID = $maxId + 1
                    Service = $fields["Service"]
                    Username = $fields["Username"]
                    Password = $fields["Password"]
                    URL = $fields["URL"]
                    Notes = $fields["Notes"]
                    DateCreated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    DateModified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                if (-not $passwords) { $passwords = @() }
                $passwords = @($passwords) + $newEntry
                Save-Passwords -Passwords $passwords
                
                Write-Host ""
                Write-Host "  ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "  ║  SUCCESS: Password saved! ID: $($newEntry.ID)                               ║" -ForegroundColor Green
                Write-Host "  ╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host ""
                Write-Host "  Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            27 { # ESC
                return
            }
        }
    }
}

# View passwords with enhanced list UI
function View-Passwords {
    $passwords = @(Get-Passwords)
    
    if ($passwords.Count -eq 0) {
        Draw-MainHeader
        Hide-Cursor
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                          PASSWORD LIST                                    ║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  ╔═════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║                                                                     ║" -ForegroundColor Red
        Write-Host "  ║       No passwords stored yet. Add one to get started!             ║" -ForegroundColor Red
        Write-Host "  ║                                                                     ║" -ForegroundColor Red
        Write-Host "  ╚═════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $selectedIndex = 0
    
    while ($true) {
        Draw-MainHeader
        Hide-Cursor
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                          PASSWORD LIST                                    ║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  ╔════╦════════════════════════════════════╦═══════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║ ID ║ Service                            ║ Username                  ║" -ForegroundColor Yellow
        Write-Host "  ╠════╬════════════════════════════════════╬═══════════════════════════╣" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $passwords.Count; $i++) {
            $pwd = $passwords[$i]
            $selected = ($i -eq $selectedIndex)
            
            $svc = $pwd.Service.Substring(0, [Math]::Min(36, $pwd.Service.Length))
            $usr = $pwd.Username.Substring(0, [Math]::Min(25, $pwd.Username.Length))
            
            if ($selected) {
                Write-Host "  ║ " -ForegroundColor Cyan -NoNewline
                $Host.UI.RawUI.BackgroundColor = "DarkBlue"
                $Host.UI.RawUI.ForegroundColor = "White"
                Write-Host ("{0,2} ║ {1,-36} ║ {2,-25}" -f $pwd.ID, $svc, $usr) -NoNewline
                $Host.UI.RawUI.BackgroundColor = "Black"
                Write-Host " ║" -ForegroundColor Cyan
            } else {
                Write-Host "  ║ " -ForegroundColor Cyan -NoNewline
                Write-Host ("{0,2}" -f $pwd.ID) -ForegroundColor White -NoNewline
                Write-Host " ║ " -ForegroundColor Cyan -NoNewline
                Write-Host ("{0,-36}" -f $svc) -ForegroundColor White -NoNewline
                Write-Host " ║ " -ForegroundColor Cyan -NoNewline
                Write-Host ("{0,-25}" -f $usr) -ForegroundColor Gray -NoNewline
                Write-Host " ║" -ForegroundColor Cyan
            }
        }
        
        Write-Host "  ╚════╩════════════════════════════════════╩═══════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Total Passwords: $($passwords.Count)" -ForegroundColor Green
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
        Write-Host "║ UP/DOWN: Navigate  │  ENTER: View Details  │  ESC: Back                    ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up
                $selectedIndex = ($selectedIndex - 1)
                if ($selectedIndex -lt 0) { $selectedIndex = $passwords.Count - 1 }
            }
            40 { # Down
                $selectedIndex = ($selectedIndex + 1) % $passwords.Count
            }
            13 { # Enter
                Show-PasswordDetail -Password $passwords[$selectedIndex]
            }
            27 { # ESC
                return
            }
        }
    }
}

# Show password detail with enhanced UI
function Show-PasswordDetail {
    param($Password)
    Draw-MainHeader
    Hide-Cursor

    # Show masked password by default and allow toggling with 'P'
    $showPlain = $false

    while ($true) {
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                       PASSWORD DETAILS                                    ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  ID:          " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.ID) -ForegroundColor White -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Service:     " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.Service) -ForegroundColor White -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Username:    " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.Username) -ForegroundColor Cyan -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Password:    " -ForegroundColor Yellow -NoNewline
        if ($showPlain) {
            Write-Host (("{0,-55}" -f $Password.Password)) -ForegroundColor Green -NoNewline
        } else {
            $mask = "".PadLeft([Math]::Min(45, ($Password.Password).Length), '*')
            Write-Host (("{0,-55}" -f $mask)) -ForegroundColor DarkGreen -NoNewline
        }
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  URL:         " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.URL) -ForegroundColor White -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Notes:       " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.Notes) -ForegroundColor White -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Created:     " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.DateCreated) -ForegroundColor Gray -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ║  Modified:    " -ForegroundColor Yellow -NoNewline
        Write-Host ("{0,-55}" -f $Password.DateModified) -ForegroundColor Gray -NoNewline
        Write-Host " ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Press [P] to toggle password visibility | Press any other key to return" -ForegroundColor Cyan

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $ch = $key.Character.ToString().ToUpper()
        if ($ch -eq "P") {
            $showPlain = -not $showPlain
            Clear-Screen
            Draw-MainHeader
            Hide-Cursor
            continue
        }

        break
    }

    return
}

# Search password
function Search-Password {
    Draw-MainHeader
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                         SEARCH PASSWORD                                   ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  Enter search term (service, username, or URL):                      ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  >> " -ForegroundColor Yellow -NoNewline
    Show-Cursor
    $searchTerm = Read-Host
    Hide-Cursor
    
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        return
    }
    
    $passwords = @(Get-Passwords)
    $results = @($passwords | Where-Object { 
        $_.Service -like "*$searchTerm*" -or 
        $_.Username -like "*$searchTerm*" -or 
        $_.URL -like "*$searchTerm*"
    })
    
    if ($results.Count -eq 0) {
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║  No matches found for '$searchTerm'                                    " -ForegroundColor Red -NoNewline
        Write-Host "║" -ForegroundColor Red
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Draw-MainHeader
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    SEARCH RESULTS                                         ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Search: '$searchTerm' | Found: $($results.Count) match(es)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ╔════╦════════════════════════════════════╦═══════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║ ID ║ Service                            ║ Username                  ║" -ForegroundColor Yellow
    Write-Host "  ╠════╬════════════════════════════════════╬═══════════════════════════╣" -ForegroundColor Cyan
    
    foreach ($pwd in $results) {
        $svc = $pwd.Service.Substring(0, [Math]::Min(36, $pwd.Service.Length))
        $usr = $pwd.Username.Substring(0, [Math]::Min(25, $pwd.Username.Length))
        
        Write-Host "  ║ " -ForegroundColor Cyan -NoNewline
        Write-Host ("{0,2}" -f $pwd.ID) -ForegroundColor White -NoNewline
        Write-Host " ║ " -ForegroundColor Cyan -NoNewline
        Write-Host ("{0,-36}" -f $svc) -ForegroundColor White -NoNewline
        Write-Host " ║ " -ForegroundColor Cyan -NoNewline
        Write-Host ("{0,-25}" -f $usr) -ForegroundColor Yellow -NoNewline
        Write-Host " ║" -ForegroundColor Cyan
    }
    
    Write-Host "  ╚════╩════════════════════════════════════╩═══════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Edit password
function Edit-Password {
    Draw-MainHeader
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                         EDIT PASSWORD                                     ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  Enter password ID to edit:                                           ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  >> " -ForegroundColor Yellow -NoNewline
    Show-Cursor
    $id = Read-Host
    Hide-Cursor
    
    $passwords = @(Get-Passwords)
    $pwd = $passwords | Where-Object { $_.ID -eq [int]$id }
    
    if (-not $pwd) {
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║  ERROR: Password ID not found!                                        ║" -ForegroundColor Red
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Edit form
    $fields = @{
        Service = $pwd.Service
        Username = $pwd.Username
        Password = $pwd.Password
        URL = $pwd.URL
        Notes = $pwd.Notes
    }
    
    $fieldNames = @("Service", "Username", "Password", "URL", "Notes")
    $fieldLabels = @("Service/Website", "Username", "Password", "URL", "Notes")
    $currentField = 0
    
    while ($true) {
        Draw-MainHeader
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
        Write-Host "║                    EDIT PASSWORD - ID: $id                                  " -ForegroundColor Magenta -NoNewline
        Write-Host "║" -ForegroundColor Magenta
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
        Write-Host ""
        Hide-Cursor
        
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $fieldNames.Count; $i++) {
            $fname = $fieldNames[$i]
            $flabel = $fieldLabels[$i]
            $selected = ($i -eq $currentField)
            
            if ($selected) {
                Write-Host "  ║ " -ForegroundColor Cyan -NoNewline
                Write-Host ">> " -ForegroundColor Yellow -NoNewline
                $Host.UI.RawUI.BackgroundColor = "DarkMagenta"
                $Host.UI.RawUI.ForegroundColor = "White"
                Write-Host ("{0,-18}" -f $flabel) -NoNewline
                $Host.UI.RawUI.BackgroundColor = "Black"
                Write-Host " : " -ForegroundColor Cyan -NoNewline
                
                if ($fname -eq "Password" -and $fields[$fname]) {
                    Write-Host ("{0,-45}" -f ("*" * [Math]::Min(45, $fields[$fname].Length))) -ForegroundColor Green -NoNewline
                } else {
                    Write-Host ("{0,-45}" -f $fields[$fname]) -ForegroundColor White -NoNewline
                }
                Write-Host " ║" -ForegroundColor Cyan
            } else {
                Write-Host "  ║    " -ForegroundColor Cyan -NoNewline
                Write-Host ("{0,-18}" -f $flabel) -ForegroundColor DarkGray -NoNewline
                Write-Host " : " -ForegroundColor Cyan -NoNewline
                
                if ($fname -eq "Password" -and $fields[$fname]) {
                    Write-Host ("{0,-45}" -f ("*" * [Math]::Min(45, $fields[$fname].Length))) -ForegroundColor DarkGreen -NoNewline
                } else {
                    Write-Host ("{0,-45}" -f $fields[$fname]) -ForegroundColor Gray -NoNewline
                }
                Write-Host " ║" -ForegroundColor Cyan
            }
        }
        
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
        Write-Host "║ TAB: Next │ ENTER: Edit Field │ F2: Save Changes │ ESC: Cancel             ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            9 { # TAB
                if ($key.ControlKeyState -band 0x0010) { # Shift key pressed
                    $currentField = ($currentField - 1)
                    if ($currentField -lt 0) { $currentField = $fieldNames.Count - 1 }
                } else {
                    $currentField = ($currentField + 1) % $fieldNames.Count
                }
            }
            13 { # Enter
                $fname = $fieldNames[$currentField]
                $flabel = $fieldLabels[$currentField]
                Write-Host ""
                Write-Host "  ┌─────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
                Write-Host "  │ " -ForegroundColor Yellow -NoNewline
                Show-Cursor
                Write-Host "New $flabel (blank to keep current)" -ForegroundColor White -NoNewline
                Write-Host ": " -ForegroundColor Yellow -NoNewline
                
                if ($fname -eq "Password") {
                    $securePass = Read-Host -AsSecureString
                    $newVal = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
                } else {
                    $newVal = Read-Host
                }
                Hide-Cursor
                
                if (-not [string]::IsNullOrWhiteSpace($newVal)) {
                    $fields[$fname] = $newVal
                }
                Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
            }
            113 { # F2
                $pwd.Service = $fields["Service"]
                $pwd.Username = $fields["Username"]
                $pwd.Password = $fields["Password"]
                $pwd.URL = $fields["URL"]
                $pwd.Notes = $fields["Notes"]
                $pwd.DateModified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                
                Save-Passwords -Passwords $passwords
                
                Write-Host ""
                Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "  ║  SUCCESS: Password updated!                                           ║" -ForegroundColor Green
                Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host ""
                Write-Host "  Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            27 { # ESC
                return
            }
        }
    }
}

# Delete password
function Delete-Password {
    Draw-MainHeader
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                        DELETE PASSWORD                                    ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  Enter password ID to delete:                                         ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  >> " -ForegroundColor Yellow -NoNewline
    Show-Cursor
    $id = Read-Host
    Hide-Cursor
    
    $passwords = @(Get-Passwords)
    $pwd = $passwords | Where-Object { $_.ID -eq [int]$id }
    
    if (-not $pwd) {
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║  ERROR: Password ID not found!                                        ║" -ForegroundColor Red
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  Password details:                                                    ║" -ForegroundColor Yellow
    Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
    Write-Host "  ║  Service:  " -ForegroundColor Yellow -NoNewline
    Write-Host ("{0,-59}" -f $pwd.Service) -ForegroundColor White -NoNewline
    Write-Host " ║" -ForegroundColor Yellow
    Write-Host "  ║  Username: " -ForegroundColor Yellow -NoNewline
    Write-Host ("{0,-59}" -f $pwd.Username) -ForegroundColor Cyan -NoNewline
    Write-Host " ║" -ForegroundColor Yellow
    Write-Host "  ║                                                                       ║" -ForegroundColor Yellow
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║  WARNING: This action cannot be undone!                               ║" -ForegroundColor Red
    Write-Host "  ║                                                                       ║" -ForegroundColor Red
    Write-Host "  ║  Are you sure you want to delete this password?                      ║" -ForegroundColor Red
    Write-Host "  ║                                                                       ║" -ForegroundColor Red
    Write-Host "  ║  Press [Y] to confirm  |  Press [N] to cancel                        ║" -ForegroundColor Red
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "  >> " -ForegroundColor Yellow -NoNewline
    
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    if ($key.Character.ToString().ToUpper() -eq "Y") {
        $passwords = @($passwords | Where-Object { $_.ID -ne [int]$id })
        Save-Passwords -Passwords $passwords
        Write-Host ""
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║  SUCCESS: Password deleted!                                           ║" -ForegroundColor Green
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "  ║  INFO: Deletion cancelled. Password was not deleted.                  ║" -ForegroundColor Yellow
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 2
}

# Main program entry point
Clear-Screen
Write-Host ""
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "║          ██████╗  █████╗ ███████╗███████╗██╗    ██╗ ██████╗              ║" -ForegroundColor Yellow
Write-Host "║          ██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔═══██╗             ║" -ForegroundColor Yellow
Write-Host "║          ██████╔╝███████║███████╗███████╗██║ █╗ ██║██║   ██║             ║" -ForegroundColor Yellow
Write-Host "║          ██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║   ██║             ║" -ForegroundColor Yellow
Write-Host "║          ██║     ██║  ██║███████║███████║╚███╔███╔╝╚██████╔╝             ║" -ForegroundColor Yellow
Write-Host "║          ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝              ║" -ForegroundColor Yellow
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "║                 MANAGER - FOXPRO STYLE INTERFACE                          ║" -ForegroundColor Green
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "║                      Initializing system...                               ║" -ForegroundColor White
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Initialize-Config
Initialize-DataFile

Start-Sleep -Seconds 1

$result = Show-MainMenu

if ($result -eq "EXIT") {
    Clear-Screen
    Write-Host ""
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║              ████████╗██╗  ██╗ █████╗ ███╗   ██╗██╗  ██╗                 ║" -ForegroundColor Green
    Write-Host "║              ╚══██╔══╝██║  ██║██╔══██╗████╗  ██║██║ ██╔╝                 ║" -ForegroundColor Green
    Write-Host "║                 ██║   ███████║███████║██╔██╗ ██║█████╔╝                  ║" -ForegroundColor Green
    Write-Host "║                 ██║   ██╔══██║██╔══██║██║╚██╗██║██╔═██╗                  ║" -ForegroundColor Green
    Write-Host "║                 ██║   ██║  ██║██║  ██║██║ ╚████║██║  ██╗                 ║" -ForegroundColor Green
    Write-Host "║                 ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝                 ║" -ForegroundColor Green
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║              Thank you for using Password Manager!                       ║" -ForegroundColor Yellow
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║                  Your passwords are secure!                               ║" -ForegroundColor Green
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ""
    Show-Cursor
}