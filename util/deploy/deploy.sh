#!/bin/bash

########### Capture parameters ###########
# dep_type: deploy type, possible values ["code", "jobs"]
# dtb_path: databricks folder path, repo route where json config file is located
# dtb_file: databricks config file, name of the json config file used for the deployment
while [[ "$#" -gt 0 ]]
do 
    case $1 in
        --dep_type)deploy_type="$2"; shift;;
        --dtb_path)databricks_code_path="$2"; shift;;
        --dtb_file)service_code_file="$2"; shift;;
        --dtb_host)databricks_host="$2"; shift;;
        --dtb_token)databricks_token="$2"; shift;;
    esac
    shift
done

echo "Databricks input code: $databricks_code_path"
echo "File config path: $service_code_file"

file=$databricks_code_path/$service_code_file  

########### Validate existence and deploy workspace folders ###########
function workspace_deploy(){
    echo "########## Initiating workspace deployment ##########"
    # Iterate over json array from config file
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
    echo "########## End of workspace deployment ##########"
}

########### Deploy notebooks in given folders ###########
function code_deploy(){
    echo "########## Initiating code deployment ##########"
    # Iterate over json array from config file
    jq -c -r '.[]' $file | while read js_object; do 
        var_action=$(jq -r '.action' <<< "$js_object")
        var_file_type=$(jq -r '.file_type' <<< "$js_object")
        var_file_extension=$(jq -r '.file_extension' <<< "$js_object")
        var_file_name=$(jq -r '.file_name' <<< "$js_object")
        var_folder_path=$(jq -r '.folder_path' <<< "$js_object")

        echo "Item: $var_folder_path, $var_file_name, $var_file_type"

        databricks workspace import ./src/deploy/$var_file_type/$var_file_name$var_file_extension $var_folder_path/$var_file_name --language $var_file_type --overwrite
    done
    echo "########## End of code deployment ##########"
}

########### Check and Deploy new/existing jobs ###########
function job_check(){
    while [[ "$#" -gt 0 ]]
    do 
        case $1 in
            -n|--name)job_name="$2"; shift;;
        esac
        shift
    done

    #echo "########## Listing current jobs ##########"
    #var_jobs=$(databricks jobs list)
    #for value in "${var_jobs[@]}"
    #do
    #echo "Job Name: $value"
    #done

    echo "########## Verify if job exists based on name ##########"
    curl -H "Authorization: Bearer ${databricks_token}" "${databricks_host}/api/2.1/jobs/list?name=${job_name}" > jobslist.txt
    var_exist=$(cat jobslist.txt | jq '.jobs[0].job_id')

    id_array=()
    if [ "$var_exist" = "null" ]; then
        echo "Job does not exist. Proceeding to create it"
    else
        id_array=$(cat jobslist.txt | jq '.jobs[] |.job_id')
        for value in "${id_array[@]}"
        do
        echo "Job Id: $value"
        done
    fi

    id_size=${#id_array[@]}
}

function job_deploy(){
    echo "########## Initiating job deployment ##########"
    # Iterate over json array from config file
    jq -c -r '.[]' $file | while read js_object; do 
        var_name=$(jq -r '.name' <<< "$js_object")

        echo "Item: $var_name"
        echo "$js_object" > job_def.json

        job_check -n $var_name

        if [ $id_size -eq 0 ]; then
            echo "Creating the job"
            databricks jobs create --json-file job_def.json
        elif [ $id_size -eq 1 ]; then
            echo "Updating the job"
            databricks jobs reset --job-id ${id_array[0]} --json-file job_def.json
        else
            echo "Multiple jobs with same name. Please verify"
        fi
        done
    echo "########## End of job deployment ##########"
}

function job_deploy_dir(){
    echo "########## Initiating job deployment ##########"
    # Iterate over json array from config file
    jq -c -r '.[]' $file | while read js_object; do 
        var_job_name=$(jq -r '.job_name' <<< "$js_object")
        var_file_path=$(jq -r '.local_file_path' <<< "$js_object")

        echo "Item: $var_job_name"

        job_check -n $var_job_name

        if [ $id_size -eq 0 ]; then
            echo "Creating the job"
            databricks jobs create --json-file $var_file_path
        elif [ $id_size -eq 1 ]; then
            echo "Updating the job"
            databricks jobs reset --job-id ${id_array[0]} --json-file $var_file_path
        else
            echo "Multiple jobs with same name. Please verify"
        fi
        done
    echo "########## End of job deployment ##########"
}

########### Call a function according to deploy type parameter ###########
if [ "$deploy_type" = "code" ]; then
    code_deploy
elif [ "$deploy_type" = "jobs" ]; then
    #job_deploy
    job_deploy_dir
else
    workspace_deploy
fi