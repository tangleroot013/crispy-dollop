#!/usr/bin/env python3
# =============================================================================
# UNIFIED WORKSPACE DECOUPLING & REFACTORING SUITE
# Targets: Python Engine Matrices & Shell Runner Injections
# =============================================================================
import os
import re

def refactor_workspace():
    workspace_root = os.path.expanduser("~/god_stack")
    
    print("\033[1;34m[*] Commencing full workspace optimization matrix...\033[0m")
    
    # -------------------------------------------------------------------------
    # PHASE 1: REFACTORING PYTHON RUNNERS (e.g., run_all.py, courlan_router.py at root)
    # -------------------------------------------------------------------------
    python_targets = ["run_all.py", "courlan_router.py"]
    class_pattern = re.compile(r"class CourlanRouter:.*?(?=\nclass |\nif __name__ ==|\Z)", re.DOTALL)
    
    for filename in python_targets:
        file_path = os.path.join(workspace_root, filename)
        if not os.path.exists(file_path):
            continue
            
        # Skip refactoring the actual canonical utility file if it's already in utils/
        if filename == "courlan_router.py" and os.path.dirname(file_path).endswith("utils"):
            continue

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        if "class CourlanRouter:" in content:
            # If it's the root courlan_router.py, we can leave it or clear duplicates
            # For run_all.py, we strip the redundant definition and add the module import
            cleaned_content = class_pattern.sub("", content)
            
            import_line = "from utils.courlan_router import CourlanRouter\n"
            if "import" in cleaned_content:
                lines = cleaned_content.splitlines(keepends=True)
                lines.insert(1, import_line)
                cleaned_content = "".join(lines)
            else:
                cleaned_content = import_line + cleaned_content
                
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(cleaned_content)
            print(f"\033[1;32m[+] Python Layer Refactored: {filename} migrated to shared utility namespace.\033[0m")

    # -------------------------------------------------------------------------
    # PHASE 2: REFACTORING SHELL DEPLOYMENT RUNNERS
    # -------------------------------------------------------------------------
    scripts_dir = os.path.join(workspace_root, "scripts")
    if os.path.exists(scripts_dir):
        for root, _, files in os.walk(scripts_dir):
            for file in files:
                if file.endswith(".sh"):
                    file_path = os.path.join(root, file)
                    
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    if "class CourlanRouter" in content:
                        # Target python string blocks inside shell heredocs
                        heredoc_pattern = re.compile(r"cat\s+<<\s*['\"]?EOF['\"]?.*class CourlanRouter:.*?EOF", re.DOTALL)
                        
                        modular_env_snippet = (
                            "# Standardize local module path visibility\n"
                            "export PYTHONPATH=\"${HOME}/god_stack:${PYTHONPATH:-}\"\n\n"
                            "python3 -c \"\n"
                            "try:\n"
                            "    from utils.courlan_router import CourlanRouter\n"
                            "    print('✅ Courlan Router integration verified via PYTHONPATH setup.')\n"
                            "except ImportError:\n"
                            "    print('❌ Operational Error: Structural utility workspace path broken.')\n"
                            "    exit(1)\n"
                            "\""
                        )
                        
                        updated_content = heredoc_pattern.sub(modular_env_snippet, content)
                        
                        # Defensively inject safe bash setup if missing
                        if "set -euo pipefail" not in updated_content:
                            lines = updated_content.splitlines(keepends=True)
                            for idx, line in enumerate(lines):
                                if line.startswith("#!"):
                                    lines.insert(idx + 1, "set -euo pipefail\n")
                                    break
                            updated_content = "".join(lines)
                            
                        with open(file_path, "w", encoding="utf-8") as f:
                            f.write(updated_content)
                        print(f"\033[1;32m[+] Shell Runner Normalized: decoupled python logic from {file}.\033[0m")
                        
    print("\033[1;32m[✅] Optimization routine completed successfully.\033[0m")

if __name__ == "__main__":
    refactor_workspace()
