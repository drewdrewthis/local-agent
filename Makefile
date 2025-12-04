.PHONY: build shell run clean help

# Build and run container with interactive shell
shell: build
	@echo "Starting cursor-agent sandbox container..."
	@echo "Container provides isolated file system access"
	@echo "Use 'cursor-agent' command inside the container (note: native modules may fail)"
	@echo "Type 'exit' to quit the sandbox"
	docker run -it --rm --name cursor-sandbox \
		-v $(PWD):/workspace \
		-v cursor-data:/root/.cursor \
		cursor-sandbox /bin/bash

# Run demo showing sandboxing works
demo: build
	@echo "Running sandbox demo..."
	docker run --rm cursor-sandbox

# Build the Docker image
build:
	docker build -t cursor-sandbox .

# Run container in background (for testing)
run: build
	docker run -d --rm --name cursor-sandbox \
		-v $(PWD):/workspace \
		-v cursor-data:/root/.cursor \
		cursor-sandbox

# Clean up
clean:
	docker rm -f cursor-sandbox || true
	docker rmi cursor-sandbox || true

# Show available commands
help:
	@echo "Available commands:"
	@echo "  make shell  - Interactive shell in sandboxed container"
	@echo "  make demo   - Run automated demo showing sandboxing works"
	@echo "  make build  - Build Docker image with cursor-agent installed"
	@echo "  make run    - Run container in background"
	@echo "  make clean  - Remove container and image"
	@echo "  make help   - Show this help"
	@echo ""
	@echo "Sandboxing achieved:"
	@echo "  ✅ Isolated file system access via volume mounts"
	@echo "  ✅ cursor-agent CLI installed and available"
	@echo "  ✅ Controlled access to workspace files only"
	@echo "  ✅ Process isolation from host system"
	@echo "  ⚠️  cursor-agent has native module compatibility issues in Alpine"
	@echo "      (expected - designed for Ubuntu/Debian)"