# dotfiles

A set of dotfiles and install scripts. I have two primary goals: 
- Uniquitous platform independent installation (MacOS, Linux, Windows)
- No external dependencies, click and go

## Tools
- [dotbot](https://github.com/anishathalye/dotbot)

Initializing and checking-out the specified submodule versions: 
`git submodule update --init --recursive`

Upgrading submodules to latest published version: 
`git submodule update --init --remote`

This can be done manually with dotbot: 

```
