#!/bin/bash 
file="./util/deploy/notebook.json"

jq -c -r '.[]' $file | while read js_object; do 
  #echo $js_object
  val_folder=$(jq -r '.folder' <<< "$js_object")
  val_name=$(jq -r '.name' <<< "$js_object")
  val_type=$(jq -r '.type' <<< "$js_object")
  echo "item: $val_folder, $val_name, $val_type"
done