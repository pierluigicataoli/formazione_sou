#!/bin/bash

NODO1="macchina1"
NODO2="macchina2"

nmcontainer="echo-server"
image="ealen/echo-server"

map="80:80"

avvio() {

NODO=$1
echo "si sta avviando il '$nmcontainer' sulla '$NODO' "
vagrant ssh "$NODO" -- -c "docker run -d --name $nmcontainer -p $map $image" 2>/dev/null 
}

blocco () {

NODO=$1
echo "arresto del '$nmcontainer sulla '$NODO' "
vagrant ssh "$NODO" -- -c "docker stop $nmcontainer && docker rm $nmcontainer" 2>/dev/null  || true 

}

while true ; do

blocco $NODO2
avvio $NODO1
echo "il container è avviato su '$NODO1' attesa di 60 secondi"
sleep 60

blocco $NODO1
avvio $NODO2
echo "il container ora è avviato su '$NODO2' attesa di 60 secondi"
sleep 60
done

