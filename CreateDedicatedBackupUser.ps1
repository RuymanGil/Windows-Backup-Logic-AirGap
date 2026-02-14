# ==============================================================================
# Nombre: CreateDedicatedBackupUser.ps1
# Función: Creación de usuario técnico y Hardening (Restricciones de seguridad)
# ==============================================================================

# 1. Configuración de variables
$username = "Svc_BackupAdmin"
$password = ConvertTo-SecureString "CambiaEstaPassword2026!" -AsPlainText -Force
$tempFile = "$env:TEMP\security_config.inf"

Write-Host "--- Iniciando despliegue de cuenta técnica: $username ---" -ForegroundColor Cyan

# 2. Creación del usuario local
if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
    Write-Host "[!] El usuario $username ya existe. Saltando creación..." -ForegroundColor Yellow
} else {
    Write-Host "[+] Creando usuario local..." -ForegroundColor White
    New-LocalUser -Name $username `
                  -Password $password `
                  -Description "Cuenta de servicio para backups automatizados." `
                  -PasswordNeverExpires $true `
                  -UserMayNotChangePassword $true | Out-Null
    
    # Añadir al grupo Administradores (Requerido para Set-Disk)
    Add-LocalGroupMember -Group "Administradores" -Member $username
    Write-Host "[+] Usuario creado y añadido al grupo Administradores." -ForegroundColor Green
}

# 3. Configuración de derechos de usuario (secedit)
Write-Host "[+] Configurando políticas de seguridad (Hardening)..." -ForegroundColor White

# Exportar configuración actual
secedit /export /cfg $tempFile /areas USER_RIGHTS | Out-Null

# Leer contenido
$config = Get-Content $tempFile -Raw

# Función interna para procesar derechos
function Add-Right {
    param($configString, $rightName, $user)
    if ($configString -match "$rightName = ") {
        # Si el derecho existe, añade el usuario si no está ya presente
        if ($configString -notmatch "$rightName = .*$user") {
            return $configString -replace "($rightName = .*?)(?=\r?\n|$)", "`$1,$user"
        }
        return $configString
    } else {
        return $configString + "`r`n$rightName = $user"
    }
}

# Aplicar derechos y restricciones
# A. Permitir ejecución de tareas programadas
$config = Add-Right -configString $config -rightName "SeBatchLogonRight" -user $username
# B. RESTRICCIÓN: Impedir inicio de sesión físico
$config = Add-Right -configString $config -rightName "SeDenyInteractiveLogonRight" -user $username
# C. RESTRICCIÓN: Impedir acceso por Escritorio Remoto (RDP)
$config = Add-Right -configString $config -rightName "SeDenyRemoteInteractiveLogonRight" -user $username

# 4. Importar configuración final
$config | Out-File $tempFile -Encoding ascii
secedit /configure /db $env:windir\security\local.sdb /cfg $tempFile /areas USER_RIGHTS | Out-Null

# 5. Limpieza
if (Test-Path $tempFile) { Remove-Item $tempFile }

Write-Host "--- Proceso finalizado con éxito ---" -ForegroundColor Green
Write-Host "La cuenta $username está lista y blindada contra accesos humanos." -ForegroundColor White