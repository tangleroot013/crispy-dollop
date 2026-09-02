import os
from pathlib import Path
from textwrap import dedent

god_dir = Path("/home/tangleroot013/github_projects/god_stack")
if not god_dir.exists():
    god_dir = Path("/home/tangleroot013/home-data/github_projects/god_stack")
conftest_content = dedent('''\
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock
import pytest

PROJECT_ROOT = Path(__file__).parent.absolute()
sys.path.insert(0, str(PROJECT_ROOT))
if (PROJECT_ROOT / "src").exists():
    sys.path.insert(0, str(PROJECT_ROOT / "src"))

os.environ.update({
    "REDIS_URL": "redis://localhost:6379/0",
    "API_KEY": "dummy_test_key_matrix",
    "DATABASE_URL": "sqlite:///:memory:",
    "OBSIDIAN_VAULT_PATH": "/tmp/dummy_vault",
    "ENVIRONMENT": "test",
    "HEADLESS": "true"
})

MOCK_MODULES = {
    'playwright', 'redis', 'bs4', 'selenium', 'requests', 'aiohttp', 'boto3',
    'undetected_chromedriver', 'fake_useragent', 'tenacity', 'celery',
    'pika', 'psutil', 'prometheus_client', 'fastapi', 'uvicorn',
    'httpx', 'sqlalchemy', 'pydantic', 'lxml', 'pyppeteer', 'scrapy',
    'webdriver_manager', 'dotenv', 'loguru', 'pandas', 'numpy',
    'motor', 'pymongo', 'beautifulsoup4'
}

for mod in list(MOCK_MODULES):
    sys.modules[mod] = MagicMock()
    sys.modules[f'{mod}.async_api'] = MagicMock()
    sys.modules[f"{mod}.sync_api'] = MagicMock()

class SelectiveMockFinder:
    @classmethod
    def find_spec(cls, fullname, path, target=None):
        base_mod = fullname.split('.')[0]
        if base_mod in MOCK_MODULES:
            from importlib.machinery import ModuleSpec
            class MockLoader:
                @classmethod
                def create_module(cls, spec): return MagicMock()
                @classmethod
                def exec_module(cls, module): pass
            return ModuleSpec(fullname, MockLoader())
        return None

sys.meta_path.insert(0, SelectiveMockFinder())

collect_ignore_glob = ["outputs/*", "outputs"]
''')
conftest_path = god_dir / "conftest.py"
conftest_path.write_text(conftest_content)
print(f"Successfully updated {conftest_path}")
