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

## Setup delle risorse utili per la demo

