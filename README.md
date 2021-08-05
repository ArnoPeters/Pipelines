
- A template copy of Pipelines Repo should be available in Github (access), setup as described there
  	  	- (TODO in docs of Pipelines Repo) - Fill in your preferred defaults in the (TODO) release variables
			- Installed tasks: 
			- (link to azure marketplace) ?
- 


# Instructions: 
This is a template repository for creating a nuget package hosted in github, but to be build in Azure Devops and published to Azure Devops Artifacts. 
It produces a pre-release version with from the merge build when a pull request is active, and a release version when the pull request is merged. 
It also provides automatic versioning (using GitVersion) and produces Source Link enabled debug symbols, allowing debugging into the package. 

## One Time Setup

### Create a copy of this repo in your own Github account
- _Reason required Is it even possible to depend directly on this repo, even if public? If you are not a member, can you authenticate? --> TEST THIS and explain correctly_
- If you want to be able to pull future commits from this repo, or contribute with pull requests: [create a fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
- If you just want to create a starting point: [use this repository as template](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/creating-a-repository-from-a-template).
- Delete this "One Time Setup" chapter from the readme.md in the new repository. 

## Install (FREE) Azure Devops Marketplace tasks
When using the Azure Devops-specific templates, errors will be thrown if used tasks are not installed from the marketplace. Not all tasks are used in all pipelines
Below is a list of the tasks used in this repository. 

- https://marketplace.visualstudio.com/items?itemName=ATP.ATP-GitTag
- https://marketplace.visualstudio.com/items?itemName=gittools.gittools
