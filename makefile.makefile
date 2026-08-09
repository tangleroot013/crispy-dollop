.PHONY: install setup test monitor dns-test status update clean help

help:
	@echo "Quack! 🦆 Mullvad WireGuard Helper"
	@echo "==================================="
	@echo "make install    - Run full installation"
	@echo "make setup      - Run setup script"
	@echo "make test       - Test connection"
	@echo "make monitor    - Monitor VPN performance"
	@echo "make dns-test   - Test for DNS leaks"
	@echo "make status     - Show WireGuard status"
	@echo "make update     - Discover new servers"
	@echo "make clean      - Uninstall WireGuard"

install:
	sudo bash setup.sh

setup:
	bash scripts/auto-config.sh

test:
	bash scripts/test-connection.sh

monitor:
	bash scripts/performance-monitor.sh

dns-test:
	bash scripts/dns-leak-test.sh

status:
	sudo wg show

update:
	bash scripts/server-discovery.sh

clean:
	bash uninstall.sh