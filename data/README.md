# Note

Ogni giorno, intorno alle 4 di mattina, viene cercato un nuovo aggiornamento.

Alcune note:

- il file [`rete_ricarica_veicoli_elettrici.csv`](rete_ricarica_veicoli_elettrici.csv) è il file grezzo scaricato dalla Piattaforma Unica Nazionale dei punti di ricarica per i veicoli elettrici;
- il file [`rete_ricarica_veicoli_elettrici_cleaned.csv`](rete_ricarica_veicoli_elettrici_cleaned.csv), è una versione in cui sono state applicate delle modifiche migliorative al precedente:
  - corretti caratteri accentati (vedi [issue #1](https://github.com/ondata/rete_ricarica_veicoli_elettrici/issues/1))
  - normalizzati i nomi delle colonne: rimossi spazi, tutto in minuscolo, rimossi caratteri accentati, ... (vedi [issue #4](https://github.com/ondata/rete_ricarica_veicoli_elettrici/issues/4))
  - aggiunta colonna con nome regione corretto, `Trentino-Alto Adige/Südtirol` per `Trentino-Alto Adige`, ecc. (vedi [issue #7](https://github.com/ondata/rete_ricarica_veicoli_elettrici/issues/7))
  - aggiunta colonna con nome comune corretto, `Montagna sulla strada del vino` per `Montagna`, ecc. (vedi [issue #7](https://github.com/ondata/rete_ricarica_veicoli_elettrici/issues/7))

La fonte di questi dati è la [**Piattaforma Unica Nazionale dei punti di ricarica per i veicoli elettrici**](https://www.piattaformaunicanazionale.it/).
