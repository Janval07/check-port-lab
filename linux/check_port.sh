#!/bin/bash
# check_port.sh - Verifica si un puerto TCP está abierto en un host.
# Uso: ./check_port.sh <puerto> [host]

set -e

PORT="$1"
HOST="${2:-127.0.0.1}"
TIMEOUT=3

# Validación de argumentos
if [[ -z "$PORT" ]]; then
    echo "Error: debes indicar un puerto."
    echo "Uso: $0 <puerto> [host]"
    exit 2
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    echo "Error: '$PORT' no es un puerto válido (1-65535)."
    exit 2
fi

echo "Verificando $HOST:$PORT ..."

# Chequeo con /dev/tcp (nativo de bash, sin dependencias)
if timeout "$TIMEOUT" bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "Puerto $PORT en $HOST: ABIERTO"
    exit 0
else
    echo "Puerto $PORT en $HOST: CERRADO (o filtrado)"
    exit 1
fi  