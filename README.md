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
- Onboarding Arc della VM
- Installazione della Data Collection Rule (DCR) e le relative extensions sull'Arc-Enabled VM
- Import del Copilot all'interno di Copilot Studio via PowerAutomate
- Pubblicazione del Copilot all'interno di Microsoft Teams

## 1- Setup delle risorse utili per la demo
Di seguito i passi principali eseguiti da questo script Azure CLI:

- Effettua l'accesso all'account Azure eseguendo il comando az login
- Attrverso il comando az account set sceglie la sottoscrizione dove installare la demo
- Genera una stringa casuale di 5 caratteri alfanumerici e la assegna alla variabile $Seed. Questa variabile viene utilizzata per rendere unici i nomi delle risorse create in Azure 
- Genera una password casuale di 15 caratteri utilizzando una combinazione di numeri e caratteri speciali e la assegna alla variabile $adminPassword. Verrà utilizzata come password dell'amministratore delle VM
- Assegna alla variabile $MyIP l'indirizzo IP pubblico dal quale si potrà accedere al Key Vault per leggere la password di administrator assegnata alla variabile $adminPassword 
- Imposta la variabile $ENV:location con il valore "northeurope" che sarà la regione di Azure che ospiterà le risorse della demo
- Assegna all'oggetto $MyObecjectId l'object id dell'utente che avrà il diritto di accedere alla password di amministratore protetta nel key vault
- Crea un nuovo resource group utilizzando il comando az group create, specificando il nome del gruppo come "$Seed-Demo" e la posizione come $ENV:location.
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
    $ENV:location=<Inserisci la region di riferimento>
    $adminPassword=(-join ((48..59) + (63..91) + (99..123) | Get-Random -count 15 | % {[char]$_})) 
    $MyObecjectId=<Inserisci l'objectId del tuo utente> 
```
- Procedere con la creazione del Resource Group e delle chiavi SSH utili per la creazione dei nodi dell'AKS cluster
```azcli
    az group create --name "$Seed-Demo" --location $ENV:location
    $SSHPublickey=az sshkey create --name "SSHKey-$Seed" --resource-group "$Seed-Demo" --query "publicKey" -o json
```
- Posizionarsi nella directory dove sono presenti i file Bicep
- Lanciare il comando
```azcli
    az deployment sub create `
        --name "CoreDeploy-$Seed" `
        --location $ENV:location `
        --template-uri 'https://raw.githubusercontent.com/gderossilive/AIOps/main/ARM/Main.json' `
        --parameters `
            'https://raw.githubusercontent.com/gderossilive/AIOps/main/Parameters.json' `
            location=$ENV:location `
            Seed=$Seed `
            MyObjectId=$MyObecjectId `
            MyIPaddress=$MyIP `
            adminPassword=$adminPassword `
            SSHPublickey=$SSHPublickey `
            WinNum=1 
```

## Onboarding Arc della VM
L'obiettivo di questos cript è automatizzare il più possibile l'onboarding di una VM su Azure Arc. Inizia perciò con la creazione di un service principal, gli assegna il ruolo "Azure Connected Machine Onboarding" e finisce fornendo le istruzioni per completare l'onboarding

### Esecuzione dello script RunMe - Phase1.azcli
```azcli
    # Retrieve TenantID, SubscriptionID and SubscriptionName
    $tenantID=$(az account show --query tenantId -o tsv)
    $subscriptionID=$(az account show --query id -o tsv)
    $subscriptionName=$(az account show --query name -o tsv)

    # Create a service principal for the Arc resource group using a preferred name and role
    $ArcSp_pwd=az ad sp create-for-rbac --name "ArcDeploySP-$Seed" `
                            --role "Azure Connected Machine Onboarding" `
                            --scopes "/subscriptions/$subscriptionID/resourceGroups/$Seed-Demo" `
                            --query "password" -o tsv
    $ArcSp_id=az ad sp list --filter "displayname eq 'ArcDeploySP-$Seed'" --query "[0].appId" -o tsv
    az role assignment create --assignee $ArcSp_id --role "Kubernetes Cluster - Azure Arc Onboarding" --scope "/subscriptions/$subscriptionID/resourceGroups/$Seed-Demo"
```
## Import del Copilot all'interno di Copilot Studio via PowerAutomate

### Import della Solution
Per poter importare la Solution è necessario:

- Selezionare Solutions
- Cliccare su 'Import solution'
- Cliccare su Browse e scegliere il file zip contenente la Solution 'Files/OpsCopBot_1_0_0_2.zip'
- Cliccare Next
- Cliccare Next
- Per ogni Connection scegliere quella corrispondete precedentemente creata
- Cliccare Import
- Aspettare che l'operazione di import finisca

### Verifca dell'import a configurazione del Copilot
Se l'import è finito con successo, basterò andare su https://copilotstudio.preview.microsoft.com/ per vedere il copilot Operations appena creato.

Per la configurazione del Copilot:

