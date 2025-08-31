# Generated from spec: E01-F02-T01 (Node.js and Yarn Environment Setup)
# Spec ID: 0768281a

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Windows Node.js & Yarn Installation" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "✓ Chocolatey installed" -ForegroundColor Green
    } else {
        Write-Host "✓ Chocolatey already installed" -ForegroundColor Green
    }
}

function Install-NodeJS {
    Write-Host ""
    Write-Host "Installing Node.js 20 LTS..." -ForegroundColor Yellow
    
    $nodeExists = Get-Command node -ErrorAction SilentlyContinue
    if ($nodeExists) {
        $nodeVersion = node --version
        Write-Host "Node.js already installed: $nodeVersion" -ForegroundColor Cyan
        
        if ($nodeVersion -match "^v20\.") {
            Write-Host "✓ Node.js 20.x already installed" -ForegroundColor Green
            return
        } else {
            Write-Host "Different Node.js version found. Installing Node.js 20 LTS..." -ForegroundColor Yellow
        }
    }
    
    choco install nodejs-lts -y --version=20.0.0
    
    refreshenv
    
    Write-Host "✓ Node.js installed successfully" -ForegroundColor Green
}

function Enable-Corepack {
    Write-Host ""
    Write-Host "Enabling Corepack..." -ForegroundColor Yellow
    
    $corepackExists = Get-Command corepack -ErrorAction SilentlyContinue
    if (!$corepackExists) {
        Write-Host "Installing Corepack..." -ForegroundColor Yellow
        npm install -g corepack
    }
    
    corepack enable
    Write-Host "✓ Corepack enabled" -ForegroundColor Green
}

function Install-Yarn {
    Write-Host ""
    Write-Host "Installing Yarn 4 (Berry)..." -ForegroundColor Yellow
    
    $yarnExists = Get-Command yarn -ErrorAction SilentlyContinue
    if ($yarnExists) {
        $yarnVersion = yarn --version
        Write-Host "Current Yarn version: $yarnVersion" -ForegroundColor Cyan
    }
    
    corepack prepare yarn@stable --activate
    
    yarn set version stable
    
    $yarnVersion = yarn --version
    Write-Host "✓ Yarn $yarnVersion installed" -ForegroundColor Green
}

if (!(Test-Administrator)) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

Install-Chocolatey
Install-NodeJS
Enable-Corepack
Install-Yarn

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Windows installation complete!" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Node.js version: $(node --version)" -ForegroundColor Green
Write-Host "Yarn version: $(yarn --version)" -ForegroundColor Green
Write-Host "npm version: $(npm --version)" -ForegroundColor Green

Write-Host ""
Write-Host "Please restart your terminal or run 'refreshenv' to update PATH" -ForegroundColor Yellow