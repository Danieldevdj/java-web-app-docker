# Java Web Application with Docker and Kubernetes

A complete DevOps solution for deploying a Java web application on an on-premise Kubernetes cluster with comprehensive infrastructure automation using Ansible.

## 🚀 Project Overview

This repository contains:
- **Java Web Application**: Spring-based web application packaged as WAR
- **Docker Configuration**: Containerization using Tomcat base image
- **Kubernetes Manifests**: Deployment and service configurations
- **Ansible Infrastructure**: Complete on-premise setup automation for 11 servers
- **CI/CD Pipeline**: GitHub Actions workflow for automated deployment
- **Monitoring Stack**: Prometheus and Grafana integration
- **High Availability**: HAProxy and Keepalived load balancing

## 📋 Infrastructure Architecture

### Server Layout (11 Servers)

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer Layer                       │
│  ┌──────────────────┐          ┌──────────────────┐         │
│  │   LB-1 (Master)  │          │  LB-2 (Backup)   │         │
│  │   HAProxy +      │◄────────►│   HAProxy +      │         │
│  │   Keepalived     │  VRRP    │   Keepalived     │         │
│  └────────┬─────────┘          └─────────┬────────┘         │
│           │    Virtual IP: 192.168.1.100  │                 │
└───────────┼────────────────────────────────┼─────────────────┘
            │                                │
┌───────────┼────────────────────────────────┼─────────────────┐
│           │   Kubernetes Control Plane     │                 │
│  ┌────────▼────────┐  ┌──────────────┐  ┌─▼──────────────┐  │
│  │  Master-1       │  │  Master-2    │  │  Master-3      │  │
│  │  (etcd, API)    │  │  (etcd, API) │  │  (etcd, API)   │  │
│  └─────────────────┘  └──────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────┘
            │                                │
┌───────────┼────────────────────────────────┼─────────────────┐
│           │   Kubernetes Worker Nodes      │                 │
│  ┌────────▼──┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Worker-1  │  │ Worker-2 │  │ Worker-3 │  │ Worker-4 │    │
│  │ (Pods)    │  │ (Pods)   │  │ (Pods)   │  │ (Pods)   │    │
│  └───────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐                                                │
│  │ Worker-5 │                                                │
│  │ (Pods)   │                                                │
│  └──────────┘                                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Monitoring Layer                           │
│  ┌─────────────────────────────────────────────────┐        │
│  │  Monitoring Server                              │        │
│  │  - Prometheus (Metrics Collection)              │        │
│  │  - Grafana (Visualization)                      │        │
│  │  - Node Exporter (on all nodes)                 │        │
│  └─────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Technology Stack

### Application
- **Language**: Java 8
- **Framework**: Spring Framework 5.0.7
- **Build Tool**: Maven
- **Packaging**: WAR (Web Archive)
- **Server**: Apache Tomcat

### Containerization
- **Runtime**: Docker Engine
- **Container Runtime**: containerd
- **Registry**: DockerHub
- **Base Image**: tomcat:latest

### Orchestration
- **Platform**: Kubernetes 1.28
- **Installation**: kubeadm
- **Network Plugin**: Calico
- **Pod CIDR**: 10.244.0.0/16

### Load Balancing
- **Load Balancer**: HAProxy 2.8
- **High Availability**: Keepalived
- **Virtual IP**: 192.168.1.100
- **Protocol**: VRRP

### Monitoring
- **Metrics**: Prometheus 2.47
- **Visualization**: Grafana
- **Exporters**: Node Exporter 1.6.1
- **Retention**: 15 days

### Automation
- **Configuration Management**: Ansible
- **CI/CD**: GitHub Actions
- **Version Control**: Git/GitHub

## 📦 Quick Start

### Prerequisites

- 11 Ubuntu servers (20.04 or 22.04 LTS)
- Ansible 2.9+ on control node
- SSH access to all servers
- Minimum 4GB RAM per server
- Internet connectivity

### 1. Clone Repository

```bash
git clone https://github.com/Danieldevdj/java-web-app-docker.git
cd java-web-app-docker
```

### 2. Configure Infrastructure

```bash
cd ansible
vi inventory/hosts.ini  # Update server IP addresses
```

### 3. Setup SSH Access

```bash
ssh-keygen -t rsa -b 4096
for i in {11..13} {21..25} {31..32} 41; do
  ssh-copy-id ubuntu@192.168.1.$i
done
```

### 4. Install Ansible Collections

```bash
ansible-galaxy install -r requirements.yml
```

### 5. Deploy Infrastructure

```bash
# Option 1: Interactive setup
./setup.sh

# Option 2: Full automated setup
ansible-playbook -i inventory/hosts.ini site.yml
```

### 6. Verify Installation

```bash
# Check all components
./setup.sh  # Select option 6

# Or manually
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔧 Configuration

### Inventory Configuration

Edit `ansible/inventory/hosts.ini` with your server IPs:

```ini
[k8s_masters]
k8s-master-1 ansible_host=YOUR_IP_1
k8s-master-2 ansible_host=YOUR_IP_2
k8s-master-3 ansible_host=YOUR_IP_3

[k8s_workers]
k8s-worker-1 ansible_host=YOUR_IP_4
# ... add all workers

[loadbalancers]
lb-1 ansible_host=YOUR_IP_10 keepalived_priority=100 keepalived_state=MASTER
lb-2 ansible_host=YOUR_IP_11 keepalived_priority=90 keepalived_state=BACKUP

[monitoring]
monitoring-1 ansible_host=YOUR_IP_12
```

### Variable Configuration

Edit files in `ansible/group_vars/` to customize:
- `all.yml`: Global settings
- `k8s_cluster.yml`: Kubernetes configuration
- `loadbalancers.yml`: HAProxy and Keepalived settings
- `monitoring.yml`: Prometheus and Grafana settings

## 🚢 Application Deployment

### Build and Deploy Locally

```bash
# Build application
mvn clean package

# Build Docker image
docker build -t your-dockerhub-username/java-web-app .

# Push to DockerHub
docker push your-dockerhub-username/java-web-app

# Deploy to Kubernetes
kubectl apply -f javawebapp-deployment.yml
```

### CI/CD with GitHub Actions

1. Configure secrets in GitHub:
   - `DOCKERHUB_USERNAME`: Your DockerHub username
   - `DOCKERHUB_TOKEN`: Your DockerHub access token
   - `KUBE_CONFIG`: Your Kubernetes config file (base64 encoded)

2. Push code to trigger pipeline:
```bash
git add .
git commit -m "Deploy application"
git push origin main
```

## 📊 Monitoring and Observability

### Access Monitoring Dashboards

- **Prometheus**: http://192.168.1.41:9090
- **Grafana**: http://192.168.1.41:3000 (admin/admin)
- **HAProxy Stats**: http://192.168.1.100:8404/stats (admin/admin)

### Recommended Grafana Dashboards

1. **Node Exporter Full** (ID: 1860)
   - CPU, Memory, Disk, Network metrics
   
2. **Kubernetes Cluster Monitoring** (ID: 315)
   - Pod, Deployment, Service metrics
   
3. **HAProxy Full** (ID: 367)
   - Load balancer metrics

## 🔐 Security Best Practices

1. **SSH Keys**: Use SSH keys instead of passwords
2. **Firewall**: Configure UFW or iptables
3. **RBAC**: Implement Kubernetes RBAC policies
4. **Network Policies**: Define pod network policies
5. **Secrets**: Use Kubernetes secrets for sensitive data
6. **TLS/SSL**: Configure SSL certificates for production
7. **Updates**: Regularly update all components

## 📚 Documentation

- [Infrastructure Setup Guide](ansible/README.md) - Detailed Ansible documentation
- [Kubernetes Deployment](javawebapp-deployment.yml) - K8s manifest reference
- [Docker Configuration](Dockerfile) - Container build instructions

## 🔍 Troubleshooting

### Common Issues

**Issue**: Ansible cannot connect to servers
```bash
# Test connectivity
ansible all -i ansible/inventory/hosts.ini -m ping

# Check SSH config
ssh -vvv ubuntu@192.168.1.11
```

**Issue**: Kubernetes nodes not joining
```bash
# On master: Get join command
kubeadm token create --print-join-command

# On worker: Join manually
sudo kubeadm join 192.168.1.100:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

**Issue**: HAProxy not starting
```bash
# Check configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# View logs
journalctl -u haproxy -f
```

**Issue**: Virtual IP not active
```bash
# Check Keepalived status
systemctl status keepalived
ip addr show

# View logs
tail -f /var/log/keepalived-transitions.log
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Danieldevdj** - [GitHub Profile](https://github.com/Danieldevdj)

## 🙏 Acknowledgments

- Spring Framework team
- Kubernetes community
- Docker community
- Ansible community
- HAProxy and Keepalived maintainers
- Prometheus and Grafana teams

## 📞 Support

For issues, questions, or contributions:
- **GitHub Issues**: [Create an issue](https://github.com/Danieldevdj/java-web-app-docker/issues)
- **Documentation**: See [ansible/README.md](ansible/README.md) for detailed setup

## 🗺️ Roadmap

- [ ] Add Helm charts for application deployment
- [ ] Implement GitOps with ArgoCD
- [ ] Add Istio service mesh
- [ ] Implement automated backup solutions
- [ ] Add security scanning with Trivy
- [ ] Implement log aggregation with ELK stack
- [ ] Add automated certificate management with cert-manager
