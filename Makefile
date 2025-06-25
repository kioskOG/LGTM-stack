.DEFAULT_GOAL := help

# -------------------------------------
# Namespaces
NAMESPACE_loki  = loki
NAMESPACE_tempo = tempo
NAMESPACE_alloy = alloy-logs
NAMESPACE_mimir = mimir
NAMESPACE_kps   = monitoring

# -------------------------------------
# Chart sources
CHART_loki  = grafana/loki
CHART_tempo = grafana/tempo-distributed
CHART_alloy = grafana/alloy
CHART_mimir = grafana/mimir-distributed
CHART_kps   = ./kube-prometheus-stack

# -------------------------------------
# Chart versions
VERSION_loki  = 6.30.1
VERSION_tempo = 1.42.2
VERSION_alloy = 1.1.1
VERSION_mimir = 5.7.0

# -------------------------------------
# Values files
VALUES_loki  = ./loki/loki-override-values.yaml
VALUES_tempo = ./tempo/tempo-override-values.yaml
VALUES_alloy = ./alloy/alloy-override-values.yaml
VALUES_mimir = ./mimir/mimir-override-values.yaml
VALUES_kps   = ./kube-prometheus-stack/prometheus-values.yaml

# -------------------------------------
# Helm repo & namespace bootstrap
# Helm repo & namespace bootstrap
init:
	@echo "👉 Adding Helm repo if missing and updating..."
	@helm repo add grafana https://grafana.github.io/helm-charts || true
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo update
	@echo "👉 Ensuring required namespaces exist..."
	@for ns in $(NAMESPACE_loki) $(NAMESPACE_tempo) $(NAMESPACE_alloy) $(NAMESPACE_mimir) $(NAMESPACE_kps); do \
		if ! kubectl get namespace $$ns > /dev/null 2>&1; then \
			echo "✅ Creating namespace: $$ns"; \
			kubectl create namespace $$ns; \
		else \
			echo "⚙️  Namespace $$ns already exists. Skipping."; \
		fi \
	done

# -------------------------------------
# Install Targets
install-loki:
	helm upgrade --install loki $(CHART_loki) \
		--version $(VERSION_loki) \
		-n $(NAMESPACE_loki) \
		--values $(VALUES_loki) \
		--debug

install-tempo:
	helm upgrade --install tempo $(CHART_tempo) \
		--version $(VERSION_tempo) \
		-n $(NAMESPACE_tempo) \
		--values $(VALUES_tempo) \
		--debug

install-alloy:
	@if ! kubectl get configmap alloy-config -n $(NAMESPACE_alloy) > /dev/null 2>&1; then \
		echo "📦 Applying alloy ConfigMap..."; \
		kubectl apply -f ./alloy/alloy-logs-configMap.yml; \
	else \
		echo "✅ ConfigMap 'alloy-config' already exists. Skipping apply."; \
	fi
	helm upgrade --install grafana-alloy $(CHART_alloy) \
		--version $(VERSION_alloy) \
		-n $(NAMESPACE_alloy) \
		--values $(VALUES_alloy) \
		--debug

install-mimir:
	helm upgrade --install mimir $(CHART_mimir) \
		--version $(VERSION_mimir) \
		-n $(NAMESPACE_mimir) \
		--values $(VALUES_mimir) \
		--debug

install-kps:
	helm upgrade --install kube-prometheus-stack $(CHART_kps) \
		-n $(NAMESPACE_kps) \
		--values $(VALUES_kps) \
		--debug

# -------------------------------------
# Uninstall Targets
uninstall-%:
	helm uninstall $* -n $(NAMESPACE_$*) || true

# -------------------------------------
# Uninstall Alloy
uninstall-alloy:
	helm uninstall grafana-alloy -n alloy-logs || true

# -------------------------------------
# Status Targets
status-%:
	kubectl get all -n $(NAMESPACE_$*)

# -------------------------------------
# Logs Targets
logs-%:
	kubectl logs -n $(NAMESPACE_$*) --tail=50 -l app.kubernetes.io/name=$*

# -------------------------------------
# Template Debug Targets
template-debug-%:
	helm template $* $(CHART_$*) -n $(NAMESPACE_$*) --values $(VALUES_$*) --debug

# -------------------------------------
# Batch Commands
install: init install-loki install-tempo install-alloy install-mimir install-kps
uninstall: uninstall-loki uninstall-tempo uninstall-mimir uninstall-kps
uninstall-alloy: uninstall-alloy
status: status-loki status-tempo status-alloy status-mimir status-kps
logs: logs-loki logs-tempo logs-alloy logs-mimir logs-kps
template-debug: template-debug-loki template-debug-tempo template-debug-alloy template-debug-mimir template-debug-kps

# Default goal
all: install


# -------------------------------------
# Help Target
help:
	@echo ""
	@echo "🚀 LGTM Stack Deployment Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make init                  - Add Helm repos and create namespaces"
	@echo "  make install               - Install all components (Loki, Tempo, Alloy, Mimir, KPS)"
	@echo "  make uninstall             - Uninstall all components"
	@echo "  make install-<component>   - Install specific component (e.g. install-loki)"
	@echo "  make uninstall-<component> - Uninstall specific component (e.g. uninstall-tempo)"
	@echo "  make status                - Show status of all components"
	@echo "  make logs                  - Show logs for all components"
	@echo "  make logs-<component>      - Tail logs of a component (e.g. logs-loki)"
	@echo "  make template-debug        - Render Helm templates for all components"
	@echo "  make template-debug-<comp> - Debug Helm templates for a component"
	@echo "  make all                   - Same as 'make install'"
	@echo ""
	@echo "Example:"
	@echo "  make install-loki"
	@echo "  make logs-tempo"
	@echo "  make template-debug-mimir"
	@echo ""