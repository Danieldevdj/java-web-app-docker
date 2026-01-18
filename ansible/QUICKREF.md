# Infrastructure Quick Reference

## Quick Start
```bash
cd ansible
./setup.sh              # Interactive setup
# or
make setup              # Automated setup
```

## Common Commands

### Infrastructure Management
```bash
# Full setup
make setup

# Individual components
make docker              # Install Docker only
make k8s                # Setup Kubernetes only
make loadbalancer       # Setup HAProxy/Keepalived only
make monitoring         # Setup Prometheus/Grafana only

# Check status
make status             # Service status
make verify             # Full health check
```

### Kubernetes Operations
```bash
# Get kubeconfig
make get-kubeconfig

# Access cluster
kubectl get nodes
kubectl get pods -A

# Deploy application
kubectl apply -f javawebapp-deployment.yml

# Check deployment
kubectl get deployments
kubectl get services
```

### Monitoring
```bash
# Access dashboards
# Prometheus: http://192.168.1.41:9090
# Grafana: http://192.168.1.41:3000 (admin/admin)
# HAProxy Stats: http://192.168.1.31:8404/stats (admin/admin)

# View logs
make logs-haproxy
make logs-keepalived
make logs-prometheus
```

### Service Control
```bash
# Restart services
make restart-haproxy
make restart-keepalived
make restart-prometheus
make restart-grafana
```

### Troubleshooting
```bash
# Test connectivity
ansible all -i inventory/hosts.ini -m ping

# Check service status
ansible all -i inventory/hosts.ini -m shell -a "systemctl status docker"

# View logs on specific host
ansible k8s_masters[0] -i inventory/hosts.ini -m shell -a "journalctl -u kubelet -n 50"
```

## Key IP Addresses (Default)
- Virtual IP: 192.168.1.100
- Masters: 192.168.1.11-13
- Workers: 192.168.1.21-25
- Load Balancers: 192.168.1.31-32
- Monitoring: 192.168.1.41

## Important Files
- **Inventory**: `inventory/hosts.ini`
- **Variables**: `group_vars/*.yml`
- **Main Playbook**: `site.yml`
- **Config Templates**: `configs/*/`

## Security Reminders
⚠️  Change default passwords in `group_vars/` before production!
⚠️  Use Ansible vault for sensitive data
⚠️  Configure firewall rules
⚠️  Enable TLS/SSL for production

## Backup Operations
```bash
# Backup etcd
make backup-etcd

# Manual etcd backup
ssh ubuntu@192.168.1.11
sudo ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

## Emergency Procedures

### Load Balancer Failover Test
```bash
# On master LB
ansible lb-1 -i inventory/hosts.ini -m systemd -a "name=keepalived state=stopped" --become
# VIP should move to backup
# Restore
ansible lb-1 -i inventory/hosts.ini -m systemd -a "name=keepalived state=started" --become
```

### Kubernetes Node Drain
```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
# Perform maintenance
kubectl uncordon <node-name>
```

### Scale Deployment
```bash
kubectl scale deployment java-controller --replicas=3
```

## Support
- Documentation: `README.md`, `ansible/README.md`
- Verify script: `./verify-infrastructure.sh`
- Help: `make help`
