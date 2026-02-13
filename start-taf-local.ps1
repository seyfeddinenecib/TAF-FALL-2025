# TAF Local Testing - Quick Start Script
# This script helps you build and start the TAF system locally

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("full", "minimal", "core", "team1", "team2", "team3", "perf")]
    [string]$Mode = "full",
    
    [switch]$Build,
    [switch]$Clean,
    [switch]$Logs
)

$composeFile = "docker-compose-local-test.yml"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TAF Local Testing - Quick Start" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Clean mode
if ($Clean) {
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    docker compose -f $composeFile down -v
    Write-Host "Cleanup complete!" -ForegroundColor Green
    exit 0
}

# Define service groups
$services = @{
    "full" = @("mongodb", "mysql", "registry", "gateway", "auth", "user", 
               "backend-team1", "backend-team2", "backend-team3",
               "selenium-team1", "selenium-team2", "selenium-team3",
               "frontend-team1", "frontend-team2", "frontend-team3")
    "minimal" = @("mongodb", "registry", "gateway", "auth")
    "core" = @("mongodb", "registry", "gateway", "auth", "user")
    "team1" = @("mongodb", "registry", "gateway", "auth", "backend-team1", "selenium-team1", "frontend-team1")
    "team2" = @("mongodb", "registry", "gateway", "auth", "backend-team2", "selenium-team2", "frontend-team2")
    "team3" = @("mongodb", "registry", "gateway", "auth", "backend-team3", "selenium-team3", "frontend-team3")
    "perf" = @("mongodb", "registry", "gateway", "auth", "backend-team3", "frontend-team3")
}

$selectedServices = $services[$Mode]

Write-Host "Mode: $Mode" -ForegroundColor Cyan
Write-Host "Services to start: $($selectedServices -join ', ')`n" -ForegroundColor Gray

# Build if requested
if ($Build) {
    Write-Host "Building services..." -ForegroundColor Yellow
    Write-Host "This may take 15-30 minutes on first run...`n" -ForegroundColor Gray
    
    docker compose -f $composeFile build $selectedServices
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nBuild failed! Check errors above." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`nBuild complete!" -ForegroundColor Green
}

# Start services
Write-Host "`nStarting services..." -ForegroundColor Yellow

# Start in phases for better reliability
$phase1Services = @("mongodb", "mysql") | Where-Object { $selectedServices -contains $_ }
if ($phase1Services.Count -gt 0) {
    Write-Host "  Phase 1: Starting databases..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $phase1Services
    Start-Sleep -Seconds 10
}

$phase2Services = @("registry") | Where-Object { $selectedServices -contains $_ }
if ($phase2Services.Count -gt 0) {
    Write-Host "  Phase 2: Starting registry..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $phase2Services
    Start-Sleep -Seconds 30
}

$phase3Services = @("gateway", "auth", "user") | Where-Object { $selectedServices -contains $_ }
if ($phase3Services.Count -gt 0) {
    Write-Host "  Phase 3: Starting gateway and core services..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $phase3Services
    Start-Sleep -Seconds 20
}

$backendServices = @("backend-team1", "backend-team2", "backend-team3") | Where-Object { $selectedServices -contains $_ }
if ($backendServices.Count -gt 0) {
    Write-Host "  Phase 4: Starting testing backends..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $backendServices
    
    Start-Sleep -Seconds 20

$seleniumServices = @("selenium-team1", "selenium-team2", "selenium-team3") | Where-Object { $selectedServices -contains $_ }
if ($seleniumServices.Count -gt 0) {
    Write-Host "  Phase 5: Starting Selenium grids..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $seleniumServices
    
    Start-Sleep -Seconds 10
}

$frontendServices = @("frontend-team1", "frontend-team2", "frontend-team3") | Where-Object { $selectedServices -contains $_ }
if ($frontendServices.Count -gt 0) {
    Write-Host "  Phase 6: Starting frontend applications..." -ForegroundColor Gray
    docker compose -f $composeFile up -d $frontendServices
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Services Started!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Show status
Write-Host "Service Status:" -ForegroundColor Cyan
docker compose -f $composeFile ps

Write-Host "`nAccess Points:" -ForegroundColor Cyan
Write-Host "  Eureka Registry: http://localhost:8761 (eureka/eureka)" -ForegroundColor White
Write-Host "  API Gateway:     http://localhost:8080" -ForegroundColor White
Write-Host "  Auth Service:    http://localhost:8081" -ForegroundColor White
Write-Host "  User Service:    http://localhost:8082" -ForegroundColor White

if ($Mode -ne "minimal" -and $Mode -ne "core") {
    switch ($Mode) {
        "perf" {
            Write-Host "  Backend Team 3:  http://localhost:8085" -ForegroundColor White
            Write-Host "  Frontend Team 3: http://localhost:4400" -ForegroundColor Yellow
        }
        "full" {
            Write-Host "  Backend Team 1:  http://localhost:8083" -ForegroundColor White
            Write-Host "  Backend Team 2:  http://localhost:8084" -ForegroundColor White
            Write-Host "  Backend Team 3:  http://localhost:8085" -ForegroundColor White
            Write-Host "  Selenium Team 1: http://localhost:4444" -ForegroundColor White
            Write-Host "  Selenium Team 2: http://localhost:4445" -ForegroundColor White
            Write-Host "  Selenium Team 3: http://localhost:4446" -ForegroundColor White
            Write-Host "  Frontend Team 1: http://localhost:4200" -ForegroundColor Yellow
            Write-Host "  Frontend Team 2: http://localhost:4300" -ForegroundColor Yellow
            Write-Host "  Frontend Team 3: http://localhost:4400" -ForegroundColor Yellow
        }
        "team1" {
            Write-Host "  Backend Team 1:  http://localhost:8083" -ForegroundColor White
            Write-Host "  Selenium Team 1: http://localhost:4444" -ForegroundColor White
            Write-Host "  Frontend Team 1: http://localhost:4200" -ForegroundColor Yellow
        }
        "team2" {
            Write-Host "  Backend Team 2:  http://localhost:8084" -ForegroundColor White
            Write-Host "  Selenium Team 2: http://localhost:4445" -ForegroundColor White
            Write-Host "  Frontend Team 2: http://localhost:4300" -ForegroundColor Yellow
        }
        "team3" {
            Write-Host "  Backend Team 3:  http://localhost:8085" -ForegroundColor White
            Write-Host "  Selenium Team 3: http://localhost:4446" -ForegroundColor White
            Write-Host "  Frontend Team 3: http://localhost:4400" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nUseful Commands:" -ForegroundColor Cyan
Write-Host "  View logs:       docker compose -f $composeFile logs -f" -ForegroundColor Gray
Write-Host "  Stop services:   docker compose -f $composeFile stop" -ForegroundColor Gray
Write-Host "  Restart service: docker compose -f $composeFile restart <service-name>" -ForegroundColor Gray
Write-Host "  Clean up:        .\start-taf-local.ps1 -Clean" -ForegroundColor Gray

if ($Logs) {
    Write-Host "`nShowing logs (Ctrl+C to exit)..." -ForegroundColor Yellow
    docker compose -f $composeFile logs -f
}

Write-Host "`nDone! Services are starting up..." -ForegroundColor Green
Write-Host "Wait 2-3 minutes for all services to be fully ready.`n" -ForegroundColor Yellow


