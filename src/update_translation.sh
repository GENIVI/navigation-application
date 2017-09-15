#!/bin/bash

lupdate hmi/translations/translating-qml.pro
for file in hmi/translations/*.ts
do
  filename=${file##*/}
  lrelease -markuntranslated ? "$file" -qm build/hmi/hmi-launcher/"${filename%.*}.qm"
done
