# ==============================================================================
# Nombre: Check-BackupStatus.ps1
# Función: Verificación rápida del estado de seguridad del disco de backup
# ==============================================================================

$UniqueId = "TU_UNIQUE_ID_AQUI" # Pon aquí tu ID real

try {
    $disk = Get-Disk -UniqueId $UniqueId -ErrorAction Stop
    $status = if ($disk.OperationalStatus -eq 'Online') { "⚠️ ONLINE (EXPUESTO)" } else { "✅ OFFLINE (PROTEGIDO)" }
    $readOnly = if ($disk.IsReadOnly) { "✅ SÍ" } else { "⚠️ NO" }

    Write-Host "`n--- ESTADO DEL SISTEMA DE BACKUP ---" -ForegroundColor Cyan
    Write-Host "Disco: $($disk.FriendlyName)"
    Write-Host "Estado: $status" -ForegroundColor (if ($disk.OperationalStatus -eq 'Online') { "Yellow" } else { "Green" })
    Write-Host "Solo Lectura: $readOnly" -ForegroundColor (if ($disk.IsReadOnly) { "Green" } else { "Yellow" })
    
    $lastLog = Get-Content "C:\informatica\backups\montajes.log" -Tail 1
    Write-Host "Último evento en log: $lastLog" -ForegroundColor Gray
    Write-Host "------------------------------------`n"
}
catch {
    Write-Host "❌ ERROR: No se encuentra el disco de backup." -ForegroundColor Red
}