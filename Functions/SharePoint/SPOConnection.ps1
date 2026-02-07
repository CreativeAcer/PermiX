function Test-PnPModuleAvailable {
    
    # Method 1: Check installed modules (prefer 3.x)
    $moduleInstalled = Get-Module -ListAvailable -Name PnP.PowerShell -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
    
    if ($moduleInstalled) {
        $version = $moduleInstalled.Version
        Write-ActivityLog "PnP module found via Get-Module: Version $version"
        
        # Check if it's modern version
        if ($version -ge [version]"3.0.0") {
            Write-ActivityLog "Modern PnP PowerShell 3.x detected"
            return $true
        } elseif ($version -ge [version]"2.0.0") {
            Write-ActivityLog "Legacy PnP PowerShell 2.x detected - recommend upgrading to 3.x"
            return $true
        } else {
            Write-ActivityLog "Very old PnP PowerShell detected - upgrade required"
            return $false
        }
    }
    
    # Method 2: Try to import
    try {
        Import-Module PnP.PowerShell -ErrorAction Stop
        $importedModule = Get-Module PnP.PowerShell
        if ($importedModule) {
            Write-ActivityLog "PnP module successfully imported: Version $($importedModule.Version)"
            return $true
        }
    }
    catch {
        Write-ActivityLog "PnP module import failed: $($_.Exception.Message)"
    }
    
    # Method 3: Check if key commands are available (modern commands)
    try {
        $modernCommands = @("Connect-PnPOnline", "Get-PnPWeb", "Get-PnPRoleAssignment")
        $availableCommands = 0
        
        foreach ($cmd in $modernCommands) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                $availableCommands++
            }
        }
        
        if ($availableCommands -eq $modernCommands.Count) {
            Write-ActivityLog "All modern PnP commands are available"
            return $true
        } else {
            Write-ActivityLog "Missing $($modernCommands.Count - $availableCommands) key PnP commands"
        }
    }
    catch {
        Write-ActivityLog "PnP commands check failed: $($_.Exception.Message)"
    }
    
    return $false
}

function Install-PnPModule {
    param($UI)

    try {
        $UI.UpdateStatus("Installing modern PnP PowerShell 3.x...`nThis may take a few minutes.")
        
        # Check PowerShell version first
        if ($PSVersionTable.PSVersion.Major -lt 7) {
            throw "PowerShell 7.0 or later is required for modern PnP PowerShell 3.x. Current version: $($PSVersionTable.PSVersion)"
        }
        
        # Remove any legacy versions first
        $UI.UpdateStatus("Cleaning up legacy PnP PowerShell versions...")
        $legacyModules = @("SharePointPnPPowerShellOnline", "PnP.PowerShell")
        
        foreach ($module in $legacyModules) {
            try {
                $installed = Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue
                if ($installed) {
                    $oldVersions = $installed | Where-Object { $_.Version -lt [version]"3.0.0" }
                    if ($oldVersions) {
                        Write-ActivityLog "Removing legacy $module versions: $($oldVersions.Version -join ', ')"
                        Uninstall-Module -Name $module -Force -AllVersions -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
                Write-ActivityLog "Could not remove legacy $module`: $($_.Exception.Message)"
            }
        }
        
        # Check and install NuGet if needed
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nugetProvider -or $nugetProvider.Version -lt [version]"2.8.5.201") {
            $UI.UpdateStatus("Installing NuGet provider...")
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }

        # Install modern PnP PowerShell 3.x
        $UI.UpdateStatus("Installing PnP.PowerShell 3.x...`nPlease wait, this may take several minutes.")
        
        $installParams = @{
            Name = "PnP.PowerShell"
            MinimumVersion = "3.0.0"
            Force = $true
            AllowClobber = $true
            SkipPublisherCheck = $true
            Scope = "CurrentUser"
        }
        
        Install-Module @installParams
        
        # Force refresh and import
        Import-Module PnP.PowerShell -Force -ErrorAction SilentlyContinue
        
        # Verify modern installation
        $installedModule = Get-Module -ListAvailable -Name PnP.PowerShell | 
            Sort-Object Version -Descending | Select-Object -First 1
            
        if (-not $installedModule) {
            throw "PnP PowerShell module installation verification failed"
        }
        
        if ($installedModule.Version -lt [version]"3.0.0") {
            throw "Failed to install modern PnP PowerShell 3.x. Got version $($installedModule.Version) instead."
        }
        
        # Test key modern commands
        $modernCommands = @("Connect-PnPOnline", "Get-PnPWeb", "Get-PnPRoleAssignment", "Get-PnPUser", "Get-PnPGroup")
        $missingCommands = @()
        
        foreach ($cmd in $modernCommands) {
            if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
                $missingCommands += $cmd
            }
        }
        
        if ($missingCommands.Count -gt 0) {
            Write-ActivityLog "Warning: Missing modern commands: $($missingCommands -join ', ')"
        }
        
        $UI.UpdateStatus("✅ Modern PnP PowerShell $($installedModule.Version) installed successfully!`nAll key commands available for enhanced SharePoint analysis.")
        return $true
    }
    catch {
        $UI.UpdateStatus("Error installing modern PnP module: $($_.Exception.Message)")
        throw
    }
}
