# Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)
# Spec ID: 021bbc7e
# ================================================================
# PowerShell script to decrypt credentials and run Creon
# ================================================================

param(
    [string]$CredentialsPath = "/secure/creon/credentials/creon_credentials.json",
    [string]$CreonExecutable = "C:\CREON\STARTER\coStarter.exe"
)

Write-Host "🔓 Decrypting Creon credentials..." -ForegroundColor Cyan

try {
    # Check if credentials file exists
    if (-not (Test-Path $CredentialsPath)) {
        throw "Credentials file not found at: $CredentialsPath"
    }
    
    # Load encrypted credentials
    $encryptedCreds = Get-Content $CredentialsPath | ConvertFrom-Json
    
    # Verify this is the same machine
    if ($encryptedCreds.Machine -ne $env:COMPUTERNAME) {
        throw "Credentials were encrypted on a different machine: $($encryptedCreds.Machine)"
    }
    
    # Decrypt passwords (DPAPI)
    $securePassword = ConvertTo-SecureString -String $encryptedCreds.Password
    $secureCertPassword = ConvertTo-SecureString -String $encryptedCreds.CertPassword
    
    # Convert to plain text (only for Creon automation)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureCertPassword)
    $plainCertPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
    
    Write-Host "✅ Credentials decrypted successfully" -ForegroundColor Green
    
    # Set environment variables for auto-login script
    $env:CREON_USERNAME = $encryptedCreds.Username
    $env:CREON_PASSWORD = $plainPassword
    $env:CREON_CERT_PASSWORD = $plainCertPassword
    
    # Launch Creon
    Write-Host "🚀 Launching Creon..." -ForegroundColor Cyan
    Start-Process -FilePath $CreonExecutable -Wait
    
    # Clear sensitive environment variables
    Remove-Item Env:\CREON_USERNAME
    Remove-Item Env:\CREON_PASSWORD
    Remove-Item Env:\CREON_CERT_PASSWORD
    
    Write-Host "✅ Creon session completed" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    
    # Ensure cleanup of sensitive data
    if (Test-Path Env:\CREON_USERNAME) { Remove-Item Env:\CREON_USERNAME }
    if (Test-Path Env:\CREON_PASSWORD) { Remove-Item Env:\CREON_PASSWORD }
    if (Test-Path Env:\CREON_CERT_PASSWORD) { Remove-Item Env:\CREON_CERT_PASSWORD }
    
    exit 1
}