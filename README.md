Zeus
====

[![Build Status](https://github.com/jboss-set/zeus/workflows/CI/badge.svg)](https://github.com/jboss-set/zeus/actions/workflows/ci.yml)

These are Ansible configuration scripts for the Olympus JBoss SET CI server.

### Prerequisites:
* Ansible [core] 2.12 or newer (check using `ansible --version`, see [official guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
* Python 3.8 or newer (check using `python3 --version`, see [official guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/assembly_installing-and-using-python_configuring-basic-system-settings))

## Testability Notes

Some roles in this repository have been integrated with Molecule. 
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

### How to perform CCI VM automation

* First install OpenStack in your local machine. Follow the instructions [here](https://docs.openstack.org/install-guide/environment-packages-rdo.html)
* Run the playbook `cci_run.yml`, it will perform all the operations.
