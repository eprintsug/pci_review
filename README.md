# Peer Community In Review for EPrints

Peer Community In integration

Implementation of COAR Notify powered PCI endorsement submission interface for pre-prints in EPrints

## Requirements

Depends on:

A [signposting](https://signposting.org/) enabled EPrints

and

[EPrints COAR Notify](https://github.com/eprintsug/coar_notify)

## Installation

If you manage your repository ingredients with git submodules (and you should) from the EPrints install directory:

```
git submodule add https://github.com/eprintsug/coar_notify ingredients/coar_notify
git submodule add https://github.com/eprintsug/pci_review ingredients/pci_review
git submodule update --init
```

Add the following to the flavour/inc file:

```
ingredients/coar_notify
ingredients/pci_review
```

Then test the install and migrate the config

```
bin/epadmin test [repoid]
bin/epadmin update [repoid]
```
