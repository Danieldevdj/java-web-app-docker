#!/bin/bash
# Quick Start Script for Infrastructure Setup
# This script provides an interactive setup experience

set -e

echo "========================================"
echo "On-Premise DevOps Infrastructure Setup"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    echo "Please install Ansible first:"
    echo "  sudo apt update && sudo apt install ansible -y"
    exit 1
fi

echo -e "${GREEN}✓ Ansible is installed${NC}"

# Check if inventory file exists
if [ ! -f "inventory/hosts.ini" ]; then
    echo -e "${RED}Error: Inventory file not found${NC}"
    echo "Please configure inventory/hosts.ini first"
    exit 1
fi

echo -e "${GREEN}✓ Inventory file found${NC}"

# Test connectivity
echo ""
echo "Testing connectivity to all servers..."
if ansible all -i inventory/hosts.ini -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ All servers are reachable${NC}"
else
    echo -e "${RED}Error: Cannot reach all servers${NC}"
    echo "Please check:"
    echo "  1. Server IP addresses in inventory/hosts.ini"
    echo "  2. SSH key authentication is configured"
    echo "  3. Firewall rules allow SSH access"
    exit 1
fi

# Show menu
echo ""
echo "Setup Options:"
echo "1. Complete Infrastructure Setup (All components)"
echo "2. Docker and containerd only"
echo "3. Kubernetes cluster only"
echo "4. Load Balancer (HAProxy + Keepalived) only"
echo "5. Monitoring (Prometheus + Grafana) only"
echo "6. Check infrastructure status"
echo "7. Exit"
echo ""

read -p "Select option [1-7]: " option

case $option in
    1)
        echo ""
        echo -e "${YELLOW}Starting complete infrastructure setup...${NC}"
        echo "This will install Docker, Kubernetes, Load Balancer, and Monitoring"
        read -p "Continue? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            ansible-playbook -i inventory/hosts.ini site.yml
            echo -e "${GREEN}✓ Complete setup finished${NC}"
        fi
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Installing Docker and containerd...${NC}"
        ansible-playbook -i inventory/hosts.ini playbooks/01-docker-setup.yml
        echo -e "${GREEN}✓ Docker installation finished${NC}"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Setting up Kubernetes cluster...${NC}"
        ansible-playbook -i inventory/hosts.ini playbooks/02-kubernetes-setup.yml
        echo -e "${GREEN}✓ Kubernetes setup finished${NC}"
        ;;
    4)
        echo ""
        echo -e "${YELLOW}Setting up Load Balancer...${NC}"
        ansible-playbook -i inventory/hosts.ini playbooks/05-keepalived-scripts.yml
        ansible-playbook -i inventory/hosts.ini playbooks/03-loadbalancer-setup.yml
        echo -e "${GREEN}✓ Load Balancer setup finished${NC}"
        ;;
    5)
        echo ""
        echo -e "${YELLOW}Setting up Monitoring...${NC}"
        ansible-playbook -i inventory/hosts.ini playbooks/04-monitoring-setup.yml
        echo -e "${GREEN}✓ Monitoring setup finished${NC}"
        ;;
    6)
        echo ""
        echo "Checking infrastructure status..."
        echo ""
        echo "=== Docker Status ==="
        ansible docker_hosts -i inventory/hosts.ini -m shell -a "docker --version" 2>/dev/null || echo "Docker not found"
        echo ""
        echo "=== Kubernetes Nodes ==="
        ansible k8s_masters[0] -i inventory/hosts.ini -m shell -a "kubectl get nodes 2>/dev/null || echo 'Kubernetes not configured'" 2>/dev/null
        echo ""
        echo "=== HAProxy Status ==="
        ansible loadbalancers -i inventory/hosts.ini -m shell -a "systemctl is-active haproxy" 2>/dev/null || echo "HAProxy not found"
        echo ""
        echo "=== Keepalived Status ==="
        ansible loadbalancers -i inventory/hosts.ini -m shell -a "systemctl is-active keepalived" 2>/dev/null || echo "Keepalived not found"
        echo ""
        echo "=== Prometheus Status ==="
        ansible monitoring -i inventory/hosts.ini -m shell -a "systemctl is-active prometheus" 2>/dev/null || echo "Prometheus not found"
        echo ""
        echo "=== Grafana Status ==="
        ansible monitoring -i inventory/hosts.ini -m shell -a "systemctl is-active grafana-server" 2>/dev/null || echo "Grafana not found"
        ;;
    7)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Access your infrastructure:"
@VIP=$$(grep "virtual_ip" $(INVENTORY) | grep -oP '=\K[^ ]+' || echo "192.168.1.100"); \
K8S_MASTER_IP=$$(grep "k8s-master-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.11"); \
LB_IP=$$(grep "lb-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.31"); \
MON_IP=$$(grep "monitoring-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.41"); \
echo "  Kubernetes API: https://$$VIP:6443"; \
echo "  HAProxy Stats: http://$$LB_IP:8404/stats (admin/admin)"; \
echo "  Prometheus: http://$$MON_IP:9090"; \
echo "  Grafana: http://$$MON_IP:3000 (admin/admin)"
echo ""
echo "Next steps:"
echo "  1. Copy kubeconfig: scp ubuntu@$$K8S_MASTER_IP:~/.kube/config ~/.kube/config"
echo "  2. Update server address: kubectl config set-cluster kubernetes --server=https://$$VIP:6443"
echo "  3. Deploy application: kubectl apply -f ../javawebapp-deployment.yml"
echo "  4. Configure Grafana dashboards"
echo ""
