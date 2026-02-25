Cosa è KubeVirt e quali problemi va a risolvere?  KubeVirt è un estensione di k8s che permette di containerizzare macchine virtuali. Una VM classica è possibile "convertirla" in un processo QEMU/KVM per farla girare su un Hypervisor basato su Linux.  Il processo QEMU/KVS è un processo che permette  la gestione ad alte prestazioni delle macchine virtuali (come se fossero macchine native)

QEMU è un software che ha il compito di “emulare” le risorse hardware, le periferiche per essere precisi.

KVM è un modulo del kernel Linux che permette, tramite le estensioni di virtualizzazione della CPU, di allocare risorse (CPU e RAM) nelle macchine virtuali e renderle performanti alla stessa velocità dell’hardware nativo.

KubeVirt permette la migrazione di una macchina VMware in un container, incapsulando il processo QEMU/KVS dentro un pod chiamato virt-launcher.
La VM condivide le stesse caratteristiche:
- Stesso IP
- Stessi servizi ccc
- Stesso Kernel

Bisogna specificare che questo non avviene sempre, ma di base la migrazione deve avvenire in maniera “trasparente”

All’interno del Cluster la VM viene vista come una normale risorsa K8s quindi possiede l’ip del Pod Network ecc ecc.

VMI:

Virt-launcher non è altro che il pod VMI.

Il VMI sta alle VM come I Deployment stanno ai Pod.

La VM in k8s è vista come l’oggetto Dichiarativo e di conseguenza descrive lo stato desiderato all’interno del cluster.
Mentre la VMI è l’oggetto Runtime e rappresenta l’istanza in esecuzione.

Questo è un particolare fondamentale da sapere, perché per permettere di scalare le risorse a caldo, bisogna modificare il file YAML della VM e non della VMI.

Aumento della RAM:

Per poter aumentare la RAM è necessario soddisfare determinati requisiti:
* LiveResourceUpdate abilitato all’interno del Feature Gate.
* Bisogna rispettare il limite massimo dichiarato nel file YAML della VM
* Bisogna aver installato il QEMU Guest Agent all’interno della VMI.
* Il Sistema Operativo deve possedere moduli che permettono la modifica a caldo (il termine corretto è HOTPLUG).

- Il Feature Gate è un meccanismo che abilita e disabilita determinate funzionalità all’interno di un Cluster. Per permettere la scalabilità è necessario aggiungere  le funzioni “LiveUpdate” o “LiveResourceUpdate” all’interno dei file di configurazione del Cluster.

- Per permettere di scalare la RAM (e non solo) è importante aver settato e rispettate i limiti presenti all’interno del file YAML della VM.
Ovviamente non si può andare oltre ai limiti che in precedenza sono stati impostati.

NB: è possibile cambiare il valore del parametro limit o maxMemory mentre la VM è in esecuzione, SOLO SE questi parametri erano già impostati all’interno del file YAML della vm. In caso contrario è necessario riavviare la VM (ColdPlug).

- Il QEMU Guest Agent è un software che deve essere presente all’interno della VMI. Permette la comunicazione tra Hypervisor e Sistema Operativo.
       Il suo compito principale è quello di “aggiornare” il Sistema Operativo, su tutti i cambiamenti che vengono effettuati dal Hypervisor.

- Il Sistema Operativo deve supportare i moduli per l’Hotplug (come acpi_memhotplug e memory_hotplug). Tali funzionalità dipendono dalla configurazione del Kernel Linux, in particolare dall'attivazione delle opzioni CONFIG_MEMORY_HOTPLUG e CONFIG_MEMORY_HOTREMOVE in fase di compilazione
      
Gli ultimi S.O (quelli più moderni) hanno i moduli pre caricati.

Tutti le distribuzioni Linux degli ultimi 10-15 anni hanno i moduli presenti all’interno del proprio Kernel.

Per quanto riguarda i Sistemi Operativi Windows, non “nascono” con il supporto per l’hardware virtuale QEMU/KVM. Per far funzionare L’HOTPLUG bisogna installare i VirtIO Drivers.

Come si effettua il cambiamento?

Come detto prima, dopo che una macchina virtuale si trova all’interno di un cluster K8s/OpenShift è una risorsa effettiva del Cluster, quindi basta cambiare il file YAML della VM,in particolare il valore -> spec.template.spec.domain.resources.requests.memory, e applicare il file yaml con kubectl/oc apply della VM.

NB: BISOGNA CAMBIARE LO YAML DELLA VM, NON DELLA VMI.

Aumento della CPU:

I requisiti sono pressoché molto simili, l’uniche differenze sono i campi che vanno modificati. 

 - Per la Feature Gate bisogna aggiungere la funzione “CPUHotplug”

- Il Sistema Operativo deve supportare i moduli per l’Hotplug della CPU (come acpi_cpuhotplug). Tali funzionalità dipendono dalla configurazione del Kernel Linux, in particolare dall'attivazione dell'opzione CONFIG_HOTPLUG_CPU in fase di compilazione.

-Come nel caso dell’aumento della RAM il file yaml deve essere impostato per supportare un limit sul numero di socket (sockets -> requests  maxSockets -> limit)

Dal punto di vista applicativo, i cambiamenti si applicano nello stesso modo oc apply -f file_yaml

NB: Risulta estremamente complicato diminuire il numero di Socket, quindi il processo inverso viene sempre fatto in maniera “Cold”.

Aggiunta Disco:

Il processo di aggiungere un volume è il processo più semplice, perché vengono sfruttate al massimo le capacità di k8s di montare volumi all’interno di un pod in esecuzione.

Il processo è differente quasi del tutto diverso rispetto agli altri precedentemente affrontati.

Tranne per il Feature Gate e per il Sistema Operativo.

- Nel Feature Gate bisogna aggiungere la feature "HotPlugVolumes"

- Il Sistema Operativo deve supportare i moduli per l’Hotplug dei dischi (come pci_hotplug o acpiphp). Queste funzionalità dipendono dalla configurazione del Kernel Linux, in particolare dall'attivazione delle opzioni CONFIG_HOTPLUG_PCI e del supporto specifico per il bus o il controller utilizzato (es. CONFIG_SCSI)

Per il resto i requisiti sono completamenti diversi da quelli visti in precedenza.

-Non possiamo montare direttamente un PV, bisogna montare un PVC e lo storage class deve supportare la modalità di accesso corretta(principalmente ReadWriteOnce).

-Bisogna utilizzare il bus VirtIO-scsi per permettere l’HOTPLUG, utilizzando altri controller come per esempio il SATA, non è possibile l’HOTPLUG.
  Per best Practice il controller scsi viene definito attraverso gli ansible hook, durante la migrazione o manualmente (file YAML) all’interno della creazione della VM.

-L’ultimo requisito sono i permessi RBAC, l’utente che esegue l’operazione deve avere i permessi necessari per la creare/leggere un PVC e “patchare” la VM.

A differenza dei cambiamenti precedenti, per aggiungere un disco, non bisogna modificare il file YAML, ma bisogna utilizzare un comando tramite cli di OC.

Il comando è virtctl addvolume <nome-vm> --volume-name=<nome-pvc> --persist  
Il flag —persist rende il volume permanente e non temporaneo.

Parallelo con VMware:

Il parallelo con VMware è abbastanza netto.  Su VMware per aggiungere risorse alla VM, lo fai con un click all’interno della GUI di VMware, aggiungi banchi di RAM, aggiungi cores, aggiungere Socket e persino un HDD,SSD tutto a caldo, il processo è estremamente meno complesso rispetto a modificare una VM all’interno di un container.

Ovviamente ci sono dei vantaggi all’interno di un cluster OCP o K8s.

Il vantaggio principale sta nel opzioni di scalabilità. Su VMware la scalabilità è manuale, dipende dall’utente.
Mentre su OCP la scalabilità è automatica. Può sia essere orizzontale che verticale HPA/VPA.
