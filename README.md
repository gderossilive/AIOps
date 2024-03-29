# Demo di un Copilot per IT Operations 

Questa demo ha l'obiettivo di dimostrare come poter interrogare via copilot i dati utili al personale di operations e raccolti all'interno di Azure Monitor. I dati sono relativi a 2  risorse Azure:
- Un Azure Kubernetes Cluster (AKS)
- Una VM arc-enabled

I dati sono raccolti all'interno di Azure Monitor utilizzando Container Insights e VM Insigths.

## Prerequisiti

I prerequisiti per poter installare questa demo sono:
- Sottoscrizione Azure
- Licenze copilot studio
- Licenza Office 365

# Setup della demo

Il setup di questo copilot richiede una serie di passaggi:
- Setup delle risorse utili per la demo (AKS, VM, Log Analytics, etc.)
- Abilitazione Arc per la VM
- Installazione della Data Collection Rule (DCR) e le relative extensions sull'Arc-Enabled VM
- Setup del Copilot all'interno di Copilot Studio e PowerAutomate
- Pubblicazione del Copilot all'interno di Microsoft Teams

## 1- Setup delle risorse utili per la demo
Di seguito i passi principali eseguiti da questo script Azure CLI:

- Effettua l'accesso all'account Azure eseguendo il comando az login
- Attrverso il comando az account set sceglie la sottoscrizione dove installare la demo
- Genera una stringa casuale di 5 caratteri alfanumerici e la assegna alla variabile $Seed. Questa variabile viene utilizzata per rendere unici i nomi delle risorse create in Azure 
- Genera una password casuale di 15 caratteri utilizzando una combinazione di numeri e caratteri speciali e la assegna alla variabile $adminPassword. Verrà utilizzata come password dell'amministratore delle VM
- Assegna alla variabile $MyIP l'indirizzo IP pubblico dal quale si potrà accedere al Key Vault per leggere la password di administrator assegnata alla variabile $adminPassword 
- Imposta la variabile $location con il valore "northeurope" che sarà la regione di Azure che ospiterà le risorse della demo
- Assegna all'oggetto $MyObecjectId l'object id dell'utente che avrà il diritto di accedere alla password di amministratore protetta nel key vault
- Crea un nuovo resource group utilizzando il comando az group create, specificando il nome del gruppo come "$Seed-Demo" e la posizione come $location.
- Genera una chiave SSH utilizzando il comando az sshkey create e la assegna alla variabile $SSHPublickey.
- Esegue il comando az deployment sub create per creare l'infrastruttura di rete, il key vault, il cluster AKS, la VM che verrà poi abilitata con Azure Arc, il Log Analytics Workspace per la raccolta dei dati di monitoring. Vengono specificati i parametri necessari da passare all'ARM template per la sua esecuzione

### Esecuzione dello script RunMe - Phase1.azcli
- Effettuare il login su Azure
```azcli
    az login
```
- Posizionarsi all'interno della sottoscrizione nella quale si vuole creare lo scenario
```azcli
    az account set --subscription <ResourceId della tua sottoscrizione>
```
- Instanziare le 5 variabili sotto
```azcli
    $Seed=(-join ((48..57) + (97..122) | Get-Random -Count 3 | % {[char]$_}))
    $MyIP=<Inserisci il tuo IP>
    $location=<Inserisci la region di riferimento>
    $adminPassword=(-join ((48..59) + (63..91) + (99..123) | Get-Random -count 15 | % {[char]$_})) 
    $MyObecjectId=<Inserisci l'objectId del tuo utente> 
```
- Procedere con la creazione del Resource Group e delle chiavi SSH utili per la creazione dei nodi dell'AKS cluster
```azcli
    az group create --name "$Seed-Demo" --location $location
    $SSHPublickey=az sshkey create --name "SSHKey-$Seed" --resource-group "$Seed-Demo" --query "publicKey" -o json
```
- Posizionarsi nella directory dove sono presenti i file Bicep
- Lanciare il comando
```azcli
    az deployment sub create `
        --name "CoreDeploy-$Seed" `
        --location $location `
        --template-uri 'https://raw.githubusercontent.com/gderossilive/AIOps/main/ARM/Main.json' `
        --parameters `
            'https://raw.githubusercontent.com/gderossilive/AIOps/main/Parameters.json' `
            location=$location `
            Seed=$Seed `
            MyObjectId=$MyObecjectId `
            MyIPaddress=$MyIP `
            adminPassword=$adminPassword `
            SSHPublickey=$SSHPublickey `
            WinNum=1 
```



