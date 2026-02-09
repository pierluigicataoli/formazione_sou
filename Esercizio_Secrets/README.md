Nella cartella si trovano i tre file di creazioni dei Secrets.

Ho creato 3 Secrets di diverso tipi.

I tipi in questione sono:
Opaque
kubernetes.io/basic-auth
kubernetes.io/ssh-auth

Ho creato i secrets con kubectl apply -f.

Per estrarre i secrets il comando è kubectl get secret nome-secret -o yaml, così però il risultato è codificato in base64, se vogliamo vedere la chiave in chiaro bisogna decodificarla con base64 --encode.
