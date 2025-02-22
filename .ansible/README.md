# Ansible - new environment setup

1. Install and configure SSH client
1. Install Git
1. Setup Ansible

- Install `python3-venv`
- Create venv
- Install `ansible`

4. Run Ansible

```sh
ansible-playbook --ask-become-pass ~/.ansible/bootstrap.yml --extra-vars='env=dev'
```
