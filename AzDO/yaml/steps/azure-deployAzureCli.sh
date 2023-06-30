#!/bin/bash

# Copy the script below the --- dotted line
# Conversion to inline for yaml: 
# replace \ with \\
# replace " with \"
# replace a newline char with \n
# -------------------------------------------------------

deploymentName='$(deploymentName)'
deploymentMode='$(deploymentMode)'
deploymentLevel='$(deploymentLevel)'
outputVariableNamePrefix='$(outputVariableNamePrefix)'
parameterOverrides=$'$(parameterOverrides)'
resourceLocation='$(resourceLocation)'
resourceGroupName='$(resourceGroupName)'
templateFile='$(templateFile)'
templateParameterFile='$(templateParameterFile)'
showExpectedChanges=$(showExpectedChanges)
managementGroupId='$(managementGroupId)'

# Ensure Azure CLI is up to date. May generate warning, can be ignored
echo '##[section]Ensure Azure CLI is up to date'
exec 3>&2
exec 2> /dev/null
az bicep upgrade
exec 2>&3

# Path sanitizing for Linux
templateFile="${templateFile//\\//}"
templateParameterFile="${templateParameterFile//\\//}"

if [ "$deploymentName" == "" ]; then 
  deploymentName="$(date +%Y%m%d-%H%M%S)-deployment"
fi

params=""
if [ "$parameterOverrides" != "" ]; then 
  params+=$" --parameters $parameterOverrides"
fi
if [ "$templateParameterFile" != "" ]; then 
  params+=" --parameters \"$templateParameterFile\""
fi
{
  if [ $deploymentLevel == 'tenant' ]; then
    cmd="az deployment tenant create --location \"$resourceLocation\""
    outputsCmd="az deployment tenant show"
  elif [ $deploymentLevel == 'managementGroup' ]; then
    cmd="az deployment mg create --management-group-id \"$managementGroupId\" --location \"$resourceLocation\""
    outputsCmd="az deployment mg show --management-group-id \"$managementGroupId\""
  elif [ $deploymentLevel == 'subscription' ]; then
    cmd="az deployment sub create --location \"$resourceLocation\""
    outputsCmd="az deployment sub show"
  elif [ $deploymentLevel == 'resourceGroup' ]; then 
    cmd="az deployment group create --mode \"$deploymentMode\" --resource-group \"$resourceGroupName\""
    outputsCmd="az deployment group show --resource-group \"$resourceGroupName\""
  fi
  cmd="$cmd --name \"$deploymentName\" --template-file \"$templateFile\" $params"
  outputsCmd="$outputsCmd --name \"$deploymentName\" --query properties.outputs"
  echo "##[command]$cmd"
  if [[ "${showExpectedChanges,,}" == "true" ]]; then 
    echo '##[section]Template: expected changes'
    eval "$cmd --what-if -w"
  fi
  echo '##[section]Template: deployment'
  eval "$cmd"
  deploymentoutputs=$(eval "$outputsCmd")
} && {
  echo '##[section]Convert outputs to variables'
  echo $deploymentoutputs | jq -c '. | to_entries[] | [.key, .value.value, .value.type]' |
    while IFS=$"\n" read -r c; do
      keyname=$(echo "$c" | jq -r '.[0]')
      value=$(echo "$c" | jq -r '.[1]')
      type=$(echo "$c" | jq -r '.[2]')
      
      if [ "$type" == "SecureString" ]; then
        echo "##vso[task.setvariable variable=$outputVariableNamePrefix$keyname;issecret=true]$value"
        echo "Added variable '$outputVariableNamePrefix$keyname' ('$type') with secret value '******'"
      elif [ "$type" == "String" ]; then 
        echo "##vso[task.setvariable variable=$outputVariableNamePrefix$keyname]$value"
        echo "Added variable '$outputVariableNamePrefix$keyname' ('$type') with value '$value'"
      else 
        echo "##[warning]Skipped output variable conversion: Type '$type' is not supported for '$keyname'"
      fi
      
    done    
} 