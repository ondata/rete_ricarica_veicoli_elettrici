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

node "$folder"/rete_ricarica_veicoli_elettrici.js

# if "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl exists, delete it
if [ -f "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl ]; then
    rm "$folder"/output/rete_ricarica_veicoli_elettrici.jsonl
fi

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

