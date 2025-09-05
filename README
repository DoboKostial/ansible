1. VMs and virtualisation
(role vm_deployment)
This role sets up desired virtualisation cluster and deploys VMs with Rocky 9 OS
Currently libvirtd/KVM option fully functional, Vcenter/VMware under construction.
Creates libvirt pool (domain) according HW specs in group_vars/host_vars, downloads OS image, 
sets networking and SSH access via public keys for 2 dedicated users:
- rocky (for standard SSH tets login)
- ansible_master (for further ansible driven management from ansible control node)

2. OS configuration
(role os_config)

This Ansible role prepares a Linux host for database-style workloads by:
Creating an LVM layout on a dedicated disk (no partitioning): a capped Physical Volume, a single VG, and two LVs split by percentages (e.g., 80/20).
Formatting both LVs as XFS and mounting them persistently (/data and /pgwal).
Applying tuned profile, sysctl settings, ulimits via limits.d, and SELinux state as requested.
The role is generic  and idempotent (skips pvcreate if a PV exists; uses pvresize to enforce size cap when needed). Uses LVM/XFS/mount modules to avoid destructive re-runs.

Safety & caveats
Danger: Ensure lvm_device poins to the correct, empty disk. The role will wipe signatures and create a new PV.
SELinux: Switching to disabled typically requires a reboot to fully take effect.
Re-running: The role is idempotent, but it will not shrink existing filesystems or reshape LVs automatically; adjust vars carefully if changing layout on a live system.


3. Postgresql instalation and configuration
(role postgresql)
Install and configure target version PostgreSQL  on Rocky Linux 9.

The role creates a cluster in /data/<cluster>, puts WAL on a separate mount at /pgwal/<cluster>/pg_wal, archives to /pgwal/<cluster>/archive, enables SSL with a self-signed fallback, ships a secure pg_hba.conf, supports memory “autotune” (or hard values), computes HugePages from SHOW shared_buffers, runs a cron job for WAL archive cleanup at 60%, and sets a systemd drop-in so the service uses the correct PGDATA.

Features

PGDG repo & packages
Initdb with --waldir → WAL outside data (/pgwal/<cluster>/pg_wal), archive is a sibling (/pgwal/<cluster>/archive)
Config from template
→ almost every GUC is mapped to postgresql_* variables (comprehensive sane defaults in defaults/main.yml)
pg_hba.conf baseline: local peer for postgres, SCRAM elsewhere (your CIDRs easy to add)
SSL under /etc/ssl/postgresql/<cluster>
→ uses existing cert/key or generates self-signed if missing (secure file modes)
WAL archive + cron cleanup when the archive dir exceeds a threshold (default 60%; min keep window in hours)
Memory: either hard-set values in group_vars or enable autotune (integer-only math)
HugePages: compute required vm.nr_hugepages after start from SHOW shared_buffers (+margin); optional restart via handler
Systemd drop-in sets PGDATA, pg_isready wait for readiness
Hardening: reomve public access to public schemas 
