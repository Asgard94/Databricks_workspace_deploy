#!/bin/bash

while [[ "$#" -gt 0 ]]
do 
    case "${option}"
        in
        --db_path)databricks_code_path="$2"; shift;;
        --db_file)service_code_file="$2"; shift;;
    esac
done

echo "Databricks input code : $databricks_code_path"
echo "File config path   : $service_code_file"


file=$databricks_code_path/$service_code_file  
jq -c -r '.[]' $file | while read js_object; do 
    var_folder_path=$(jq -r '.folder_path' <<< "$js_object")

    echo "Item: $var_folder_path"

    var_output=$(databricks workspace ls $var_folder_path --absolute)

    if [ $? -ne 0 ]; then
        echo "Folder $var_folder_path not found. Proceeding to create it..."
        databricks workspace mkdirs $var_folder_path                
    else
        echo "Folder $var_folder_path already exists"
    fi              
done