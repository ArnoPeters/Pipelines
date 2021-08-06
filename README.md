The purpose of this repository is to provide reusable building blocks implementing specific workflows for CI/CD pipelines. Currently it is scoped toward pipelines in Azure Devops, and pipelines that use Github Actions. 

# One Time Setup

It is technically possible to create pipelines in another github account that depend directly on this (public) repository. This might cause unexpected behavior in those pipelines when this repository is updated. For this reason, it is very much recommended to keep your pipelines stable by creating a copy of this repo in your own Github account.
- If you just want to create a starting point: [use this repository as template](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/creating-a-repository-from-a-template).
- If you want to be able to pull future commits from this repo, or contribute with pull requests: [create a fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo)

## Azure Devops
_This only applies when using this repository for Azure Devops_

_TODO: REWRITE BELOW_
### Authors
Check the values to the variables in "AzDo/Yaml/Variables/Authors.yml". This file is used in several workflows, and ensures that your authoring information is uniformly embedded in your packages. (TODO: copyright and license should go in nuget repo, not here)

### Install (FREE) Azure Devops Marketplace tasks
When using the Azure Devops-specific templates, errors will be thrown if the templates uses tasks are not previously installed from the marketplace. 
Below is a list of the tasks used in this repository. 
Note: not every pipeline needs all tasks. The links to the tasks will also be added as comment at the top in of the actual template files to assist in adding only on demand. 

- https://marketplace.visualstudio.com/items?itemName=ATP.ATP-GitTag
- https://marketplace.visualstudio.com/items?itemName=gittools.gittools
- https://marketplace.visualstudio.com/items?itemName=KriefMikael.githubtools

