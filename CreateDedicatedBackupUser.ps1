# ==============================================================================
# Nombre: CreateDedicatedBackupUser.ps1
# Función: Creación de usuario técnico habilitado para login y recuperación
# Autor: Ruymán Gil García - SysAdmin L3
# ==============================================================================

# 1. Configuración de variables
$username = "Svc_BackupAdmin"
$password = ConvertTo-SecureString "CambiaEstaPassword2026!" -AsPlainText -Force
$tempFile = "$env:TEMP\security_config.inf"

Write-Host "--- Iniciando despliegue de cuenta técnica: $username ---" -ForegroundColor Cyan

# 2. Creación del usuario local
if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
    Write-Host "[!] El usuario $username ya existe. Verificando configuración..." -ForegroundColor Yellow
} else {
    Write-Host "[+] Creando usuario local..." -ForegroundColor White
    
    New-LocalUser -Name $username `
                  -Password $password `
                  -Description "Cuenta para backups y recuperación de datos." `
                  -PasswordNeverExpires `
                  -UserMayNotChangePassword | Out-Null
    
    Write-Host "[+] Usuario creado exitosamente." -ForegroundColor Green
}

# 2.1 Asegurar pertenencia al grupo Administradores
try {
    $group = "Administradores"
    $isMember = Get-LocalGroupMember -Group $group -Member $username -ErrorAction SilentlyContinue
    
    if (-not $isMember) {
        Add-LocalGroupMember -Group $group -Member $username -ErrorAction Stop
        Write-Host "[+] Usuario añadido al grupo $group." -ForegroundColor Green
    } else {
        Write-Host "[*] El usuario ya pertenece al grupo $group." -ForegroundColor Gray
    }
}
catch {
    Write-Host "[ERROR] No se pudo añadir al grupo Administradores: $_" -ForegroundColor Red
}

# 3. Configuración de derechos de usuario
Write-Host "[+] Configurando políticas de acceso..." -ForegroundColor White

secedit /export /cfg $tempFile /areas USER_RIGHTS | Out-Null
$config = Get-Content $tempFile -Raw

function Add-Right {
    param($configString, $rightName, $user)
    if ($configString -match "$rightName = ") {
        if ($configString -notmatch "$rightName = .*$user") {
            return $configString -replace "($rightName = .*?)(?=\r?\n|$)", "`$1,$user"
        }
        return $configString
    } 
    else {
        if ($configString -match "\[Privilege Rights\]") {
            return $configString -replace "\[Privilege Rights\]", "[Privilege Rights]`r`n$rightName = $user"
        } else {
            return $configString + "`r`n[Privilege Rights]`r`n$rightName = $user"
        }
    }
}

# --- CONFIGURACIÓN DE ACCESO ---

# A. Permitir ejecución de tareas programadas (Necesario para Cobian)
$config = Add-Right -configString $config -rightName "SeBatchLogonRight" -user $username

# B. Permitir inicio de sesión local (Necesario para entrar y recuperar archivos)
$config = Add-Right -configString $config -rightName "SeInteractiveLogonRight" -user $username

# NOTA: Se han eliminado 'SeDenyInteractiveLogonRight' y 'SeDenyRemoteInteractiveLogonRight' 
# para permitir que el usuario pueda loguearse en el sistema.

# 4. Importar configuración final
$config | Out-File $tempFile -Encoding Default
secedit /configure /db "$env:windir\security\local.sdb" /cfg $tempFile /areas USER_RIGHTS | Out-Null

# 5. Limpieza
if (Test-Path $tempFile) { Remove-Item $tempFile }

Write-Host "--- Proceso finalizado ---" -ForegroundColor Green
Write-Host "La cuenta $username ahora puede iniciar sesión para tareas de recuperación." -ForegroundColor White