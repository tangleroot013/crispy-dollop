#!/usr/bin/env bash
# =============================================================================
# OPTIMIZE WORKSPACE - Defensive Automation & Script Sanitization
# =============================================================================
set -euo pipefail

TARGET_DIR="$HOME/bin/scripts"

echo "Checking for loose execution scripts in context..."

TARGET_SCRIPTS=(
    "god_master.py"
    "run_production_matrix.py"
    "run_tests.sh"
    "run_workspace_refactor.py"
    "patch_raw_shedder.py"
    "restore_limits.py"
    "setup.sh"
)

for script in "${TARGET_SCRIPTS[@]}"; do
    if [[ -f "$HOME/$script" ]]; then
        echo "Processing: $script -> Moving to workspace"
        mv "$HOME/$script" "$TARGET_DIR/"
        
        chmod +x "$TARGET_DIR/$script"
        
        # Safe shebang insertion logic
        if [[ "$script" == *.py ]] && ! head -n 1 "$TARGET_DIR/$script" | grep -q "#!"; then
            sed -i '1s|^|#!/usr/bin/env python3\n|' "$TARGET_DIR/$script"
            echo "   ↳ Python shebang patched."
        elif [[ "$script" == *.sh ]] && ! head -n 1 "$TARGET_DIR/$script" | grep -q "#!"; then
            sed -i '1s|^|#!/usr/bin/env bash\n|' "$TARGET_DIR/$script"
            echo "   ↳ Bash shebang patched."
        fi
    fi
done

echo "Workspace migration processing complete."
