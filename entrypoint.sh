#!/usr/bin/env bash
# =========================================================================
# Aarkam Rokka Sovereign Storage Fabric Container Entrypoint
# Supports: ROKKA_ROLE = "all" (default), "coordinator", or "gateway"
# Direct command execution supported when arguments are passed.
# =========================================================================

set -Eeuo pipefail

if [ "$#" -gt 0 ]; then
    exec "$@"
fi

ROLE="${ROKKA_ROLE:-all}"

echo "================================================================="
echo " Aarkam Rokka Sovereign Storage Fabric (v1.0.2)"
echo " Role: ${ROLE}"
echo " Ports: Coordinator (7774/57774), Gateway (7772/57772)"
echo "================================================================="

case "${ROLE,,}" in
    coordinator)
        echo "[INFO] Launching rokka-coordinator..."
        exec /app/rokka-coordinator
        ;;
    gateway)
        echo "[INFO] Launching rokka-gateway..."
        exec /app/rokka-gateway
        ;;
    all|both|cluster)
        echo "[INFO] Launching both rokka-coordinator and rokka-gateway..."
        /app/rokka-coordinator &
        COORD_PID=$!
        
        # Allow coordinator initialization
        sleep 2
        
        /app/rokka-gateway &
        GW_PID=$!
        
        trap "echo '[INFO] Terminating daemons...'; kill -TERM $COORD_PID $GW_PID 2>/dev/null || true; wait $COORD_PID $GW_PID 2>/dev/null || true" SIGINT SIGTERM
        
        # Wait for either process to terminate
        wait -n "$COORD_PID" "$GW_PID"
        ;;
    *)
        echo "[ERROR] Unknown ROKKA_ROLE: '${ROLE}'. Expected: 'coordinator', 'gateway', or 'all'."
        exit 1
        ;;
esac
