# Intro

A fine marzo 2024 è stata messa online la [**Piattaforma Unica Nazionale dei punti di ricarica per i veicoli elettrici**](https://www.piattaformaunicanazionale.it/), in cui sono visualizzabili su mappa o in elenchi - e **non anche come dati grezzi e aperti** - i punti di ricarica per veicoli elettrici presenti in Italia.

Lo saranno in futuro? Non è dato saperlo, ma è molto probabile che avvenga, perché lo prevedono le norme e lo raccomanda il buon senso.<br>
Abbiamo fatto una segnalazione in tal senso al [**Difensore Civico per il Digitale**](https://ondata.github.io/guida-diritti-cittadinanza-digitali/parte-seconda/tutela-dei-diritti/).

➡️ Finché le [API](#le-api) saranno accessibili aggiorneremo i dati nella cartella [`data`](data).

Nota bene: nei dati sorgente c'è un problema di codifica dei caratteri (evidente con i caratteri accentati).

## Le API

Navigando il sito con un _browser_ (vedi immagine sotto), si legge in chiaro che i dati sono esposti tramite API.

In particolare, leggendo gli URL delle API, si vede che si tratta di un *ArcGIS REST Service*, che sono direttamente e comodamente leggibili con [**GDAL/OGR**](https://gdal.org/drivers/vector/esrijson.html).

![](immagini/browser_api.png)
