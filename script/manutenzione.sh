#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/output

mlrgo --csv cut -f regione_cleaned,comune_cleaned then uniq -a "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv > "${folder}"/output/rete_ricarica_veicoli_elettrici__regioni_comuni.csv

exit 0

csvmatch ./output/rete_ricarica_veicoli_elettrici_cleaned.csv ../data/risorse/Elenco-comuni-italiani.csv --fields1 regione_cleaned comune_cleaned --fields2 denominazione_regione denominazione_in_italiano --fuzzy levenshtein -r 0.90 -i -a -n --join left-outer --output 1.regione_cleaned 1.comune_cleaned 2.codice_comune_formato_alfanumerico 2.denominazione_regione 2.denominazione_in_italiano | vd -f csv
