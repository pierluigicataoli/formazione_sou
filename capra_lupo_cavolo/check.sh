#!/bin/bash

IO_SONO=$1
PREDA=$2

sleep 2

echo "--- PROCESSO AVVIATO: $IO_SONO (Preda: $PREDA) ---"

while true; do
    DOVE_SONO=$(hostname)
    POSIZIONE_BARCA=$(cat /dati_barca/posizione 2>/dev/null | tr -d '\n' || echo "boh")

    if pgrep -f "check.sh $PREDA " > /dev/null; then
        PREDA_PRESENTE=true
    else
        PREDA_PRESENTE=false
    fi

    if [ "$PREDA_PRESENTE" = true ] && [ "$POSIZIONE_BARCA" != "$DOVE_SONO" ]; then
        
        MSG="il/la $PREDA è stato mangiato/a dalla/dal $IO_SONO!"
        echo "$MSG"
        
        # Invio messaggio rete
        echo "$MSG" | nc -w 1 riva_sx 5000 2>/dev/null
        echo "$MSG" | nc -w 1 riva_dx 5000 2>/dev/null

        pkill -f "check.sh $PREDA "
    fi

    sleep 1
done
