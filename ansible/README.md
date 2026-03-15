# Ansible – AVD on Azure Local

Ansible playbooks and roles for deploying and configuring Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
ansible/
├── site.yml                              # Master playbook
├── inventory.example.yml                 # Example dynamic/static inventory
└── roles/
    ├── avd-control-plane/
    │   ├── tasks/main.yml                # Deploy AVD host pool, app group, workspace
    │   └── defaults/main.yml             # Default variable values
    └── avd-session-hosts/
        ├── tasks/main.yml                # Deploy and configure session-host VMs
        └── defaults/main.yml             # Default variable values
```

---

## Prerequisites

```bash
pip install ansible
ansible-galaxy collection install azure.azcollection
pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt
```

Authenticate with Azure:
```bash
az login
# or set environment variables: AZURE_SUBSCRIPTION_ID, AZURE_TENANT, AZURE_CLIENT_ID, AZURE_SECRET
```

---

## Running the Playbooks

### Full deployment (control plane + session hosts)

```bash
ansible-playbook site.yml -i inventory.example.yml
```

### Control plane only

```bash
ansible-playbook site.yml -i inventory.example.yml --tags control-plane
```

### Session hosts only

```bash
ansible-playbook site.yml -i inventory.example.yml --tags session-hosts
```

---

## Variable Overrides

Override variables at runtime:

```bash
ansible-playbook site.yml \
  -e "avd_host_pool_name=my-pool avd_resource_group=rg-avd-prod"
```

Use Ansible Vault for secrets:

```bash
ansible-vault create group_vars/all/secrets.yml
ansible-playbook site.yml --ask-vault-pass
```
