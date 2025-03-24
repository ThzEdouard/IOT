.PHONY: install apply run

install:
	@if k3d cluster list | grep -q p3; then \
		echo "Cluster p3 already exists. Deleting it..."; \
		k3d cluster delete p3; \
	fi
	@echo "Creating K3D cluster..."
	@k3d cluster create p3 --k3s-arg "--disable=traefik@server:0"
	@echo "Configuring kubectl..."
	@export KUBECONFIG=$$(k3d kubeconfig write p3)
	@kubectl cluster-info
	@echo "Creating namespaces..."
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
	@echo "Installing Argo CD..."
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --validate=false
	@echo "Creating repository secret..."
	@kubectl create secret generic repo-secret \
		--namespace=argocd \
		--from-literal=type=git \
		--from-literal=url=git@github.com:julesmuntz/julmuntz.git \
		--from-file=sshPrivateKey=$$(ls ~/.ssh/id_* 2>/dev/null | grep -v "\.pub$$" | head -n 1) \
		--dry-run=client -o yaml | \
		kubectl label -f - --local -o yaml argocd.argoproj.io/secret-type=repository | \
		kubectl apply -f -
	@echo "Installing Argo CD application..."
	@find . -name "*.yaml" -exec kubectl apply -f {} \;
	@echo "Waiting for Argo CD to be ready..."
	@kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@echo "Argo CD admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo
	@echo "Setup complete!"

apply:
	@find . -name "*.yaml" -exec kubectl apply -f {} \;

run:
	@kubectl port-forward svc/argocd-server -n argocd 4242:443 