deploymentName='$(deploymentName)'
templateParameterFile='$(templateParameterFile)'
parameterOverrides="$(parameterOverrides)"
resourceGroupName='$(resourcegroupName)'
resourceLocation='$(resourceLocation)'
templateFile='$(templateFile)'
outputVariableNamePrefix='$(outputVariableNamePrefix)'

if [ "$deploymentName" == "" ]; then 
  deploymentName="$(date +%Y%m%d-%H%M%S)-deployment"
fi

params=""
if [ "$parameterOverrides" != "" ]; then 
  params+=" --parameters $parameterOverrides"
fi
if [ "$templateParameterFile" != "" ]; then 
  params+=" --parameters @$templateParameterFile"
fi

if [ "$resourceGroupName" == "" ]; then
  az deployment sub create \
    --name $deploymentName \
    --location $resourceLocation \
    --template-file $templateFile \
    $params

    echo "az deployment sub show --name $deploymentName"
    deploymentoutputs=$(az deployment sub show --name $deploymentName \
      --query properties.outputs)
elif [ "$resourceLocation" == "" ]; then

  az deployment group create \
    --name $deploymentName \
    --resource-group $resourceGroupName \
    --template-file $templateFile \
    $params

    echo "az deployment group show --resource-group $resourceGroupName --name $deploymentName"
    deploymentoutputs=$(az deployment group show --resource-group $resourceGroupName --name $deploymentName \
      --query properties.outputs)
else
  echo "Specify either ResourceGroup or ResourceLocation."
  exit 1
fi

echo 'convert outputs to variables'
echo $deploymentoutputs | jq -c '. | to_entries[] | [.key, .value.value, .value.type]' |
  while IFS=$"\n" read -r c; do
    keyname=$(echo "$c" | jq -r '.[0]')
    value=$(echo "$c" | jq -r '.[1]')
    type=$(echo "$c" | jq -r '.[2]')
    
    if [ "$type" == "SecureString" ]; then
      echo "##vso[task.setvariable variable=$outputVariableNamePrefix$keyname;issecret=true]$value"
      echo "Added variable '$keyname' ('$type')"
    elif [ "$type" == "String" ]; then 
      echo "##vso[task.setvariable variable=$outputVariableNamePrefix$keyname]$value"
      echo "Added variable '$keyname' ('$type') with value '$value'"
    else 
      echo "Skipped output variable conversion: Type '$type' is not supported for '$keyname'"
    fi
    
  done