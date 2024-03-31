# Cartella script

Questa cartella contiene gli script che estraggono i dati dalla [**Piattaforma Unica Nazionale dei punti di ricarica per i veicoli elettrici**](https://www.piattaformaunicanazionale.it/) e li rendono disponibili nella cartella [`data`](../data/README.md).

L'unico script che descriviamo brevemente qui è [`rete_ricarica_veicoli_elettrici.sh`](#rete_ricarica_veicoli_elettricish). Gli altri al momento sono soltanto dei test.

## rete_ricarica_veicoli_elettrici.sh

[`rete_ricarica_veicoli_elettrici.sh`](rete_ricarica_veicoli_elettrici.sh) è uno script `bash` basato su [GDAL](https://gdal.org/programs/ogr2ogr.html), [Miller](https://miller.readthedocs.io) e [DuckDB](https://duckdb.org/).:

- GDAL viene usato per puntare alle API *ArcGIS REST Service* che alimenta la piattaforma e scaricare i dati in formato CSV;
- Miller e DuckDB per operazioni di strutturazione e pulizia dei dati grezzi.
