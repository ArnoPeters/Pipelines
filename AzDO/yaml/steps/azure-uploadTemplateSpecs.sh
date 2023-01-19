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
if [[ ( "$preReleaseLabel" != "" ) && ( $preReleaseLabel != -* ) ]]; then 
  preReleaseLabelWithDash="-$preReleaseLabel"
fi

semanticVersion="${semverMajor}.${semverMinor}.${semverPatch}${preReleaseLabelWithDash}"
majorWildcard="${semverMajor}.x.x${preReleaseLabelWithDash}"
minorWildcard="${semverMajor}.${semverMinor}.x${preReleaseLabelWithDash}"

echo "Publishing 'semantic' version '${semanticVersion}'"
versions="${semanticVersion}"

# Case insensitive compare
if [[ "${publishWildcardVersions,,}" == "true" ]]; then 
  echo "Publishing 'wildcard' versions '${majorWildcard}' and '${minorWildcard}'."
  versions+=("${majorWildcard}" "${minorWildcard}")
fi

# Case insensitive compare
if [[ "${publishLatest,,}" == "true" ]]; then 
  if [[ "$preReleaseLabel" == "" ]]; then 
    echo "Publishing 'latest' as version."
    versions+=("latest")
  else 
    echo "Pre-release label present: skipping publish of 'latest' as version."
  fi
fi

filter="@($filter)"

# ensure linux-compatible relative path 
sourceFolder="${sourceFolder//\\//}" 
sourceFolder="${sourceFolder#"$PWD"}" 

if [[ $sourceFolder == /* ]]; then 
  sourceFolder=".$sourceFolder" 
fi

hasUploadedAnyhting=false

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

        for version in "${versions[@]}"
        do
          hasUploadedAnyhting=true # Not the perfect solution to use global var for this
          cmd="az ts create --yes --name \"$namespacedFileName\" --version \"$version\" --resource-group \"$resourceGroupName\" --location \"$location\" --template-file \"$pathname\""
          echo "$cmd"
          eval "$cmd"
        done
      esac
    fi
  done
}

walk_dir "$sourceFolder" "${versions[@]}"

if [ hasUploadedAnyhting ]; then 
  exit 0
else 
  exit 1
fi