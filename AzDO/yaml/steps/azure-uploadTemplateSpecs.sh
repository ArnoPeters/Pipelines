#!/bin/bash

# Uncomment to get the script for local testing or for inline use in a Task Group 

# semverMajor='1'
# semverMinor='2'
# semverPatch='3'
# preReleaseLabel="TEST"
# resourceGroupName="TemplateSpecs"
# location="westeurope"
# sourceFolder="/Azure/Arm&Bicep"
# filter='*.json|*.bicep'
# publishWildcardVersions="True"
# publishLatest="True"

# --- Script start --- 
set -e
echo "##[section]Determining version labels"
if [[ ( "$preReleaseLabel" != "" ) ]]; then 
  if [[ ( $preReleaseLabel != -* ) ]]; then 
    preReleaseLabelWithDash="-$preReleaseLabel"
  else
    preReleaseLabelWithDash="$preReleaseLabel"
  fi
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
function dir_upload_templatespecs () {    
  shopt -s nullglob dotglob extglob
  local path=$1
  echo "##[debug] --- Scan of Directory [$path] STARTED ---"
  shift 1
  local -a versions=("$@")
  for pathname in "$path"/*; do
    if [ -d "$pathname" ]; then
      dir_upload_templatespecs "$pathname" "${versions[@]}"
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
            hasUploadedAnything=true #It's quite ugly to use a global var for this, but it works.
            cmd="az ts create --yes --name \"$namespacedFileName\" --version \"$version\" --resource-group \"$resourceGroupName\" --location \"$location\" --template-file \"$pathname\""
            echo "##[command]$cmd"
            eval "$cmd"
          done
          echo "##[endgroup]"
        ;;   
        *)
          echo "##[debug] SKIP: $pathname NOT in $filter"
        ;;  
      esac
    fi
  done
  echo "##[debug] --- Scan of Directory [$path] COMPLETED ---"
}
echo "##[section]Publish Template Specs to resource group [$resourceGroupName]"

dir_upload_templatespecs "$sourceFolder" "${versions[@]}"

if $hasUploadedAnything ; then 
  exit 0
else 
  exit 1
fi