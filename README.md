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
- Quota disponibile per servizi Azure OpenAI nella propria sottoscrizione

# Setup della demo

Il setup di questo copilot richiede una serie di passi:
- Setup delle risorse infrastrutturali necessarie per la demo (AKS, VM, Log Analytics, etc.)
- Onboarding della VM su Azure Arc
- Onboarding della VM e del Cluster AKS in Azure Monitor
- Setup delle componenti Azure OpenAI
- Import e configurazione del Copilot e dei relativi flow in PowerAutomate
- Pubblicazione del Copilot all'interno di Microsoft Teams

## 1- Setup delle risorse utili per la demo
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

## 2- Onboarding Arc della VM
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

## 3- Onboarding della VM e del Cluster AKS in Azure Monitor
L'obiettivo di questo script è:
- Attivare VM Insights sull'Arc enabled VM
- Attivare Container Insights sul'Azure Kubernetes Service cluster

Per far questo basta eseguire lo script "RunMe - Step3.azcli"

Le operazioni compiute dallo script sono:
- Creare 2 DCR (una per la VM Arc-enabled e l'altra per il cluster AKS) per inviare i performance counter verso il Log Analytics Workspace 
- Installare un'applicazione d'esempio all'interno del cluster AKS (pets-store)
- Installare 2 extension all'interno della VM Arc-enabled (AMA+Dependency Agent)
- Eseguire il patch assessment sulla VM Arc-enabled

# 4- Setup del Modello GPT-3.5-Turbo
L'obiettivo di questo script è:
- Creare un'utenza applicativa per il Copilot
- Creare un modello GPT-3.5-Turbo utilizzato in seguito dal Copilot

Per far questo basta eseguire lo script "RunMe - Step4.azcli"

Le operazioni compiute dallo script sono:
- Creazione di un utenza per il Copilot con ruolo di Reader sul resource group creato durante questa installazione
- Concedere l'accesso al Key Vault per l'utenza del Copilot
- Creazione di un Open AI Service + deployment
- Stampa dell'output dell'intero deployment con i dettagli per
    - Utenza del Copilot
    - Secret dell'utenza del Copilot
    - TenantId del MS Entra Id
    - Nome del Key Vault
    - Nome del Log Analytics Workspace
    - Nome dell'Azure OpenAI Service
    - Nome del'Azure OpenAI Deployment
Si consiglia di salvarsi queste informazioni perché saranno utilizzate nel passi successivi del deployment

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