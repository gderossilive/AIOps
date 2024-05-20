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

