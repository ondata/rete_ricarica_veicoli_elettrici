#!/bin/bash

### requisiti ###
# gdal ogr https://gdal.org/programs/ogr2ogr.html
# Miller https://miller.readthedocs.io
# duckdb https://duckdb.org
### requisiti ###

### nota ###
# mlrgo, nello script sotto, è un alias per l'esguibile di Miller, che di default è mlr
### nota ###

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../data
mkdir -p "${folder}"/output/

URL="https://services2.arcgis.com/pROHh69WvVijk4nR/ArcGIS/rest/services/IdR_latest_ready/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token="

# scarica dati e converti in CSV
ogr2ogr -f CSV -lco GEOMETRY=AS_XY  "$folder"/../data/rete_ricarica_veicoli_elettrici.csv  "$URL" OGRGeoJSON

# ordina i dati per ID_univoco_EVSE, così il diff del versioning sarà più lite
mlrgo -S -I --csv sort -f ID_univoco_EVSE "$folder"/../data/rete_ricarica_veicoli_elettrici.csv

### cleaned_data ###

# copia il file originale in un nuovo file
cp -f "$folder"/../data/rete_ricarica_veicoli_elettrici.csv "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv

characters=("Ã¨" "Ã©" "Ã¹" "Ã²" "Ã¬" "Ãª" "Ã")
replacements=("è" "é" "ù" "ò" "ì" "ê" "à")

# Cicla attraverso gli array per eseguire le sostituzioni (vedi #1)
for ((i=0; i<${#characters[@]}; i++)); do
    sed -i "s/${characters[i]}/${replacements[i]}/g" "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv
done

# rimuovi NBSP (Non-breaking space)
sed -i 's/\xc2\xa0/ /g' "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv
# rimuovi spazi ridondanti
mlrgo -I -S --csv clean-whitespace "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv

# normalizza i nomi delle colonne (vedi #4)
duckdb --csv -c "SELECT * from read_csv('$folder/../data/rete_ricarica_veicoli_elettrici_cleaned.csv',normalize_names=true,all_varchar=true)" >"$folder"/../data/tmp.csv
mv "$folder"/../data/tmp.csv "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv
mlrgo -S -I --csv cat "$folder"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv

# correggere nomi regione (vedi #7)
mlrgo -S -I --csv put '$regione_cleaned=$regione' then sub -f regione_cleaned "Trentino.*" "Trentino-Alto Adige/Südtirol" then \
sub -f regione_cleaned "Valle.*" "Valle d'Aosta/Vallée d'Aoste" then \
sub -f regione_cleaned "Friuli.*" "Friuli-Venezia Giulia" "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv


# correggere nomi comuni (vedi #8)
mlrgo -S -I --csv put '$comune_cleaned=$comune' "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv


while read -r line; do
  regione=$(echo "$line" | jq -r '.regione')
  comune=$(echo "$line" | jq -r '.comune')
  comune_cleaned=$(echo "$line" | jq -r '.comune_cleaned')
  mlrgo -I -S --csv put 'if ($regione_cleaned == "'"$regione"'" && $comune_cleaned == "'"$comune"'"){ $comune_cleaned = "'"$comune_cleaned"'"}else{$comune_cleaned=$comune_cleaned}' "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv
done < "${folder}"/../data/risorse/comuni.jsonl

# aggiungi colonna con codice comune formato alfanumerico
mlrgo --csv cut -f regione_cleaned,comune_cleaned then uniq -a "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv > "${folder}"/output/rete_ricarica_veicoli_elettrici_cleaned.csv

duckdb --csv -c "SELECT A.*,B.codice_comune_formato_alfanumerico from read_csv('${folder}/output/rete_ricarica_veicoli_elettrici_cleaned.csv',all_varchar=true) A
JOIN read_csv('${folder}/../data/risorse/Elenco-comuni-italiani.csv',all_varchar=true) B
ON LOWER(A.regione_cleaned) = LOWER(B.denominazione_regione) AND LOWER(A.comune_cleaned) = LOWER(B.denominazione_in_italiano)" >"${folder}"/output/tmp.csv

#csvmatch "${folder}"/output/rete_ricarica_veicoli_elettrici_cleaned.csv "${folder}"/../data/risorse/Elenco-comuni-italiani.csv --fields1 regione_cleaned comune_cleaned --fields2 denominazione_regione denominazione_in_italiano  -i -a -n --join left-outer --output 1.regione_cleaned 1.comune_cleaned 2.codice_comune_formato_alfanumerico >"${folder}"/output/tmp.csv

mlrgo -S --csv join --ul -j regione_cleaned,comune_cleaned -f "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv  then unsparsify then sort -f id_univoco_evse then reorder -e -f regione_cleaned,comune_cleaned,codice_comune_formato_alfanumerico "${folder}"/output/tmp.csv >"${folder}"/output/rete_ricarica_veicoli_elettrici_cleaned_istat.csv

mv "${folder}"/output/rete_ricarica_veicoli_elettrici_cleaned_istat.csv "${folder}"/../data/rete_ricarica_veicoli_elettrici_cleaned.csv

### Dati sulle automobili elettriche ###

URL_auto="https://services2.arcgis.com/pROHh69WvVijk4nR/ArcGIS/rest/services/Province_Italiane_BEV/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token="

# scarica dati e converti in CSV
ogr2ogr -f CSV  "$folder"/../data/immatricolazioni_auto_provincia.csv  "$URL_auto" OGRGeoJSON

URL_serie_auto="https://services2.arcgis.com/pROHh69WvVijk4nR/ArcGIS/rest/services/Distribuzione_BEV_HYB_grafico/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pgeojson&token="

# scarica dati e converti in CSV
ogr2ogr -f CSV  "$folder"/../data/serie_storica_immatricolazioni_nazionali.csv  "$URL_serie_auto" OGRGeoJSON
