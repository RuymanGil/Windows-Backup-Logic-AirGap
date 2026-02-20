# 🛡️ Estrategia de Respaldo Seguro (Cobian Reflector + PowerShell)

Este proyecto implementa una arquitectura de copias de seguridad de nivel profesional (L3) diseñada para mitigar riesgos de Ransomware mediante la gestión de discos **Offline**, permisos restrictos y rotación automática de logs.

## 🚀 Concepto: Air-Gap Lógico y Automatización

Para garantizar la integridad de los datos, el sistema utiliza **Hooks** (Eventos) secuenciales gestionados por Cobian Reflector. El disco de destino permanece invisible y en modo solo lectura mientras no hay una tarea activa.

1.  **Pre-Backup:** Montaje del disco y activación de modo lectura/escritura.
2.  **Backup:** Ejecución de copia Incremental (basada en el atributo de archivo).
3.  **Post-Backup 1:** Desmontaje y bloqueo del disco (Estado Offline).
4.  **Post-Backup 2:** Rotación de logs para mantenimiento de espacio.

---

## 📋 1. Preparación de la Identidad (Hardening)

1.  **Creación de Usuario:**
    Ejecute `CreateDedicatedBackupUser.ps1` como Administrador. 
    * Crea la cuenta `Svc_BackupAdmin` y restringe el inicio de sesión interactivo/RDP.
2.  **Configuración del Servicio:**
    * Abra `services.msc` y localice **Cobian Reflector - Motor**.
    * Cambie el inicio de sesión a la cuenta `.\Svc_BackupAdmin`.
    * **Reinicie el servicio** para aplicar cambios.

---

## ⚙️ 2. Configuración de la Tarea en Cobian

Configure la tarea **"Backup D: COMPLETO"** con los siguientes parámetros clave:

### 🔹 Dinámica y Ciclo de Vida
* **Copias completas a conservar:** `1`
* **Hacer un respaldo completo cada:** `0` (Cero).
* **Lógica:** El script `mount_backup.ps1` formatea el disco el día 1 del mes, forzando a Cobian a iniciar un nuevo ciclo de forma automática.

### 🔹 Filtros de Exclusión
Añada en **"Excluir estos ficheros"**:
* Directorios: `System Volume Information`, `$RECYCLE.BIN`.
* Máscaras: `*.tmp`, `~$*`, `Thumbs.db`, `desktop.ini`.

### ⚡ Eventos (Hooks de Línea de Comando)
Añada los comandos habilitando siempre la opción **"Esperar por finalización"**:

**A. Pre-Respaldo:**
* `powershell.exe -ExecutionPolicy Bypass -File "C:\informatica\backups\mount_backup.ps1"`

**B. Post-Respaldo (En este orden):**
1.  `powershell.exe -ExecutionPolicy Bypass -File "C:\informatica\backups\UnmountBackup.ps1"`
2.  `powershell.exe -ExecutionPolicy Bypass -File "C:\informatica\backups\Optional-Maintain-BackupLogs.ps1"`

---

## 🛠️ 3. Herramientas de Gestión y Diagnóstico

Todos los archivos deben ubicarse en `C:\informatica\backups`.

| Archivo | Función |
| :--- | :--- |
| `mount_backup.ps1` | Monta el disco y aplica formateo si es día 1 del mes. |
| `UnmountBackup.ps1` | Pone el disco en modo Solo Lectura y Offline. |
| `Optional-Maintain-BackupLogs.ps1` | Elimina logs de la carpeta que superen los 10MB