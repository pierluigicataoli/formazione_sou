#!/bin/bash

DATA_DIR="./stato_barca"
mkdir -p $DATA_DIR
rm -f $DATA_DIR/GAMEOVER

avvia_processo() {
    RIVA=$1
    NOME=$2
    PREDA=$3
    docker exec -d $RIVA /bin/bash -c "nohup ./check.sh $NOME $PREDA > /tmp/$NOME.log 2>&1 &"
}

uccidi_processo() {
    RIVA=$1
    NOME=$2
    docker exec $RIVA pkill -f "check.sh $NOME " 2>/dev/null
}

controlla_processo() {
    RIVA=$1
    NOME=$2
    docker exec $RIVA pgrep -f "check.sh $NOME " > /dev/null
}

inizializza_gioco() {
    echo "--- Inizializzazione Processi ---"
    docker-compose down >/dev/null 2>&1
    docker-compose up -d --build >/dev/null 2>&1
    
    echo -n "riva_sx" > $DATA_DIR/posizione
    
    echo "Creo i processi sulla riva sinistra..."
    avvia_processo "riva_sx" "lupo" "capra"
    avvia_processo "riva_sx" "capra" "cavolo"
    avvia_processo "riva_sx" "cavolo" "nessuno"
    sleep 2
}

disegno_scena() {
    clear
    luogo_barca=$(cat $DATA_DIR/posizione | tr -d '\n')
    
    lupo_sin=" "; lupo_dest=" "; capra_sin=" "; capra_dest=" "; cavolo_sin=" "; cavolo_dest=" "
    
    if controlla_processo "riva_sx" "lupo"; then lupo_sin="Lupo"; fi
    if controlla_processo "riva_dx" "lupo"; then lupo_dest="Lupo"; fi
    if controlla_processo "riva_sx" "capra"; then capra_sin="Capra"; fi
    if controlla_processo "riva_dx" "capra"; then capra_dest="Capra"; fi
    if controlla_processo "riva_sx" "cavolo"; then cavolo_sin="Cavolo"; fi
    if controlla_processo "riva_dx" "cavolo"; then cavolo_dest="Cavolo"; fi

    barca_sin="  "; barca_dest="  "
    if [ "$luogo_barca" == "riva_sx" ]; then barca_sin="Barca_contadino  "; else barca_dest="Barca_contadino  "; fi

    echo "   RIVA SINISTRA      |       RIVA DESTRA    "
    echo "============================================="
    echo "   $lupo_sin  $capra_sin  $cavolo_sin    $barca_sin   |    $barca_dest    $lupo_dest  $capra_dest  $cavolo_dest  " 
}
logica_spostamento() {
    ATTORE=$1
    PREDA=$2
    
    RIVA_CORRENTE=$(cat $DATA_DIR/posizione | tr -d '\n')
    ALTRA_RIVA="riva_dx"
    if [ "$RIVA_CORRENTE" == "riva_dx" ]; then ALTRA_RIVA="riva_sx"; fi

    if ! controlla_processo "$RIVA_CORRENTE" "$ATTORE"; then
        echo "Errore: $ATTORE non è sulla riva dove c'è la barca ($RIVA_CORRENTE)!"
        sleep 2
        return
    fi

    uccidi_processo "$RIVA_CORRENTE" "$ATTORE"
    
    echo -n "$ALTRA_RIVA" > $DATA_DIR/posizione

    avvia_processo "$ALTRA_RIVA" "$ATTORE" "$PREDA"
}

muovi_barca() {
    CORRENTE=$(cat $DATA_DIR/posizione | tr -d '\n')
    if [ "$CORRENTE" == "riva_sx" ]; then NUOVA="riva_dx"; else NUOVA="riva_sx"; fi
    echo -n "$NUOVA" > $DATA_DIR/posizione
}

inizializza_gioco

while true; do
disegno_scena
    
    if [ -f "$DATA_DIR/GAMEOVER" ]; then
        echo " hai perso, riprova "
        cat "$DATA_DIR/GAMEOVER"
        echo "Premi INVIO..."
        read
        docker-compose down
        exit
    fi
    
    # Controllo Vittoria
    if controlla_processo "riva_dx" "lupo" && controlla_processo "riva_dx" "capra" && controlla_processo "riva_dx" "cavolo"; then
        echo " complimenti, è andato tutto a buon fine"
        docker-compose down
        exit
    fi

    echo "Chi sposti?"
    echo "1) Lupo"
    echo "2) Capra"
    echo "3) Cavolo"
    echo "4) Solo Barca"
    echo "q) Esci"
    read -p "Scelta: " scelta

    case $scelta in
        1) logica_spostamento "lupo" "capra" ;;
        2) logica_spostamento "capra" "cavolo" ;;
        3) logica_spostamento "cavolo" "nessuno" ;;
        4) muovi_barca ;;
        q) docker-compose down; exit ;;
    esac
done
