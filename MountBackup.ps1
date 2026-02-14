# Configuración
$UniqueId = "AQUÍ_TU_UNIQUE_ID" # Sustituye por el ID obtenido
$LogPath = "C:\informatica\backups\montajes.log"

# Asegurar que el directorio de logs existe
if (!(Test-Path "C:\informatica\backups")) { New-Item -ItemType Directory -Path "C:\informatica\backups" -Force | Out-Null }

$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $targetDisk = Get-Disk -UniqueId $UniqueId -ErrorAction Stop

    # 1. Poner el disco Online
    $targetDisk | Set-Disk -IsOffline $false -ErrorAction Stop
    
    # 2. Quitar el atributo de Solo Lectura
    $targetDisk | Set-Disk -IsReadOnly $false -ErrorAction Stop
    
    "$TimeStamp - ÉXITO: Disco montado y modo lectura/escritura activado." | Out-File -FilePath $LogPath -Append -Encoding utf8
}
catch {
    "$TimeStamp - ERROR: No se pudo montar el disco. Detalle: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append -Encoding utf8
    exit 1
}