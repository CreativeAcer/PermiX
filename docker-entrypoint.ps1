<#
.SYNOPSIS
    Container entrypoint - launches web UI
.DESCRIPTION
    Starts the web-based PermiX on port 8080
#>

Write-Host ""
Write-Host "  Starting PermiX (Web UI)" -ForegroundColor Cyan
Write-Host "  Access the UI at: http://localhost:8080" -ForegroundColor Green
Write-Host ""

& /app/Start-SPOTool-Web.ps1 -Port 8080 -ListenAddress "+" -NoBrowser
