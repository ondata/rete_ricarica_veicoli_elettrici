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

mkdir -p "$folder"/../data

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
