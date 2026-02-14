# ==============================================================================
# Nombre: Optional-Maintain-BackupLogs.ps1
# Función: Rotación/Limpieza de logs que superen los 10MB
# ==============================================================================

$LogDir = "C:\informatica\backups"
$MaxSize = 10MB

# 1. Comprobar si la carpeta existe
if (Test-Path $LogDir) {
    
    # 2. Obtener todos los archivos .log de la carpeta
    $LogFiles = Get-ChildItem -Path $LogDir -Filter *.log

    foreach ($File in $LogFiles) {
        # 3. Comprobar el tamaño (Length está en bytes)
        if ($File.Length -gt $MaxSize) {
            try {
                Remove-Item $File.FullName -Force -ErrorAction Stop
                # Opcional: Podrías crear un nuevo log vacío indicando el borrado
                # "Log reseteado por exceso de tamaño" | Out-File $File.FullName
            }
            catch {
                # Si el archivo está bloqueado por otro proceso, fallará silenciosamente
                exit 1
            }
        }
    }
}