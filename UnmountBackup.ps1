# Configuración
$UniqueId = "AQUÍ_TU_UNIQUE_ID" # Sustituye por el ID obtenido
$LogPath = "C:\informatica\backups\desmontajes.log"

# Asegurar que el directorio de logs existe
if (!(Test-Path "C:\informatica\backups")) { New-Item -ItemType Directory -Path "C:\informatica\backups" -Force | Out-Null }

$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $targetDisk = Get-Disk -UniqueId $UniqueId -ErrorAction Stop

    # 1. Sincronizar caché de almacenamiento
    Update-StorageProviderCache
    
    # 2. Activar Inmutabilidad (Solo Lectura)
    $targetDisk | Set-Disk -IsReadOnly $true -ErrorAction Stop
    
    # 3. Poner el disco Offline
    $targetDisk | Set-Disk -IsOffline $true -ErrorAction Stop
    
    "$TimeStamp - ÉXITO: Disco protegido (ReadOnly) y puesto en estado Offline." | Out-File -FilePath $LogPath -Append -Encoding utf8
}
catch {
    "$TimeStamp - ERROR: No se pudo desmontar el disco correctamente. Detalle: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append -Encoding utf8
    exit 1
}