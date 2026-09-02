#!/usr/bin/env bash
# ==============================================================================
# G.O.D. STACK v1.5.0 ISOLATED TESTING HARNESS (PEP 668 COMPLIANT)
# ==============================================================================
set -euo pipefail

TARGET_DIR="/home/tangleroot013/god_stack"
VENV_DIR="${TARGET_DIR}/venv"

echo -e "\n\033[1;35m=== RUNNING G.O.D. STACK ARCHITECTURE VERIFICATION MATRIX ===\033[0m\n"

# 1. Enforce Virtual Environment isolation layer
if [ ! -d "${VENV_DIR}" ]; then
    echo "🌐 Environment isolation layer missing. Building workspace venv..."
    python3 -m venv "${VENV_DIR}"
fi

# 2. Activate the internal context
echo "🔋 Hydrating local execution context..."
source "${VENV_DIR}/bin/activate"

# 3. Upgrade basic installer framework and run safe pip sequence
pip install --upgrade pip --quiet
echo "📦 Injecting isolated package architecture..."
pip install pytest pytest-asyncio playwright pyyaml markdownify beautifulsoup4 --quiet

# 4. Bind the operational system library for Playwright engine compliance
echo "🎭 Verifying browser binaries runtime footprint..."
playwright install chromium

# 5. Map system pathways for localized validation
export PYTHONPATH="${TARGET_DIR}"

# 6. Fire up test metrics
pytest -v "${TARGET_DIR}/tests"

