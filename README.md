Zeus
====

These are Ansible configuration scripts for the Olympus JBoss SET CI server.

## Testability Notes

Some roles in this repository have been integrated with Molecule (those roles contain the `molecule` directory). 
Molecule is a library that makes it possible to execute Ansible roles on disposable containers to perform testing.

### Molecule Installation Steps

Molecule needs to be installed on the system where you want to test roles.

Recommended way to install molecule on a developer machine:

* Install & upgrade pip: `python -m pip install --upgrade pip`,
* go to the zeus directory,
* with python env, create a virtual environment: `python3 -m venv env`,
* enter virtual env: `source env/bin/activate` (to exit the virtual env, run `deactivate`),
* via pip, install molecule with podman (or docker) driver: `python3 -m pip install "molecule[ansible,lint,podman]"`.

(See https://molecule.readthedocs.io/en/latest/installation.html for official guide.)

### How to run Molecule test in Zeus

* From root of the repo, Run `$ molecule test --all` to run the whole testsuite.
* From root of the repo, Run `$ molecule test -s role_name` to run individual role test.
