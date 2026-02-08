#Requires -Version 7.0
<#
.SYNOPSIS
    Install prerequisites for SharePoint Online Permissions Report Tool (PowerShell 7 + Modern PnP)
.DESCRIPTION
    Updated installer for PowerShell 7 with modern PnP PowerShell 3.x
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("CurrentUser", "AllUsers")]
    [string]$Scope = "CurrentUser",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "SharePoint Online Permissions Report Tool" -ForegroundColor Green
Write-Host "Modern Prerequisites Installer (PowerShell 7 + PnP 3.x)" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Gray

# Check PowerShell version - require PowerShell 7+
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $psVersion ($($PSVersionTable.PSEdition))" -ForegroundColor Cyan

if ($psVersion.Major -lt 7) {
    Write-Error "PowerShell 7.0 or later is required for modern PnP PowerShell 3.x"
    Write-Host "`nCurrent version: $psVersion" -ForegroundColor Red
    Write-Host "Please upgrade to PowerShell 7:" -ForegroundColor Yellow
    Write-Host "• Download from: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor White
    Write-Host "• Or run: winget install Microsoft.PowerShell" -ForegroundColor White
    exit 1
}

Write-Host "✓ PowerShell version check passed!" -ForegroundColor Green
Write-Host "✓ PowerShell edition: $($PSVersionTable.PSEdition)" -ForegroundColor Green

# Clean up any old PnP versions first
Write-Host "`nCleaning up legacy PnP PowerShell versions..." -ForegroundColor Yellow

$legacyModules = @(
    "SharePointPnPPowerShellOnline",
    "PnP.PowerShell"
)

foreach ($module in $legacyModules) {
    try {
        $installedVersions = Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue
        if ($installedVersions) {
            Write-Host "Found $module versions: $($installedVersions.Version -join ', ')" -ForegroundColor Gray
            
            if ($Force -or $installedVersions.Version -lt [version]"3.0.0") {
                Write-Host "Removing $module..." -ForegroundColor Yellow
                Uninstall-Module -Name $module -AllVersions -Force -ErrorAction SilentlyContinue
                Write-Host "✓ Removed $module" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Note: Could not remove $module - $($_.Exception.Message)" -ForegroundColor Gray
    }
}

# Required modules configuration for modern setup
$requiredModules = @(
    @{
        Name = "PnP.PowerShell"
        MinVersion = "3.0.0"
        Description = "Modern PnP PowerShell for SharePoint Online (3.x series)"
        Required = $true
        PowerShellVersion = "7.0"
    },
    @{
        Name = "ImportExcel"
        MinVersion = "7.8.0"
        Description = "Enhanced Excel export capabilities"
        Required = $false
        PowerShellVersion = "5.1"
    },
    @{
        Name = "Microsoft.Graph.Authentication"
        MinVersion = "1.0.0"
        Description = "Microsoft Graph authentication (if needed for advanced features)"
        Required = $false
        PowerShellVersion = "7.0"
    }
)

Write-Host "`nInstalling required PowerShell modules..." -ForegroundColor Yellow
Write-Host "Scope: $Scope" -ForegroundColor Gray
Write-Host "PowerShell: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor Gray

foreach ($module in $requiredModules) {
    Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
    Write-Host "Processing module: $($module.Name)" -ForegroundColor Cyan
    Write-Host "Description: $($module.Description)" -ForegroundColor Gray
    Write-Host "Required: $($module.Required)" -ForegroundColor Gray
    Write-Host "Min Version: $($module.MinVersion)" -ForegroundColor Gray
    
    try {
        # Check PowerShell version requirement
        if ([version]$PSVersionTable.PSVersion -lt [version]$module.PowerShellVersion) {
            Write-Host "⚠️ Skipping $($module.Name) - requires PowerShell $($module.PowerShellVersion)" -ForegroundColor Yellow
            continue
        }
        
        # Check if module is already installed
        $installedModule = Get-Module -Name $module.Name -ListAvailable | 
            Sort-Object Version -Descending | Select-Object -First 1
        
        if ($installedModule) {
            Write-Host "Current version: $($installedModule.Version)" -ForegroundColor Gray
            
            if ([version]$installedModule.Version -ge [version]$module.MinVersion) {
                if (-not $Force) {
                    Write-Host "✓ Module meets minimum version requirement" -ForegroundColor Green
                    continue
                } else {
                    Write-Host "Force flag specified - reinstalling..." -ForegroundColor Yellow
                }
            } else {
                Write-Host "⚡ Module version below minimum requirement" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Module not found - installing..." -ForegroundColor Yellow
        }
        
        # Install or update module
        $installParams = @{
            Name = $module.Name
            Force = $Force
            AllowClobber = $true
            Scope = $Scope
            SkipPublisherCheck = $true
        }
        
        if ($module.MinVersion) {
            $installParams.MinimumVersion = $module.MinVersion
        }
        
        Write-Host "Installing $($module.Name)..." -ForegroundColor Yellow
        Install-Module @installParams
        
        # Verify installation
        $newModule = Get-Module -Name $module.Name -ListAvailable | 
            Sort-Object Version -Descending | Select-Object -First 1
        
        if ($newModule) {
            Write-Host "✅ Successfully installed: $($newModule.Version)" -ForegroundColor Green
            
            # Test import for critical modules
            if ($module.Name -eq "PnP.PowerShell") {
                try {
                    Write-Host "Testing PnP PowerShell import..." -ForegroundColor Gray
                    Import-Module PnP.PowerShell -Force -ErrorAction Stop
                    $pnpCommands = Get-Command -Module PnP.PowerShell | Measure-Object
                    Write-Host "✅ PnP PowerShell loaded successfully ($($pnpCommands.Count) commands available)" -ForegroundColor Green
                    
                    # Test key commands
                    $keyCommands = @("Connect-PnPOnline", "Get-PnPWeb", "Get-PnPUser", "Get-PnPGroup", "Get-PnPRoleAssignment")
                    $missingCommands = @()
                    
                    foreach ($cmd in $keyCommands) {
                        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
                            $missingCommands += $cmd
                        }
                    }
                    
                    if ($missingCommands.Count -eq 0) {
                        Write-Host "✅ All key PnP commands available" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️ Missing commands: $($missingCommands -join ', ')" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "⚠️ PnP PowerShell import test failed: $_" -ForegroundColor Yellow
                }
            }
        } else {
            throw "Module installation verification failed"
        }
    }
    catch {
        if ($module.Required) {
            Write-Host "❌ Failed to install required module: $($module.Name)" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            Write-Error "Installation of required module failed. Cannot continue."
            exit 1
        } else {
            Write-Host "⚠️ Failed to install optional module: $($module.Name)" -ForegroundColor Yellow
            Write-Host "Error: $_" -ForegroundColor Yellow
            Write-Host "This module is optional and the application will work without it." -ForegroundColor Gray
        }
    }
}

# Create project directories
Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
Write-Host "Setting up project directories..." -ForegroundColor Yellow
$directories = @(".\Logs", ".\Reports\Generated", ".\Logs\PermissionsAnalysis")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Gray
    }
}

# Final verification
Write-Host "`nFinal verification..." -ForegroundColor Yellow
$finalModules = Get-Module -Name "PnP.PowerShell" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

Write-Host "`nInstallation Summary:" -ForegroundColor Green
Write-Host "=" * 30 -ForegroundColor Gray

if ($finalModules) {
    Write-Host "✅ PnP PowerShell Version: $($finalModules.Version)" -ForegroundColor Green
    $isPnP3x = $finalModules.Version -ge [version]"3.0.0"
    Write-Host "✅ Modern PnP (3.x): $(if ($isPnP3x) { 'Yes' } else { 'No - Please upgrade' })" -ForegroundColor $(if ($isPnP3x) { 'Green' } else { 'Red' })
    Write-Host "✅ PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "✅ PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Green
    Write-Host "✅ Compatible Setup: $(if ($isPnP3x -and $PSVersionTable.PSVersion.Major -ge 7) { 'Yes' } else { 'Upgrade needed' })" -ForegroundColor $(if ($isPnP3x -and $PSVersionTable.PSVersion.Major -ge 7) { 'Green' } else { 'Yellow' })
} else {
    Write-Host "❌ PnP PowerShell: Not installed or not found" -ForegroundColor Red
}

Write-Host "`nModern Features Available:" -ForegroundColor Cyan
Write-Host "• Enhanced role assignment analysis" -ForegroundColor White
Write-Host "• Advanced user and group enumeration" -ForegroundColor White
Write-Host "• List and library security assessment" -ForegroundColor White
Write-Host "• Site feature and configuration analysis" -ForegroundColor White
Write-Host "• Improved error handling and diagnostics" -ForegroundColor White

Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Edit Config\Settings.json with your SharePoint tenant details" -ForegroundColor White
Write-Host "2. Run Start-SPOTool-Web.ps1 to launch the web interface" -ForegroundColor White
Write-Host "3. Use modern app registration authentication" -ForegroundColor White
Write-Host "4. Try Demo Mode to test all features" -ForegroundColor White

if ($finalModules -and $finalModules.Version -ge [version]"3.0.0") {
    Write-Host "`n🚀 Ready for modern SharePoint permissions analysis!" -ForegroundColor Green
    Write-Host "Your setup includes:" -ForegroundColor Gray
    Write-Host "• PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor Gray
    Write-Host "• PnP PowerShell $($finalModules.Version) (Modern 3.x)" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️ Please ensure PnP PowerShell 3.x is properly installed" -ForegroundColor Yellow
}

Write-Host "`nFor support and documentation, see README.md" -ForegroundColor Gray