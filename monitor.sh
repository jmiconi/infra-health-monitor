#!/usr/bin/env bash
#
# Infra Health Monitor
# - Database (SQL Server TCP check por ahora)
# - DFS / File Server connectivity
#
# Este script está pensado para ejecutarse vía systemd
# con un usuario de servicio (svc_monitor)
#

set -u          # error si se usa una variable no definida
set -o pipefail # error si falla un pipe

############################
# CONFIGURACIÓN GENERAL
############################

SECRETS_FILE="/etc/infra-monitor/infra-monitor.secrets"

############################
# FUNCIONES AUXILIARES
############################

log() {
    local msg="$1"
    echo "[$LOG_PREFIX] $(date '+%Y-%m-%d %H:%M:%S') - $msg"
}

fatal() {
    log "$1"
    exit 2
}

############################
# CARGA DE SECRETOS
############################

if [[ ! -f "$SECRETS_FILE" ]]; then
    fatal "Secrets file not found: $SECRETS_FILE"
fi

# shellcheck disable=SC1090
source "$SECRETS_FILE"

############################
# VALIDACIÓN DE VARIABLES
############################

REQUIRED_VARS=(
    MONITOR_ENV
    LOG_PREFIX
    DB_HOST
    DB_PORT
    DB_TIMEOUT
    DB_WARN_MS
    DB_CRIT_MS
)

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        fatal "Missing required environment variable: $var"
    fi
done

############################
# VALIDACIÓN DFS (OPCIONAL)
############################

DFS_ENABLED=false

if [[ -n "${DFS_MODE:-}" ]]; then
    log "[DFS] DFS_MODE detected: $DFS_MODE"

    DFS_REQUIRED_VARS=(
        DFS_HOST
        DFS_PORT
        DFS_TIMEOUT
        DFS_WARN_MS
        DFS_CRIT_MS
    )

    for var in "${DFS_REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            fatal "Missing required DFS variable: $var"
        fi
    done

    DFS_ENABLED=true
else
    log "[DFS] DFS checks disabled (DFS_MODE not set)"
fi

log "Environment validation OK"

############################
# DB CHECK (TCP CONNECTIVITY)
############################

log "[DB] Starting TCP connectivity check to ${DB_HOST}:${DB_PORT}"

DB_START=$(date +%s%3N)

if timeout "$DB_TIMEOUT" bash -c "</dev/tcp/${DB_HOST}/${DB_PORT}" 2>/dev/null; then
    DB_END=$(date +%s%3N)
    DB_LATENCY=$((DB_END - DB_START))

    if (( DB_LATENCY >= DB_CRIT_MS )); then
        log "[DB] latency=${DB_LATENCY}ms status=CRITICAL"
        exit 2
    elif (( DB_LATENCY >= DB_WARN_MS )); then
        log "[DB] latency=${DB_LATENCY}ms status=WARNING"
    else
        log "[DB] latency=${DB_LATENCY}ms status=OK"
    fi
else
    log "[DB] connection FAILED (timeout=${DB_TIMEOUT}s)"
    exit 2
fi

############################
# DFS CHECK (SI APLICA)
############################

if [[ "$DFS_ENABLED" == true ]]; then
    log "[DFS] Checking TCP connectivity to ${DFS_HOST}:${DFS_PORT}"

    DFS_START=$(date +%s%3N)

    if timeout "$DFS_TIMEOUT" bash -c "</dev/tcp/${DFS_HOST}/${DFS_PORT}" 2>/dev/null; then
        DFS_END=$(date +%s%3N)
        DFS_LATENCY=$((DFS_END - DFS_START))

        if (( DFS_LATENCY >= DFS_CRIT_MS )); then
            log "[DFS] latency=${DFS_LATENCY}ms status=CRITICAL"
            exit 2
        elif (( DFS_LATENCY >= DFS_WARN_MS )); then
            log "[DFS] latency=${DFS_LATENCY}ms status=WARNING"
        else
            log "[DFS] latency=${DFS_LATENCY}ms status=OK"
        fi
    else
        log "[DFS] connection FAILED (timeout=${DFS_TIMEOUT}s)"
        exit 2
    fi
fi

############################
# RESULTADO FINAL
############################

log "GLOBAL STATUS: OK"
exit 0
