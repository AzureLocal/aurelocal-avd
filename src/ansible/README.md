# Ansible Configuration

Ansible playbooks and roles for post-deployment configuration of AVD session hosts.

## Structure

```
src/ansible/
├── playbooks/
│   └── site.yml              # Main playbook
├── inventory/
│   └── hosts.example.yml     # Example inventory
└── roles/
    ├── avd-control-plane/    # Control plane config role
    └── avd-session-hosts/    # Session host config role
```

## Usage

```bash
cd src/ansible
cp inventory/hosts.example.yml inventory/hosts.yml
# Edit inventory/hosts.yml with your hosts
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

## Prerequisites

- Ansible 2.14+
- `azure.azcollection` collection: `ansible-galaxy collection install azure.azcollection`
