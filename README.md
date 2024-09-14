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
- Un client con AzCLI e Kubectl installati ed aggiornati (si consiglia di utilizzare il codespace associato a questo repository)
- Quota disponibile per servizi Azure OpenAI per la propria sottoscrizione

# Setup della demo

Il setup di questo copilot richiede una serie di passi:
- Setup delle risorse infrastrutturali necessarie per la demo (AKS, VM, Log Analytics, etc.)
- Onboarding della VM su Azure Arc
- Onboarding della VM e del Cluster AKS in Azure Monitor
- Setup delle componenti Azure OpenAI
- Import e configurazione del Copilot e dei relativi flow in PowerAutomate
- Pubblicazione del Copilot all'interno di Microsoft Teams

## 1 - Setup delle risorse utili per la demo
## 1 - Setup delle risorse utili per la demo
Obiettivo di questo script è quello di fare il setup delle seguenti componenti:
- un Resource Group che conterrà tutte le risorse Azure utilizzate dalla demo
- una coppia di chiavi SSH per l'accesso sicuro ai nodi del cluster AKS
- una Virtual Network sulla quale saranno attestate la VM ed il cluster AKS
- un Bastion per l'accesso sicuro ala VM
- un Key Vault che custodirà in modo sicuro la password di admin per la VM, l'API-Key per l'accesso ad Azure OpenAI ed il secret dei service principal utilizzato dal Copilot per accedere alle risorse Azure
- un Log Analytics Workspace per la raccolta delle metriche e dei log delle risorse
- un Azure OpenAI service

Di seguito i passi principali da eseguire:
- Rinominare il file .env.example in .env e personalizzarlo con i propri valori per
    - MyObecjectId ovvero l'Entra ID Object ID dell'utente che eseguirà gli script in Azure
    - MySubscriptionId ovvero l'ID della sottoscrizione dove verranno ospitate le componenti Azure delle demo
    - location la regione di Azure che ospiterà le componenti delle demo
- Eseguire lo script "RunMe - Step1.azcli"

Le operazioni compiute dallo script sono:
- Carica le variabili memorizzate all'interno del file .env
- Effettua l'accesso all'account Azure eseguendo il comando az login
- Attrverso il comando az account set sceglie la sottoscrizione dove installare la demo
- Genera una stringa casuale di 5 caratteri alfanumerici e la assegna alla variabile $Seed. Questa variabile viene utilizzata per rendere unici i nomi delle risorse create in Azure 
- Genera una password casuale di 15 caratteri utilizzando una combinazione di numeri e caratteri speciali e la assegna alla variabile $adminPassword. Verrà utilizzata come password dell'amministratore delle VM
- Crea un nuovo resource group utilizzando il comando az group create, specificando il nome del gruppo come "$Seed-Demo" e la posizione come $ENV:location.
- Genera una chiave SSH utilizzando il comando az sshkey create e la assegna alla variabile $SSHPublickey.
- Esegue il comando az deployment sub create per creare l'infrastruttura di rete, il key vault, il cluster AKS, la VM che verrà poi abilitata con Azure Arc, il Log Analytics Workspace per la raccolta dei dati di monitoring. Vengono specificati i parametri necessari da passare all'ARM template per la sua esecuzione

## 2 - Onboarding Arc della VM
## 2 - Onboarding Arc della VM
L'obiettivo di questo script è automatizzare il più possibile l'onboarding di una VM su Azure Arc. Inizia perciò con la creazione di un service principal, gli assegna il ruolo "Azure Connected Machine Onboarding" e finisce fornendo le istruzioni per completare l'onboarding

Di seguito i passi principali da eseguire:
- Eseguire lo script "RunMe - Step2.azcli"
- Copiare il comando dato in output dallo script
- collegarsi alla VM DC-1 creata al passo precedente
    - Selezionare la VM DC-1
    - Selezionare Bastion
    - Alla voce 'Authentication Type' scegliere l'opzione 'Passworkd from Azure Key Vault'
    - Come username utilizzare 'gdradmin'
    - In 'Azure Key Vault' scegliere il Key Vault appena creato
    - In Azure Key Vault Secret, scegliere 'adminPassword'
- Eseguire il comando dato in output dallo script all'interno di una Powershell
- Verificare all'interno del portale di Azure che l'onboarding della VM in Arc sia avvenuto correttamente

## 3 - Onboarding della VM e del Cluster AKS in Azure Monitor
## 3 - Onboarding della VM e del Cluster AKS in Azure Monitor
L'obiettivo di questo script è:
- Attivare VM Insights sull'Arc enabled VM
- Attivare Container Insights sul'Azure Kubernetes Service cluster

Per far questo basta eseguire lo script "RunMe - Step3.azcli"

Le operazioni compiute dallo script sono:
- Crea 2 DCR: DCR-VM e DCR-AKS
- Associa la DCR-VM alla VM ed associa la DCR DCR-AKS al cluster AKS
- Abilita Container Insights sul cluster AKS
- Carica un'applicazione di prova (pets store) sul cluster AKS
- Abilita VM Insights sulla VM

## 4 - Setup delle componenti Azure OpenAI
L'obiettivo dello script è:
- Creare un servizio Azure OpenAI
- Creare un deployment di un modello GPT 3.5 Turbo

Le operazioni principali compiute della script sono:

## Import del Copilot all'interno di Copilot Studio via PowerAutomate
Questo passaggio verrà eseguito all'interno di Powerautomate. Quindi si cosiglia di aprire il borwser ed inserire l'indirizzo: https://make.powerautomate.com ed autenticarsi con le credenziali di amministratore del tenant

### Import della Solution
Per poter importare la Solution sono necessari 3 passaggi: import delle 2 connectione reference (Azure Key Vault, Azure Monitor) ed infine l'import del Copilot. Per partire basta cliccare su 'Import solution'

#### Import della prima connection reference (Azure Key Vault)
- Cliccare su Browse e scegliere il file zip contenente la Solution 'Files/OpsCopAkvConn_1_0_0_2.zip' e cliccare Open
- Cliccare Next
- Cliccare Next
- Cliccare sui tre puntini (...) e selezionare "+Add new connection"
    - Authentication type: selezionare Service Principal authentication
    - Per i campi successivi, inserire i valori corrispondanti presi dall'output dello Step4 (Client ID, Client Secret, Tenant ID, Key vault name)
    - Terminare cliccando create
- Cliccare Import
- Aspettare che l'operazione di import finisca e verificare il successo dell'operazione

#### Import della seconda connection reference (Azure Monitor)
- Cliccare su Browse e scegliere il file zip contenente la Solution 'Files/OpsCopAzMonConn_1_0_0_2.zip' e cliccare Open
- Cliccare Next
- Cliccare Next
- Cliccare sui tre puntini (...) e selezionare "+Add new connection"
    - Authentication type: selezionare Service Principal authentication
    - Per i campi successivi, inserire i valori corrispondanti presi dall'output dello Step4 (Client ID, Client Secret, Tenant ID)
    - Terminare cliccando create
- Cliccare Import
- Aspettare che l'operazione di import finisca e verificare il successo dell'operazione

#### Import del Copilot
- Cliccare su Browse e scegliere il file zip contenente la Solution 'Files/OpsCopBot_1_0_0_2.zip' e cliccare Open
- Cliccare Next
- Cliccare Import
- Aspettare che l'operazione di import finisca e verificare il successo dell'operazione

### Verifca dell'import
Per verificare che l'import sia finito con successo, bisognerà collegarsi a https://copilotstudio.preview.microsoft.com/ e visualizzare un nuovo Copilot chiamato 'Operations' nella sezione Copilots selezionabile in alto a sinistra

Cliccando sul nome del Copilot (Operations) e poi su Topics si potrà vedere la lista dei Topics custom creati per questo copilot (AKS Health Check, Anomalies v2, CMDBv2, Connections, DCs Health, Metrics e Patching)

### Configurazione del Copilot
Per configurare il Copilot, cliccare su 'System (8)' in alto e poi sul topic 'Conversation Start' 

Qui troveremo 8 box del tipo 'Set variable value' sulle quali fare le seguenti operazioni:
1) Global.ServerName: verificare che il valore sia 'DC-1'
2) Global.LAWName: inserire il 'Log Analytics Workspace Name' recuparato alla fine dello Step4
3) Global.RGName inserire il 'Resource Group Name' recuparato alla fine dello Step4
4) Global.TenantId inserire il 'Tenant ID' recuparato alla fine dello Step4
5) Global.SPId inserire il 'Client ID' recuparato alla fine dello Step4
6) Global.KVName inserire il 'Key Vault Name' recuparato alla fine dello Step4
7) Global.OAIService inserire il 'OpenAI Service Name' recuparato alla fine dello Step4
8) Global.OAIDeployment inserire il 'OpenAI Deployment Name' recuparato alla fine dello Step4

Dopo aver modificato gli 8 valori:
- Cliccare Save in alto a destra 
- Ricaricare il copilot cliccando sulla freccia circolare accanto alla scritta Chat (debug mode)

### Verifica del corretto funzionamento del Copilot
Per testare il corretto funzionamento dei diversi flussi, inserire le seguenti richieste all'interno della finestra chat del Copilot
- Give a descritpion for my environment
- Give a descritpion for my environment in Italian
- Give me the health check status for my AKS
- Give me my DCs' health check
- Check DC anomalies
- Which metrics are you able to manage?
- I want to check network connections status on my servers
- What about missed patches?

### Pubblicare il Copilot in Teams
Per pubblicare il Copilot in Teams:
- Cliccare sulla sezione Publish del Copilot Studio
- Cliccare il bottono Publish e confermare nella finestra di verifica
- Attendere che il processo finisca con successo
- Cliccare sul link "Go to channels"
- Selezionare "Microsoft Teams"
- Se è la prima volta che si accede a questa sezione bisognerà cliccare il bottonone "Turn on Teams"
- Cliccare il bottono "Availability options"
- Cliccare il bottone "Download .zip" e salvare il file in locale
- Aprire Teams seguendo il link "https://teams.microsoft.com/"
- Cliccare sulla sezione "Apps" nel menù di sinistra
- Cliccare su "Manage your apps"
- Cliccare su "Upload an app" 
- Selezionare "Upload an app to yuor org's app catalog"
- Selezionare il file salvato in locale e cliccare "Open"
- Al termine del caricamento dell'App verrà visualizzata nell'elenco delle App disponibili
- Cliccare sull'App e poi sul bottone "Open"
- Si apre la chat con il Copilot dove comparirà il messaggio di benvenuto
- A questo punto si può verificare il corretto funzionamento del Copilot utilizzando le stesse richieste riportate nel paragrafo "Verifica del corretto funzionamento del Copilot"



