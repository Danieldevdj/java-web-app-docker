#!/bin/bash
# Infrastructure Verification Script
# This script checks the health and status of all infrastructure components

set -e

echo "========================================"
echo "Infrastructure Health Check"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running with inventory file
if [ ! -f "inventory/hosts.ini" ]; then
    echo -e "${RED}Error: Please run this script from the ansible directory${NC}"
    exit 1
fi

# Function to print section header
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check service
check_service() {
    local host=$1
    local service=$2
    local description=$3
    
    if ansible $host -i inventory/hosts.ini -m shell -a "systemctl is-active $service" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $description: ${GREEN}Running${NC}"
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: ${RED}Not Running${NC}"
        return 1
    fi
}

# 1. Check Ansible connectivity
print_header "1. Connectivity Check"
if ansible all -i inventory/hosts.ini -m ping > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} All servers are reachable"
else
    echo -e "  ${RED}✗${NC} Some servers are unreachable"
    echo "  Run: ansible all -i inventory/hosts.ini -m ping"
    exit 1
fi

# 2. Check Docker installation
print_header "2. Docker & containerd Status"
ansible docker_hosts -i inventory/hosts.ini -m shell -a "docker --version 2>/dev/null || echo 'Not installed'" 2>/dev/null | grep -A1 "SUCCESS" | tail -1
check_service "docker_hosts" "docker" "Docker Service"
check_service "docker_hosts" "containerd" "containerd Service"

# 3. Check Kubernetes cluster
print_header "3. Kubernetes Cluster Status"
echo ""
echo "Kubernetes Nodes:"
ansible k8s_masters[0] -i inventory/hosts.ini -m shell -a "kubectl get nodes 2>/dev/null" 2>/dev/null | grep -A100 "SUCCESS" | tail -n +2 || echo "  Kubernetes not configured"
echo ""
echo "System Pods:"
ansible k8s_masters[0] -i inventory/hosts.ini -m shell -a "kubectl get pods -n kube-system 2>/dev/null | grep -E '(NAME|Running)'" 2>/dev/null | grep -A100 "SUCCESS" | tail -n +2 || echo "  No system pods found"

# 4. Check Load Balancers
print_header "4. Load Balancer Status"
check_service "loadbalancers" "haproxy" "HAProxy Service"
check_service "loadbalancers" "keepalived" "Keepalived Service"
echo ""
echo "Virtual IP Status:"
ansible loadbalancers -i inventory/hosts.ini -m shell -a "ip addr show | grep '192.168.1.100' || echo 'VIP not found on this node'" 2>/dev/null | grep -A1 "SUCCESS"

# 5. Check Monitoring
print_header "5. Monitoring Stack Status"
check_service "monitoring" "prometheus" "Prometheus Service"
check_service "monitoring" "grafana-server" "Grafana Service"
check_service "all" "node_exporter" "Node Exporter (all nodes)"

# 6. Port connectivity check
print_header "6. Service Endpoint Check"
echo ""
echo "Testing service endpoints..."

# Function to check port
check_port() {
    local host=$1
    local port=$2
    local description=$3
    
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description ($host:$port)"
    else
        echo -e "  ${YELLOW}⚠${NC} $description ($host:$port) - ${YELLOW}Not accessible${NC}"
    fi
}

# Get IPs from inventory
K8S_MASTER_IP=$(grep "k8s-master-1" inventory/hosts.ini | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.11")
LB_IP=$(grep "lb-1" inventory/hosts.ini | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.31")
MON_IP=$(grep "monitoring-1" inventory/hosts.ini | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.41")
VIP=$(grep "virtual_ip" inventory/hosts.ini | grep -oP '=\K[^ ]+' || echo "192.168.1.100")

check_port "$K8S_MASTER_IP" 6443 "Kubernetes API"
check_port "$LB_IP" 8404 "HAProxy Stats"
check_port "$MON_IP" 9090 "Prometheus"
check_port "$MON_IP" 3000 "Grafana"
check_port "$MON_IP" 9100 "Node Exporter"

# 7. Summary
print_header "7. Summary & Access Information"
echo ""
echo -e "${GREEN}Infrastructure Components:${NC}"
echo "  • Kubernetes Masters: 3 nodes"
echo "  • Kubernetes Workers: 5 nodes"
echo "  • Load Balancers: 2 nodes (HA)"
echo "  • Monitoring Server: 1 node"
echo ""
echo -e "${GREEN}Access URLs:${NC}"
echo "  • Kubernetes API: https://$VIP:6443"
echo "  • HAProxy Stats: http://$LB_IP:8404/stats (admin/admin)"
echo "  • Prometheus: http://$MON_IP:9090"
echo "  • Grafana: http://$MON_IP:3000 (admin/admin)"
echo ""
echo -e "${GREEN}Quick Commands:${NC}"
echo "  • Get kubeconfig: scp ubuntu@$K8S_MASTER_IP:~/.kube/config ~/.kube/config"
echo "  • Check cluster: kubectl get nodes"
echo "  • Deploy app: kubectl apply -f ../javawebapp-deployment.yml"
echo "  • View HAProxy stats: curl http://$LB_IP:8404/stats"
echo ""
echo "========================================"
echo -e "${GREEN}Health check completed!${NC}"
echo "========================================"
