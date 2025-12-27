# Clara Gemmastone Agent Sandbox
# Manage sandboxed agent environment with headed browser support

.PHONY: help build start stop shell status logs clean vnc

help:
	@echo "Clara Agent Sandbox"
	@echo ""
	@echo "Commands:"
	@echo "  make build    Build Docker image"
	@echo "  make start    Start sandbox (background)"
	@echo "  make stop     Stop sandbox"
	@echo "  make shell    Open shell in sandbox"
	@echo "  make vnc      Open VNC in browser"
	@echo "  make status   Show sandbox status"
	@echo "  make logs     View sandbox logs"
	@echo "  make clean    Remove containers and images"
	@echo ""
	@echo "VNC available at: http://localhost:6080"

build:
	docker-compose build

start:
	docker-compose up -d
	@echo "✅ Sandbox started"
	@echo "VNC: http://localhost:6080"

stop:
	docker-compose down
	@echo "✅ Sandbox stopped"

shell:
	docker-compose exec local-agent bash || docker-compose run --rm local-agent bash

status:
	@echo "Sandbox Status:"
	@docker-compose ps
	@echo ""
	@echo "Agent Scripts:"
	@ls -la scripts/agent/*.sh 2>/dev/null || echo "  No agent scripts yet"
	@echo ""
	@echo "Registry:"
	@cat scripts/agent/registry.json 2>/dev/null | jq '.scripts | length' | xargs -I{} echo "  {} scripts registered"

logs:
	docker-compose logs -f

vnc:
	@echo "Opening VNC at http://localhost:6080"
	@open http://localhost:6080 2>/dev/null || xdg-open http://localhost:6080 2>/dev/null || echo "Open http://localhost:6080 in browser"

clean:
	docker-compose down -v --rmi local
	@echo "✅ Cleaned up"

# Test API connectivity from sandbox
test-apis:
	@echo "Testing API connectivity..."
	docker-compose run --rm local-agent bash -c '\
		source /workspace/.env && \
		echo "Testing Google..." && \
		/workspace/scripts/core/google/bin/token-refresh && \
		echo "✅ Google OK" && \
		echo "Testing Todoist..." && \
		/workspace/scripts/core/todoist/bin/todoist projects && \
		echo "✅ Todoist OK"'

# Create new agent script
new-script:
	@read -p "Script name: " name; \
	docker-compose exec local-agent bash -c "agent-new-script $$name"
