# Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)
# Spec ID: 021bbc7e
# ================================================================
# PowerShell script to encrypt Creon credentials
# ================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$Password,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$CertPassword,
    
    [string]$OutputPath = "/secure/creon/credentials/"
)

Write-Host "🔒 Encrypting Creon credentials..." -ForegroundColor Cyan

try {
    # Convert SecureStrings to encrypted strings (DPAPI)
    $encryptedPassword = ConvertFrom-SecureString -SecureString $Password
    $encryptedCertPassword = ConvertFrom-SecureString -SecureString $CertPassword
    
    # Create credentials object
    $credentials = @{
        Username = $Username
        Password = $encryptedPassword
        CertPassword = $encryptedCertPassword
        EncryptedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Machine = $env:COMPUTERNAME
    }
    
    # Save to JSON file
    $outputFile = Join-Path $OutputPath "creon_credentials.json"
    $credentials | ConvertTo-Json | Set-Content -Path $outputFile -Encoding UTF8
    
    # Set restricted permissions
    $acl = Get-Acl $outputFile
    $acl.SetAccessRuleProtection($true, $false)
    $permission = $env:USERNAME, "FullControl", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $outputFile $acl
    
    Write-Host "✅ Credentials encrypted and saved to: $outputFile" -ForegroundColor Green
    Write-Host "⚠️  Note: These credentials can only be decrypted on this machine by this user" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Error encrypting credentials: $_" -ForegroundColor Red
    exit 1
}