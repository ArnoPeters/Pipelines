#!/bin/bash

# Uncomment to get the script for local testing or for inline use in a Task Group 

# semverMajor='1'
# semverMinor='2'
# semverPatch='3'
# preReleaseLabel="TEST"
# resourceGroupName="TemplateSpecs2"
# location="westeurope"
# sourceFolder="/Azure/Arm&Bicep"
# filter='*.json|*.bicep'
# publishWildcardVersions="True"
# publishLatest="True"

# --- Script start --- 
echo "##[section]Determining version labels"
if [[ ( "$preReleaseLabel" != "" ) && ( $preReleaseLabel != -* ) ]]; then 
  preReleaseLabelWithDash="-$preReleaseLabel"
fi

semanticVersion="${semverMajor}.${semverMinor}.${semverPatch}${preReleaseLabelWithDash}"
majorWildcard="${semverMajor}.x.x${preReleaseLabelWithDash}"
minorWildcard="${semverMajor}.${semverMinor}.x${preReleaseLabelWithDash}"

echo "Publishing '${semanticVersion}' as semantic version."
versions="${semanticVersion}"

# Case insensitive compare
if [[ "${publishWildcardVersions,,}" == "true" ]]; then 
  echo "Publishing '${majorWildcard}' and '${minorWildcard}' as wildcard versions."
  versions+=("${majorWildcard}" "${minorWildcard}")
fi

# Case insensitive compare
if [[ "${publishLatest,,}" == "true" ]]; then 
  if [[ "$preReleaseLabel" == "" ]]; then 
    echo "Publishing 'latest' as rolling version."
    versions+=("latest")
  else 
    echo "##[warning]Pre-release label present: skipping publish of 'latest' as version."
  fi
fi

filter="@($filter)"

# ensure linux-compatible relative path 
sourceFolder="${sourceFolder//\\//}" 
sourceFolder="${sourceFolder#"$PWD"}" 

if [[ $sourceFolder == /* ]]; then 
  sourceFolder=".$sourceFolder" 
fi

hasUploadedAnything=false

#https://unix.stackexchange.com/a/494146
function walk_dir () {    
  shopt -s nullglob dotglob extglob
  local path=$1
  shift 1
  local -a versions=("$@")
  for pathname in "$path"/*; do
    if [ -d "$pathname" ]; then
      walk_dir "$pathname" "${versions[@]}"
    else
      case "$pathname" in
        $filter)
      
        fileRoot="$(basename "$pathname" | sed 's/\(.*\)\..*/\1/')"
        fileDir="${pathname%/*}"

        # Template specs do not support folders, so the file path relative to the source folder is converted to a dot (.) separated "namespace"
        filePathInSourceFolder=${fileDir#"$sourceFolder"}
        filePathInSourceFolder=${filePathInSourceFolder#"/"}
        # Template specs are all stored as ARM anyway, so the file name can be added without keeping the extension
        namespacedFileName="${filePathInSourceFolder////.}.$fileRoot"

        echo "##[group]Publishing [$pathname] as [$namespacedFileName]"
        for version in "${versions[@]}"
        do
          hasUploadedAnything=true # Not the perfect solution to use global var for this
          cmd="az ts create --yes --name \"$namespacedFileName\" --version \"$version\" --resource-group \"$resourceGroupName\" --location \"$location\" --template-file \"$pathname\""
          echo "##[command]$cmd"
          eval "$cmd"
        done
        echo "##[endgroup]"
      esac
    fi
  done
}
echo "##[section]Publish Template Specs to resource group [$resourceGroupName]"

walk_dir "$sourceFolder" "${versions[@]}"

if $hasUploadedAnything ; then 
  exit 0
else 
  exit 1
fi