# --- CONFIGURACIÓN ---
$DiskUniqueId = "PON-AQUÍ-TU-UniqueID"
$LogPath = "C:\informatica\backups\desmontajes.log"

$ErrorActionPreference = "Stop"
$TimeStamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"

try {
    # 1. Localizar el disco físico
    $targetDisk = Get-Disk -UniqueId $DiskUniqueId -ErrorAction Stop

    # 2. Tomar la primera partición con letra asignada
    $partition = Get-Partition -DiskNumber $targetDisk.Number |
        Where-Object { $_.DriveLetter } |
        Select-Object -First 1

    if ($partition) {
        $driveLetter = ($partition.DriveLetter + ":")

        # --- PASO A: Cerrar procesos bloqueantes ---
        Get-Process | Where-Object { $_.Modules.FileName -like "$driveLetter*" } |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        # --- PASO B: Desmontaje por Letra (mountvol) ---
        if ($driveLetter -match "^[A-Z]:$") {
            mountvol $driveLetter /D
            "$TimeStamp - INFO: Letra $driveLetter liberada." | Out-File $LogPath -Append -Encoding utf8
        } else {
            "$TimeStamp - INFO: Letra inválida, se omite mountvol." | Out-File $LogPath -Append -Encoding utf8
        }
    } else {
        "$TimeStamp - INFO: No se encontró letra de unidad para desmontar." | Out-File $LogPath -Append -Encoding utf8
    }

    # 3. Pausa de seguridad
    Start-Sleep -Seconds 5

    # 4. Aplicar protección y poner Offline
    $targetDisk | Set-Disk -IsReadOnly $true -ErrorAction SilentlyContinue
    $targetDisk | Set-Disk -IsOffline $true -ErrorAction Stop

    "$TimeStamp - ÉXITO: Disco protegido y puesto Offline correctamente." | Out-File $LogPath -Append -Encoding utf8
    exit 0
}
catch {
    $errorMsg = $_.Exception.Message
    "$TimeStamp - ERROR DESMONTAJE: $errorMsg" | Out-File $LogPath -Append -Encoding utf8
    exit 1
}
