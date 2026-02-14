# 🛡️ Sistema de Aislamiento Lógico para Backups

Este conjunto de scripts implementa una estrategia de **aislamiento lógico** y **protección contra escritura** para unidades de copia de seguridad. El objetivo es mitigar el impacto de ataques de ransomware mediante el estado *Offline* del disco y la inmutabilidad de los datos.

## 📋 Inventario de Scripts

| Script | Propósito |
| :--- | :--- |
| `CreateDedicatedBackupUser.ps1` | Crea el usuario `Svc_BackupAdmin` y aplica el blindaje de seguridad (Hardening). |
| `Test-BackupUserSetup.ps1` | Audita y confirma que la cuenta técnica tiene los permisos y restricciones correctas. |
| `MountBackup.ps1` | Pone el disco **Online** y quita el modo **Solo Lectura**. |
| `UnmountBackup.ps1` | Activa el modo **Solo Lectura** y pone el disco **Offline**. |
| `Optional-Maintain-BackupLogs.ps1` | **(Opcional)** Limpia los archivos de log que superen los 10MB para ahorrar espacio. |

---

## 🛠️ Configuración Inicial

1. **Identificación del Hardware:**
   Es crítico usar el `UniqueId` para evitar confusiones de unidades. Obtén el ID con:
   ```powershell
   Get-Disk | Select-Object Number, FriendlyName, UniqueId
   ```
2. **Directorios:**
   Asegúrate de que la ruta de logs exista y tenga permisos restringidos:
   `C:\informatica\backups`

---

## 🔐 Blindaje de Seguridad (Hardening)

La cuenta de servicio `Svc_BackupAdmin` ha sido configurada bajo el principio de **Menor Privilegio**:
* **Permitido:** Iniciar sesión como trabajo por lotes (`SeBatchLogonRight`).
* **Denegado:** Inicio de sesión local e interactivo (Consola física).
* **Denegado:** Acceso por Escritorio Remoto (RDP).

---

## ⚙️ Programador de Tareas de Windows

Configura las tareas con los siguientes parámetros:

* **Usuario:** `Svc_BackupAdmin`
* **Opciones:** "Ejecutar tanto si el usuario inició sesión como si no" + "Privilegios más altos".
* **Argumentos:**
    * **Montaje:** `-ExecutionPolicy Bypass -File "C:\informatica\backups\MountBackup.ps1"`
    * **Desmontaje:** `-ExecutionPolicy Bypass -File "C:\informatica\backups\UnmountBackup.ps1"`
    * **Mantenimiento (Opcional):** `-ExecutionPolicy Bypass -File "C:\informatica\backups\Optional-Maintain-BackupLogs.ps1"`

---

## ⚠️ Gestión de Errores e Integridad

* **Exit Codes:** Los scripts devuelven `exit 1` en caso de fallo crítico. 
* **Logs:** Las operaciones se registran en `montajes.log` y `desmontajes.log`.
* **Estrategia:** El disco permanece en estado **Offline** y **ReadOnly** la mayor parte del tiempo, reduciendo la superficie de ataque frente a malware.
