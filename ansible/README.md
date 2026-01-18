# On-Premise DevOps Infrastructure Setup with Ansible

This repository contains Ansible playbooks and configurations for setting up a complete on-premise DevOps infrastructure with 11 servers.

## Infrastructure Overview

### Server Architecture (11 Servers)

1. **Kubernetes Master Nodes (3 servers)** - High Availability Control Plane
   - k8s-master-1: 192.168.1.11
   - k8s-master-2: 192.168.1.12
   - k8s-master-3: 192.168.1.13

2. **Kubernetes Worker Nodes (5 servers)** - Application Workload
   - k8s-worker-1: 192.168.1.21
   - k8s-worker-2: 192.168.1.22
   - k8s-worker-3: 192.168.1.23
   - k8s-worker-4: 192.168.1.24
   - k8s-worker-5: 192.168.1.25

3. **Load Balancer Nodes (2 servers)** - HAProxy + Keepalived
   - lb-1: 192.168.1.31 (MASTER)
   - lb-2: 192.168.1.32 (BACKUP)
   - Virtual IP: 192.168.1.100

4. **Monitoring Server (1 server)** - Prometheus + Grafana
   - monitoring-1: 192.168.1.41

## Components Installed

### 1. Docker and containerd
- **Docker Engine**: Latest stable version
- **containerd**: Container runtime for Kubernetes
- **Configuration**: Systemd cgroup driver, overlay2 storage driver

### 2. Kubernetes (kubeadm method)
- **Version**: 1.28.x
- **Network Plugin**: Calico
- **Pod Network CIDR**: 10.244.0.0/16
- **Control Plane**: 3 masters for High Availability
- **Worker Nodes**: 5 workers for application workload

### 3. HAProxy Load Balancer
- **Kubernetes API**: Port 6443 (load balanced across 3 masters)
- **HTTP Traffic**: Port 80 (load balanced across workers)
- **HTTPS Traffic**: Port 443 (load balanced across workers)
- **Statistics**: Port 8404 (username: admin, password: admin)

### 4. Keepalived
- **Virtual IP**: 192.168.1.100
- **VRRP Protocol**: For automatic failover
- **Health Checks**: Monitors HAProxy service

### 5. Prometheus Monitoring
- **Port**: 9090
- **Node Exporter**: Installed on all nodes (port 9100)
- **Scrape Targets**: All infrastructure nodes
- **Retention**: 15 days (default)

### 6. Grafana
- **Port**: 3000
- **Default Credentials**: admin/admin
- **Data Source**: Prometheus (preconfigured)

## Prerequisites

### Control Node (Ansible Host)
- Ansible 2.9 or higher
- Python 3.6 or higher
- SSH access to all target servers

### Target Servers
- Ubuntu 20.04 LTS or 22.04 LTS
- Minimum 2 CPU cores
- Minimum 4GB RAM (8GB recommended for masters)
- Minimum 20GB disk space
- SSH access with sudo privileges
- Internet connectivity for package downloads

## Installation Steps

### 1. Prepare the Control Node

```bash
# Install Ansible
sudo apt update
sudo apt install ansible -y

# Clone the repository
git clone https://github.com/Danieldevdj/java-web-app-docker.git
cd java-web-app-docker/ansible
```

### 2. Configure Inventory

Edit the inventory file to match your server IPs:

```bash
vi inventory/hosts.ini
```

Update the IP addresses for each server:
```ini
[k8s_masters]
k8s-master-1 ansible_host=YOUR_MASTER1_IP
k8s-master-2 ansible_host=YOUR_MASTER2_IP
k8s-master-3 ansible_host=YOUR_MASTER3_IP

[k8s_workers]
k8s-worker-1 ansible_host=YOUR_WORKER1_IP
# ... continue for all servers
```

### 3. Configure SSH Access

Set up SSH key-based authentication:

```bash
# Generate SSH key (if not already exists)
ssh-keygen -t rsa -b 4096

# Copy SSH key to all servers
for i in {11..13} {21..25} {31..32} 41; do
  ssh-copy-id ubuntu@192.168.1.$i
done
```

### 4. Test Connectivity

```bash
# Test Ansible connectivity
ansible all -i inventory/hosts.ini -m ping
```

### 5. Run Complete Setup

Execute the full infrastructure setup:

```bash
# Run all playbooks
ansible-playbook -i inventory/hosts.ini site.yml

# Or run individual playbooks
ansible-playbook -i inventory/hosts.ini playbooks/01-docker-setup.yml
ansible-playbook -i inventory/hosts.ini playbooks/02-kubernetes-setup.yml
ansible-playbook -i inventory/hosts.ini playbooks/05-keepalived-scripts.yml
ansible-playbook -i inventory/hosts.ini playbooks/03-loadbalancer-setup.yml
ansible-playbook -i inventory/hosts.ini playbooks/04-monitoring-setup.yml
```

### 6. Verify Installation

#### Check Docker
```bash
ansible docker_hosts -i inventory/hosts.ini -m shell -a "docker --version"
```

#### Check Kubernetes
```bash
# SSH to first master
ssh ubuntu@192.168.1.11

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Check HAProxy
```bash
# Check HAProxy status
ansible loadbalancers -i inventory/hosts.ini -m shell -a "systemctl status haproxy"

# Check HAProxy stats
curl http://192.168.1.31:8404/stats
# Or visit: http://192.168.1.31:8404/stats in browser
```

#### Check Keepalived
```bash
# Check virtual IP
ansible loadbalancers -i inventory/hosts.ini -m shell -a "ip addr show"

# Check Keepalived status
ansible loadbalancers -i inventory/hosts.ini -m shell -a "systemctl status keepalived"
```

#### Check Prometheus
```bash
# Visit Prometheus
http://192.168.1.41:9090

# Check targets
http://192.168.1.41:9090/targets
```

#### Check Grafana
```bash
# Visit Grafana
http://192.168.1.41:3000

# Login with: admin/admin
# Add Prometheus data source: http://localhost:9090
```

## Usage

### Access Kubernetes Cluster

From any master node:
```bash
kubectl get nodes
kubectl get pods -A
```

From your workstation (copy kubeconfig):
```bash
# Copy from master
scp ubuntu@192.168.1.11:~/.kube/config ~/.kube/config

# Update server address to use VIP
kubectl config set-cluster kubernetes --server=https://192.168.1.100:6443
```

### Deploy Application

Deploy the Java web application:
```bash
kubectl apply -f javawebapp-deployment.yml
```

### Monitor with HAProxy

1. Visit HAProxy stats: http://192.168.1.100:8404/stats
2. Login: admin/admin
3. Monitor backend health and traffic

### Monitor with Prometheus/Grafana

1. Access Grafana: http://192.168.1.41:3000
2. Login: admin/admin
3. Add Prometheus datasource: http://localhost:9090
4. Import dashboards:
   - Node Exporter Full (ID: 1860)
   - Kubernetes Cluster Monitoring (ID: 315)
   - HAProxy Full (ID: 367)

## Architecture Details

### High Availability Features

1. **Kubernetes Control Plane HA**
   - 3 master nodes with stacked etcd
   - Load balanced via HAProxy
   - Automatic leader election

2. **Load Balancer HA**
   - 2 HAProxy instances
   - Keepalived VRRP for failover
   - Virtual IP (192.168.1.100) floats between nodes
   - Sub-second failover time

3. **Application HA**
   - Multiple replicas across worker nodes
   - Health checks and auto-restart
   - Rolling updates with zero downtime

### Network Flow

```
Client Request
      ↓
Virtual IP (192.168.1.100) - Keepalived
      ↓
HAProxy (Active LB)
      ↓
      ├→ Kubernetes API (Masters 1-3:6443)
      ├→ HTTP Traffic (Workers NodePort:30080)
      └→ HTTPS Traffic (Workers NodePort:30443)
```

### Monitoring Architecture

```
All Nodes (Node Exporter:9100)
      ↓
Prometheus (192.168.1.41:9090)
      ↓
Grafana (192.168.1.41:3000)
      ↓
Dashboards & Alerts
```

## Maintenance

### Scale Worker Nodes

Add new workers to inventory and run:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/01-docker-setup.yml --limit new_worker
ansible-playbook -i inventory/hosts.ini playbooks/02-kubernetes-setup.yml --limit new_worker
```

### Update Components

```bash
# Update Docker
ansible-playbook -i inventory/hosts.ini playbooks/01-docker-setup.yml

# Upgrade Kubernetes (change version in vars)
ansible-playbook -i inventory/hosts.ini playbooks/02-kubernetes-setup.yml
```

### Backup

1. **Kubernetes etcd backup**:
   ```bash
   ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
     --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key
   ```

2. **Prometheus data**: `/var/lib/prometheus/`
3. **Grafana data**: `/var/lib/grafana/`

## Troubleshooting

### Kubernetes Issues

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Check logs
kubectl logs -n kube-system <pod-name>
journalctl -u kubelet -f
```

### HAProxy Issues

```bash
# Check configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Check logs
tail -f /var/log/haproxy.log

# Test backend connectivity
curl -I http://192.168.1.21:30080
```

### Keepalived Issues

```bash
# Check virtual IP
ip addr show

# Check logs
tail -f /var/log/syslog | grep Keepalived
cat /var/log/keepalived-transitions.log

# Manual failover test
systemctl stop keepalived  # on master
```

### Prometheus Issues

```bash
# Check service status
systemctl status prometheus
systemctl status node_exporter

# Check configuration
promtool check config /etc/prometheus/prometheus.yml

# Check targets
curl http://localhost:9090/api/v1/targets
```

## Security Considerations

1. **Firewall Rules**: Configure appropriate firewall rules
2. **SSH Keys**: Use SSH keys instead of passwords
3. **RBAC**: Implement Kubernetes RBAC
4. **Network Policies**: Define Kubernetes network policies
5. **TLS/SSL**: Configure SSL certificates for production
6. **Secrets Management**: Use Kubernetes secrets or external vaults
7. **Regular Updates**: Keep all components updated

## File Structure

```
ansible/
├── ansible.cfg                          # Ansible configuration
├── site.yml                             # Main playbook
├── inventory/
│   └── hosts.ini                        # Server inventory
├── playbooks/
│   ├── 01-docker-setup.yml              # Docker installation
│   ├── 02-kubernetes-setup.yml          # Kubernetes setup
│   ├── 03-loadbalancer-setup.yml        # HAProxy/Keepalived
│   ├── 04-monitoring-setup.yml          # Prometheus/Grafana
│   └── 05-keepalived-scripts.yml        # Keepalived scripts
└── configs/
    ├── haproxy/
    │   └── haproxy.cfg.j2               # HAProxy template
    ├── keepalived/
    │   ├── keepalived.conf.j2           # Keepalived template
    │   ├── notify_master.sh             # Master notification
    │   ├── notify_backup.sh             # Backup notification
    │   └── notify_fault.sh              # Fault notification
    ├── prometheus/
    │   └── prometheus.yml.j2            # Prometheus config
    └── grafana/
        └── grafana.ini.j2               # Grafana config
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- GitHub Issues: https://github.com/Danieldevdj/java-web-app-docker/issues
- Documentation: See this README

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [HAProxy Documentation](https://www.haproxy.org/documentation.html)
- [Keepalived Documentation](https://keepalived.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
