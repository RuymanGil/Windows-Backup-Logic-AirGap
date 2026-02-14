# 1. Verificar existencia y grupos
Get-LocalUser -Name "Svc_BackupAdmin" | Select-Object Name, Enabled, Description
Get-LocalGroupMember -Group "Administradores" | Where-Object Name -match "Svc_BackupAdmin"

# 2. Verificar Derechos de Usuario (secedit)
$tempVerify = "$env:TEMP\verify_rights.inf"
secedit /export /cfg $tempVerify /areas USER_RIGHTS | Out-Null
$content = Get-Content $tempVerify

Write-Host "`n--- Verificación de Derechos ---" -ForegroundColor Cyan
"SeBatchLogonRight", "SeDenyInteractiveLogonRight", "SeDenyRemoteInteractiveLogonRight" | ForEach-Object {
    $right = $_
    if ($content -match "$right = .*Svc_BackupAdmin") {
        Write-Host "[OK] $right configurado correctamente." -ForegroundColor Green
    } else {
        Write-Host "[ERROR] $right NO encontrado para el usuario." -ForegroundColor Red
    }
}

Remove-Item $tempVerify