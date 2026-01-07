#!/bin/bash
#creazione file log
touch /tmp/gameover_log

echo "creata...."

while true; do
    mxg=$(nc -l -p 5000)
    if [ ! -z "$mxg" ]; then
        echo "RICEVUTO MESSAGGIO RETE: $mxg"
        echo "$mxg" > /dati_barca/GAMEOVER
    fi
done &
#serve per far rimanere il container attivo\
tail -f /dev/null
