.PHONY: help install check setup docker k8s loadbalancer monitoring verify clean

# Default inventory file
INVENTORY ?= inventory/hosts.ini

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Install Ansible collections
	@echo "$(BLUE)Installing Ansible collections...$(NC)"
	ansible-galaxy install -r requirements.yml

check: ## Check connectivity to all servers
	@echo "$(BLUE)Testing connectivity to all servers...$(NC)"
	ansible all -i $(INVENTORY) -m ping

setup: install check ## Full infrastructure setup (all components)
	@echo "$(BLUE)Starting full infrastructure setup...$(NC)"
	ansible-playbook -i $(INVENTORY) site.yml

docker: ## Install Docker and containerd only
	@echo "$(BLUE)Installing Docker and containerd...$(NC)"
	ansible-playbook -i $(INVENTORY) playbooks/01-docker-setup.yml

k8s: ## Setup Kubernetes cluster only
	@echo "$(BLUE)Setting up Kubernetes cluster...$(NC)"
	ansible-playbook -i $(INVENTORY) playbooks/02-kubernetes-setup.yml

loadbalancer: ## Setup HAProxy and Keepalived only
	@echo "$(BLUE)Setting up load balancers...$(NC)"
	ansible-playbook -i $(INVENTORY) playbooks/05-keepalived-scripts.yml
	ansible-playbook -i $(INVENTORY) playbooks/03-loadbalancer-setup.yml

monitoring: ## Setup Prometheus and Grafana only
	@echo "$(BLUE)Setting up monitoring stack...$(NC)"
	ansible-playbook -i $(INVENTORY) playbooks/04-monitoring-setup.yml

verify: ## Verify infrastructure health
	@echo "$(BLUE)Running infrastructure health check...$(NC)"
	./verify-infrastructure.sh

status: ## Show status of all services
	@echo "$(BLUE)Checking service status...$(NC)"
	@echo "\n$(GREEN)Docker:$(NC)"
	ansible docker_hosts -i $(INVENTORY) -m shell -a "systemctl is-active docker" 2>/dev/null || true
	@echo "\n$(GREEN)Kubernetes:$(NC)"
	ansible k8s_masters[0] -i $(INVENTORY) -m shell -a "kubectl get nodes" 2>/dev/null || true
	@echo "\n$(GREEN)HAProxy:$(NC)"
	ansible loadbalancers -i $(INVENTORY) -m shell -a "systemctl is-active haproxy" 2>/dev/null || true
	@echo "\n$(GREEN)Prometheus:$(NC)"
	ansible monitoring -i $(INVENTORY) -m shell -a "systemctl is-active prometheus" 2>/dev/null || true

restart-haproxy: ## Restart HAProxy on load balancers
	@echo "$(YELLOW)Restarting HAProxy...$(NC)"
	ansible loadbalancers -i $(INVENTORY) -m systemd -a "name=haproxy state=restarted" --become

restart-keepalived: ## Restart Keepalived on load balancers
	@echo "$(YELLOW)Restarting Keepalived...$(NC)"
	ansible loadbalancers -i $(INVENTORY) -m systemd -a "name=keepalived state=restarted" --become

restart-prometheus: ## Restart Prometheus
	@echo "$(YELLOW)Restarting Prometheus...$(NC)"
	ansible monitoring -i $(INVENTORY) -m systemd -a "name=prometheus state=restarted" --become

restart-grafana: ## Restart Grafana
	@echo "$(YELLOW)Restarting Grafana...$(NC)"
	ansible monitoring -i $(INVENTORY) -m systemd -a "name=grafana-server state=restarted" --become

get-kubeconfig: ## Copy kubeconfig from master
	@echo "$(BLUE)Copying kubeconfig...$(NC)"
	@MASTER_IP=$$(grep "k8s-master-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+'); \
	scp ubuntu@$$MASTER_IP:~/.kube/config ~/.kube/config && \
	echo "$(GREEN)Kubeconfig copied to ~/.kube/config$(NC)"

logs-haproxy: ## View HAProxy logs
	ansible loadbalancers[0] -i $(INVENTORY) -m shell -a "tail -50 /var/log/haproxy.log" --become 2>/dev/null || \
	ansible loadbalancers[0] -i $(INVENTORY) -m shell -a "journalctl -u haproxy -n 50 --no-pager" --become

logs-keepalived: ## View Keepalived logs
	ansible loadbalancers -i $(INVENTORY) -m shell -a "tail -20 /var/log/keepalived-transitions.log" --become 2>/dev/null || true
	ansible loadbalancers[0] -i $(INVENTORY) -m shell -a "journalctl -u keepalived -n 30 --no-pager" --become

logs-prometheus: ## View Prometheus logs
	ansible monitoring -i $(INVENTORY) -m shell -a "journalctl -u prometheus -n 50 --no-pager" --become

clean: ## Clean up Ansible cache and logs
	@echo "$(YELLOW)Cleaning up...$(NC)"
	rm -f *.log *.retry
	rm -rf /tmp/ansible_facts
	@echo "$(GREEN)Cleanup completed$(NC)"

update-inventory: ## Update inventory with current IPs (interactive)
	@echo "$(BLUE)Updating inventory...$(NC)"
	@echo "Edit inventory/hosts.ini with your server IPs"
	$${EDITOR:-vi} inventory/hosts.ini

backup-etcd: ## Backup etcd on first master
	@echo "$(BLUE)Backing up etcd...$(NC)"
	ansible k8s_masters[0] -i $(INVENTORY) -m shell -a "ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-snapshot-$$(date +%Y%m%d-%H%M%S).db --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key" --become

info: ## Display access information
	@echo "$(BLUE)Infrastructure Access Information$(NC)"
	@echo ""
	@VIP=$$(grep "virtual_ip" $(INVENTORY) | grep -oP '=\K[^ ]+' || echo "192.168.1.100"); \
	LB_IP=$$(grep "lb-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.31"); \
	MON_IP=$$(grep "monitoring-1" $(INVENTORY) | grep -oP 'ansible_host=\K[^ ]+' || echo "192.168.1.41"); \
	echo "$(GREEN)Kubernetes API:$(NC) https://$$VIP:6443"; \
	echo "$(GREEN)HAProxy Stats:$(NC) http://$$LB_IP:8404/stats (admin/admin)"; \
	echo "$(GREEN)Prometheus:$(NC) http://$$MON_IP:9090"; \
	echo "$(GREEN)Grafana:$(NC) http://$$MON_IP:3000 (admin/admin)"

.DEFAULT_GOAL := help
