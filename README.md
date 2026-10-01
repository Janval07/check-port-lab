# Laboratorio: Verificador de puertos (Bash vs PowerShell)

## Objetivo

Implementar la misma tarea —determinar si un puerto TCP está **abierto** o
**cerrado** en un host— en dos entornos distintos:

- **Linux (Bash)**: script ejecutado dentro de un contenedor Docker.
- **Windows (PowerShell)**: script ejecutado de forma nativa.

---

## Estructura del proyecto

```
check-port-lab/
├── linux/
│   └── check_port.sh      # Script Bash
├── windows/
│   └── Check-Port.ps1     # Script PowerShell
└── README.md
```

---

## 1. Script Linux (Bash) — `check_port.sh`

### Descripción

Recibe un puerto (obligatorio) y opcionalmente un host (por defecto
`127.0.0.1`). Valida que el puerto esté en el rango 1-65535 e intenta abrir
una conexión TCP usando la característica nativa `/dev/tcp` de Bash, con un
timeout de 3 segundos.

- Si la conexión se establece → **ABIERTO** (exit 0).
- Si falla o expira → **CERRADO / filtrado** (exit 1).
- Si el argumento es inválido → mensaje de error (exit 2).

### Requisitos

- Docker instalado y corriendo.
- Imagen `bash:latest` (se descarga automáticamente la primera vez).

### Uso dentro de Docker

```bash
docker run --rm -it -v "${PWD}/linux:/scripts" bash:latest \
    bash /scripts/check_port.sh <puerto> [host]
```

### Ejemplos

**Puerto cerrado:**

```bash
docker run --rm -it -v "${PWD}/linux:/scripts" bash:latest \
    bash /scripts/check_port.sh 12345
# Salida: Puerto 12345 en 127.0.0.1: CERRADO (o filtrado)
```

**Puerto abierto (usando un contenedor nginx-test):**

```bash
# 1. Levantar nginx en segundo plano
docker run -d --name nginx-test -p 8080:80 nginx:alpine

# 2. Crear una red y conectar el contenedor
docker network create labnet
docker network connect labnet nginx-test

# 3. Comprobar el puerto 80 del contenedor nginx-test
docker run --rm -it --network labnet -v "${PWD}/linux:/scripts" bash:latest \
    bash /scripts/check_port.sh 80 nginx-test
# Salida: Puerto 80 en nginx-test: ABIERTO

# 4. Limpieza
docker stop nginx-test
docker rm nginx-test
docker network rm labnet
```

**Puerto inválido (validación):**

```bash
docker run --rm -it -v "${PWD}/linux:/scripts" bash:latest \
    bash /scripts/check_port.sh 99999
# Salida: Error: '99999' no es un puerto válido (1-65535).
```

---

## 2. Script Windows (PowerShell) — `Check-Port.ps1`

### Descripción

Recibe un puerto obligatorio (validado con `[ValidateRange(1,65535)]`) y
opcionalmente un host destino (por defecto `127.0.0.1`). Usa
`System.Net.Sockets.TcpClient` con `BeginConnect` +
`AsyncWaitHandle.WaitOne()` para lograr un timeout limpio de 3 segundos sin
bloquear el script.

- Si la conexión se establece → **ABIERTO** en verde (exit 0).
- Si falla o expira → **CERRADO / filtrado** en rojo (exit 1).

### Requisito previo (solo la primera vez)

Por defecto Windows bloquea la ejecución de scripts `.ps1`. Hay que cambiar
la política de ejecución **una sola vez**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Responde `S` cuando pregunte.

### Uso

```powershell
.\Check-Port.ps1 -Puerto <n> [-Destino <host>] [-TimeoutMs <ms>]
```

### Ejemplos

```powershell
# Puerto abierto típico en Windows (SMB)
.\Check-Port.ps1 -Puerto 445
# Salida: Puerto 445 en 127.0.0.1: ABIERTO

# Puerto cerrado (casi seguro nadie escucha ahí)
.\Check-Port.ps1 -Puerto 12345
# Salida: Puerto 12345 en 127.0.0.1: CERRADO (o filtrado)

# Host remoto
.\Check-Port.ps1 -Puerto 80 -Destino google.com

# Timeout personalizado (5 segundos)
.\Check-Port.ps1 -Puerto 80 -Destino google.com -TimeoutMs 5000
```