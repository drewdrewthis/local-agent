# Clara Gemmastone Agent Sandbox

.PHONY: help build start stop shell logs clean test-apis clara

help:
	@echo "Clara Agent Sandbox"
	@echo ""
	@echo "  make build      Build container"
	@echo "  make start      Start sandbox (VNC at http://localhost:6080)"
	@echo "  make clara      Start Clara (cursor-cli agent)"
	@echo "  make stop       Stop sandbox"
	@echo "  make shell      Open shell in sandbox"
	@echo "  make logs       View logs"
	@echo "  make test-apis  Verify API connectivity"
	@echo "  make clean      Remove container/image"

build:
	docker compose build

start:
	docker compose up -d
	@echo "✅ Sandbox running - VNC: http://localhost:6080"

clara:
	@docker compose exec clara specstory run --no-cloud-sync cursor -c "cursor-agent --model grok"

stop:
	docker compose down

shell:
	docker compose exec clara bash || docker compose run --rm clara bash

logs:
	docker compose logs -f

test-apis:
	docker compose exec clara bash -c '\
		echo "=== Google ===" && \
		/workspace/scripts/google/bin/token-refresh && \
		echo "=== Todoist ===" && \
		/workspace/scripts/todoist/bin/todoist projects'

clean:
	docker compose down -v --rmi local
