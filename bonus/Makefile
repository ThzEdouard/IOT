.PHONY: install apply run connect setup-gitlab setup-gitlab-namespace init-repo clean add-repo

install:
	@if k3d cluster list | grep -q bonus; then \
		echo "Cluster bonus already exists. Deleting it..."; \
		k3d cluster delete bonus; \
	fi
	@echo "Creating K3D cluster..."
	@k3d cluster create bonus --k3s-arg "--disable=traefik@server:0"
	@echo "Configuring kubectl..."
	@export KUBECONFIG=$$(k3d kubeconfig write bonus)
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
		--from-literal=url=git@172.19.0.1:gitlab/iot.git \
		--from-literal=insecure=true \
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

connect:
	@echo "Connecting to playground pod in dev namespace..."
	@POD_NAME=$$(kubectl get pods -n dev -l app=playground -o jsonpath="{.items[0].metadata.name}") && \
	if [ -z "$$POD_NAME" ]; then \
		echo "Error: No playground pods found in dev namespace"; \
		exit 1; \
	else \
		echo "Connecting to pod: $$POD_NAME"; \
		if ! kubectl exec $$POD_NAME -n dev -- which curl > /dev/null 2>&1; then \
			kubectl exec $$POD_NAME -n dev -- apk add --no-cache curl; \
			kubectl exec $$POD_NAME -n dev -- apk add --no-cache openssh-client; \
			kubectl exec $$POD_NAME -n dev -- apk add --no-cache git; \
		fi; \
		kubectl exec -it $$POD_NAME -n dev -- /bin/sh; \
	fi 

setup-gitlab:
	@echo "Setting up local GitLab instance..."
	@if ! docker ps | grep -q gitlab; then \
		echo "Starting GitLab container..."; \
		docker run --detach \
			--hostname localhost \
			--publish 22:22 \
			--publish 8080:80 \
			--publish 8443:443 \
			--name gitlab \
			--restart always \
			--volume gitlab-config:/etc/gitlab \
			--volume gitlab-logs:/var/log/gitlab \
			--volume gitlab-data:/var/opt/gitlab \
			gitlab/gitlab-ce:latest; \
		echo "GitLab is starting up. This may take a few minutes..."; \
		i=0; \
		while ! curl -s http://localhost:8080/-/health > /dev/null; do \
			case $$i in \
				0) spin="─";; \
				1) spin="\\";; \
				2) spin="|";; \
				3) spin="/";; \
			esac; \
			printf "\r[ $$spin ] Waiting for GitLab..."; \
			i=$$((( i + 1 ) % 4)); \
			sleep 1; \
		done; \
		printf "\rGitLab is ready!                  \n"; \
		echo "Access GitLab at http://localhost:8080"; \
		echo "Username: root"; \
		echo "Password: $$(docker exec gitlab grep 'Password:' /etc/gitlab/initial_root_password | cut -d ' ' -f 2)"; \
	else \
		echo "GitLab container is already running."; \
	fi

init-repo:
	@bash scripts/gitlab_namespace.sh
	@bash scripts/gitlab_repository.sh
	@bash scripts/gitlab_ssh_key.sh
	@if [ -d ".git" ] && git remote -v | grep -q "localhost:gitlab/iot.git"; then \
		echo "Git repository already initialized with correct remote. Skipping git operations."; \
	else \
		if [ -d ".git" ]; then \
			echo "Found existing .git directory with wrong remote. Removing it..."; \
			rm -rf .git; \
		fi; \
		echo "Removing any existing SSH host key for localhost..."; \
		ssh-keygen -f ~/.ssh/known_hosts -R localhost || true; \
		echo "Setting up Git repository and adding the host key automatically..."; \
		git init && \
		git add confs/*.yaml && \
		git config --local user.email "local@example.com" && \
		git config --local user.name "Local User" && \
		git commit -m "Initial commit" && \
		git remote add origin git@localhost:gitlab/iot.git && \
		echo "Attempting to push to GitLab..." && \
		GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git push -uf origin master || echo "Failed to push. Please push manually."; \
	fi

clean:
	@if k3d cluster list | grep -q bonus; then \
		echo "Deleting K3D cluster bonus..."; \
		k3d cluster delete bonus; \
	else \
		echo "No K3D cluster named bonus found."; \
	fi
	@if docker ps -a | grep -q gitlab; then \
		echo "Stopping and removing GitLab container..."; \
		docker stop gitlab; \
		docker rm gitlab; \
		echo "Removing GitLab volumes..."; \
		docker volume rm gitlab-config gitlab-logs gitlab-data; \
	else \
		echo "No GitLab container found."; \
	fi
	@echo "Removing all stopped containers..."
	@docker container prune -f
	@echo "Clean-up complete."
