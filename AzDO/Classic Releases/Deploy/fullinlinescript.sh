deploymentName='$(deploymentName)'
deploymentMode='$(deploymentMode)'
deploymentLevel='$(deploymentLevel)'
outputVariableNamePrefix='$(outputVariableNamePrefix)'
parameterOverrides='$(parameterOverrides)'
resourceLocation='$(resourceLocation)'
resourceGroupName='$(resourcegroupName)'
templateFile='$(templateFile)'
templateParameterFile='$(templateParameterFile)'

# Path sanitizing
templateFile="${templateFile//\\//}"
templateParameterFile="${templateParameterFile//\\//}"

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

if [ $deploymentLevel == 'Subscription' ]; then
  cmd="az deployment sub create --name $deploymentName --location $resourceLocation --template-file $templateFile $params"
  echo $cmd
  eval $cmd

  cmd="az deployment sub show --name $deploymentName --query properties.outputs"
  echo $cmd
  deploymentoutputs=$(eval $cmd)
else
  cmd="az deployment group create --name $deploymentName --mode $deploymentMode --resource-group $resourceGroupName --template-file $templateFile $params"
  echo $cmd
  eval $cmd

  cmd="az deployment group show --resource-group $resourceGroupName --name $deploymentName --query properties.outputs"
  echo $cmd
  deploymentoutputs=$(eval $cmd)
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