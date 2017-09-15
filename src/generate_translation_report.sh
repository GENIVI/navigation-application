#!/bin/bash

command -v csvjoin >/dev/null 2>&1 || { echo >&2 "It requires csvjoin but it's not installed.  Aborting."; exit 1; }
filelist=""
columns="1,2"
counter=3
for file in hmi/translations/*.ts
do
  filename=${file##*/}
  lconvert -i "$file" -o build/hmi/hmi-launcher/"${filename%.*}.po"
  po2csv -i build/hmi/hmi-launcher/"${filename%.*}.po" -o build/hmi/hmi-launcher/"${filename%.*}.csv"
  sed -i "1s/.*/location,source,${filename%.*}/" build/hmi/hmi-launcher/"${filename%.*}.csv"
  filelist="$filelist build/hmi/hmi-launcher/"${filename%.*}.csv""
  columns="$columns,$counter"
  counter=$((counter+3))
done
csvjoin -c location  $filelist > temp.csv
csvcut -c $columns temp.csv > translation_report.csv
rm temp.csv



