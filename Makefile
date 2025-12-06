# Development Tools Makefile
# Install and manage Google/Todoist CLI tools

.PHONY: help install install-google install-todoist uninstall clean test

# Default target
help:
	@echo "Development Tools Manager"
	@echo ""
	@echo "Available targets:"
	@echo "  install          Install all tools to system"
	@echo "  install-google   Install Google tools only"
	@echo "  install-todoist  Install Todoist tools only"
	@echo "  uninstall        Remove all tools from system"
	@echo "  clean            Clean build artifacts"
	@echo "  test             Run tests"
	@echo ""
	@echo "Usage:"
	@echo "  make install          # Install everything"
	@echo "  make install-google   # Install Google tools"
	@echo "  sudo make install     # Install system-wide"

# Installation directories
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/dev-tools
SHAREDIR = $(PREFIX)/share/dev-tools

# Install all tools
install: install-google install-todoist
	@echo "✅ All tools installed!"
	@echo "Add $(BINDIR) to your PATH:"
	@echo "  export PATH=\"$(BINDIR):\$$PATH\""

# Install Google tools
install-google:
	@echo "Installing Google tools..."
	mkdir -p $(BINDIR) $(LIBDIR)/google $(SHAREDIR)
	cp -r scripts/google/lib/* $(LIBDIR)/google/
	cp scripts/google/README.md $(SHAREDIR)/google-README.md
	ln -sf $(PWD)/scripts/google/bin/* $(BINDIR)/
	chmod +x $(BINDIR)/google-*
	@echo "✅ Google tools installed to $(BINDIR)"

# Install Todoist tools
install-todoist:
	@echo "Installing Todoist tools..."
	mkdir -p $(BINDIR) $(LIBDIR)/todoist $(SHAREDIR)
	cp -r scripts/todoist/lib/* $(LIBDIR)/todoist/
	cp scripts/todoist/README.md $(SHAREDIR)/todoist-README.md
	ln -sf $(PWD)/scripts/todoist/bin/* $(BINDIR)/
	chmod +x $(BINDIR)/todoist*
	@echo "✅ Todoist tools installed to $(BINDIR)"

# Uninstall all tools
uninstall:
	@echo "Uninstalling tools..."
	rm -f $(BINDIR)/google-* $(BINDIR)/todoist*
	rm -rf $(LIBDIR) $(SHAREDIR)
	@echo "✅ Tools uninstalled"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	find . -name "*.log" -delete
	find . -name "*.tmp" -delete
	@echo "✅ Cleaned"

# Run tests
test:
	@echo "Running tests..."
	@# Test Google tools
	@if command -v google-check >/dev/null 2>&1; then \
		echo "✅ Google tools available"; \
	else \
		echo "❌ Google tools not found - run 'make install-google'"; \
	fi
	@# Test Todoist tools
	@if command -v todoist >/dev/null 2>&1; then \
		echo "✅ Todoist tools available"; \
	else \
		echo "❌ Todoist tools not found - run 'make install-todoist'"; \
	fi

# System-wide installation (requires sudo)
install-system: PREFIX = /usr/local
install-system: install
	@echo "✅ Installed system-wide to /usr/local/bin"

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	@echo "export PATH=\"$(PWD)/scripts/google/bin:$(PWD)/scripts/todoist/bin:\$$PATH\"" >> ~/.zshrc
	@echo "✅ Added to ~/.zshrc - restart shell or run: source ~/.zshrc"

# Show status
status:
	@echo "Tool Status:"
	@echo "Google tools:  $(if command -v google-check >/dev/null 2>&1; then echo "✅ Installed"; else echo "❌ Not installed"; fi)"
	@echo "Todoist tools: $(if command -v todoist >/dev/null 2>&1; then echo "✅ Installed"; else echo "❌ Not installed"; fi)"
	@echo ""
	@echo "Installation directories:"
	@echo "  Binaries: $(BINDIR)"
	@echo "  Libraries: $(LIBDIR)"
	@echo "  Docs: $(SHAREDIR)"

start:
	@echo "Starting cursor-agent..."
	@bash -c 'source .env && cursor-agent --model "grok"'
