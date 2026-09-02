#!/usr/bin/env python3
from pathlib import Path

target = Path("utils/broadcast_server.py")
if target.exists():
    content = target.read_text()
    
    os_patch = """if __name__ == "__main__":
    try:
        import resource
        soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
        resource.setrlimit(resource.RLIMIT_NOFILE, (min(65535, hard), hard))
        print(f"🔓 OS File Descriptor Limits bumped.")
    except Exception as e:
        pass"""
        
    if 'if __name__ == "__main__":' in content:
        target.write_text(content.replace('if __name__ == "__main__":', os_patch))
        print("✅ broadcast_server.py restored and file limits re-applied safely.")
