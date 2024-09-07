#!/bin/bash

### requisiti ###
# gdal ogr https://gdal.org/programs/ogr2ogr.html
# Miller https://miller.readthedocs.io
### requisiti ###

### nota ###
# mlrgo, nello script sotto, è un alias per l'esguibile di Miller, che di default è mlr
### nota ###

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/output
mkdir -p "$folder"/../data/api

# if "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl exists, delete it
if [ -f "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl ]; then
    rm "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl
fi

# Abilita nullglob per evitare l'errore di "nessun file trovato" se non ci sono file
shopt -s nullglob

# Tentativi massimi
max_attempts=3
attempt=1

# Controllo e tentativi
while [ $attempt -le $max_attempts ]; do
    # Usa l'espansione degli array per evitare errori
    json_files=("$folder"/output/*.json)

    if [ ${#json_files[@]} -gt 0 ]; then
        echo "Trovati file JSON. Procedo..."
        break
    else
        echo "Nessun file JSON trovato. Eseguo il comando node (Tentativo $attempt di $max_attempts)..."
        node rete_ricarica_veicoli_elettrici.js
    fi

    attempt=$((attempt+1))

    if [ $attempt -gt $max_attempts ]; then
        echo "Nessun file JSON trovato dopo $max_attempts tentativi. Esco."
        exit 1
    fi
done

# Operazioni sui file JSON trovati
for i in "$folder"/output/*.json; do
    <"$i" jq -c '.content[]' >>"$folder"/output/rete_ricarica_veicoli_elettrici.jsonl
done

<"$folder"/output/rete_ricarica_veicoli_elettrici.jsonl jq -s 'sort_by(.evse_id)' >"$folder"/output/tmp.jsonl
mv "$folder"/output/tmp.jsonl "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl

# if "$folder"/../data/rete_ricarica_veicoli_elettrici_api.jsonl exists, move it to "$folder"/output
if [ -f "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl ]; then
  mv "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl "$folder"/../data/rete_ricarica_veicoli_elettrici_api.jsonl
  jq -s '.' "$folder"/../data/rete_ricarica_veicoli_elettrici_api.jsonl >"$folder"/../data/tmp.json
  flatterer --force "$folder"/../data/tmp.json "$folder"/../data/api
fi

mlrgo -I --csv cut -x -f _link then sort -t evse_id "$folder"/../data/api/csv/main.csv
