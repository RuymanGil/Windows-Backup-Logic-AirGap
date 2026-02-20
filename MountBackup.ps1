# --- CONFIGURACIÓN ---
$UniqueId = "PON-AQUI-TU-UniqueID" 
$LogPath = "C:\informatica\backups\backup_system.log"
$ErrorActionPreference = "Continue" # Importante: Que no se pare por errores no críticos

$TimeStamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
"--- $TimeStamp INICIANDO MONTAJE ---" | Out-File $LogPath -Append

try {
    # 1. Poner Online y Quitar Solo Lectura de forma directa
    Set-Disk -UniqueId $UniqueId -IsOffline $false -ErrorAction SilentlyContinue
    Set-Disk -UniqueId $UniqueId -IsReadOnly $false -ErrorAction SilentlyContinue
    
    # 2. Pausa de 12 segundos (Margen para que Windows asigne letra E:)
    Start-Sleep -Seconds 12

    # 3. Comprobación final
    $disk = Get-Disk -UniqueId $UniqueId
    $part = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.DriveLetter -ne $null }
    
    if ($part) {
        "$TimeStamp - INFO: Disco montado en $($part.DriveLetter):" | Out-File $LogPath -Append
        exit 0
    } else {
        throw "El disco está online pero no se detectó letra de unidad."
    }
}
catch {
    "$TimeStamp - ERROR MONTAJE: $($_.Exception.Message)" | Out-File $LogPath -Append
    exit 1
}