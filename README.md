# Aim and purpose
This collection of ansible routines automates VM, OS and PostgreSQL deploiyng for test and educational purposes. Currently under development is not intended for real PROD environment, TEST/DEV only.

# Requirements
Requires working ansible infrastructure and package management
### Ansible
Either You have ansible-galaxy or some minimalistic deployment (ansible-core), be sure to meet requirements defined in collections/requirements.yml 
```bash
ansible-galaxy collection install -r collections/requirements.yml
```

### Packages
This stack uses publc repos & packages to install required software. Feel free to edit according Your package management.

# Usage and typical workflows
1. The core of this stack consists of ansible roles, each intended to perform a specific task in installation workflow (virtualisation, OS configuration, PostgreSQL configuration, DB replication). Roles could be called consequently or islolated according Your needs (granularity).

2. Typical and recomended scenario is to call overlaying playbook including respective role, e.g.:
```bash
ansible-playbook -i inventory playbooks/vm_install
ansible-playbook -i inventory playbooks/os_config
ansible-playbook -i inventory playbooks/postgresql
ansible-playbook -i inventory playbooks/pg_replication
```
If You prefer to call roles directly, use role wrapper 'ansible-role', e.g.:
```bash
./ansible-role db_local pg_replication -i inventory
```

3. There will be a shell script wrapping the whole procedure (from VM deploy to PG replication) in one step (TODO)


# Properties & description of ansible roles

## 1. VMs and virtualisation (role vm_deployment)

This role sets up desired virtualisation cluster and deploys VMs with Rocky Linux 9 OS. Currently libvirtd/KVM option fully functional, Vcenter/VMware under construction.
- creates libvirt pool (domain) according HW specs in group_vars/host_vars, downloads OS image
- sets networking and SSH access via public keys for 2 dedicated users:
-- rocky (for standard SSH tets login)
-- ansible_master (for further ansible driven management from ansible control node)

## 2. OS configuration (role os_config)

This Ansible role prepares a Linux host for database-style workloads by:
- creating an LVM layout on a dedicated disk (no partitioning): a capped Physical Volume, a single VG, and two LVs split by percentages (e.g., 80/20).
- formatting both LVs as XFS and mounting them persistently (/data and /pgwal).
- applying tuned profile, sysctl settings, ulimits via limits.d, and SELinux state as requested.
- the role is generic  and idempotent (skips pvcreate if a PV exists; uses pvresize to enforce size cap when needed). Uses LVM/XFS/mount modules to avoid destructive re-runs.

**Safety & caveats**
- Danger: Ensure lvm_device poins to the correct, empty disk. The role will wipe signatures and create a new PV.
- SELinux: Switching to disabled typically requires a reboot to fully take effect.
- Re-running: The role is idempotent, but it will not shrink existing filesystems or reshape LVs automatically; adjust vars carefully if changing layout on a live system.


## 3. Postgresql instalation and configuration (role postgresql)

Installs and configures target version PostgreSQL  on Rocky Linux 9.

- the role creates a cluster in /data/<cluster>, puts WAL on a separate mount at /pgwal/<cluster>/pg_wal, archives to /pgwal/<cluster>/archive
-  enables SSL with a self-signed fallback, ships a secure pg_hba.conf
-  supports memory “autotune” (or hard values), computes HugePages from SHOW shared_buffers
- runs a cron job for WAL archive cleanup at 60%
→ almost every GUC is mapped to 'postgresql_' variables (comprehensive sane defaults in defaults/main.yml)
- pg_hba.conf baseline: local peer for postgres, SCRAM elsewhere
- hardening: reomve public access to public schemas

## 4. PostgreSQL replication (pg_replication role)
A minimal, robust role that configures physical streaming replication between two PostgreSQL  nodes with encrypted traffic (TLS).
Designed to work with previous role (service, PGDG packages, ssl=on, etc.).
- ensures a replication role exists (LOGIN REPLICATION, optional password).
- adds hostssl pg_hba.conf entries for standby CIDRs (TLS enforced + SCRAM)
- initializes replication from standby node by pg_basebackup and consequent replication with replication slot (on master)a

## 5. Testing and validation
TODO
