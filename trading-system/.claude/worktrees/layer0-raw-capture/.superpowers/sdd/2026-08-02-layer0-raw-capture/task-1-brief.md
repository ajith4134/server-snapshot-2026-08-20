### Task 1: Project scaffolding

**Files:**
- Create: `pyproject.toml`
- Create: `src/capture/__init__.py`
- Create: `tests/test_scaffolding.py`

**Interfaces:**
- Consumes: nothing
- Produces: importable package `capture`; the `uv run --python 3.12 pytest` command every later task uses

- [ ] **Step 1: Write the failing test**

```python
# tests/test_scaffolding.py
def test_package_imports():
    import capture
    assert capture.__version__ == "0.1.0"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ~/trading-system && uv run --python 3.12 pytest tests/test_scaffolding.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture'`

- [ ] **Step 3: Write minimal implementation**

```toml
# pyproject.toml
[project]
name = "capture"
version = "0.1.0"
requires-python = ">=3.12,<3.13"
dependencies = [
    "websockets>=17.0.1",
    "zstandard>=0.25.0",
    "aiohttp>=3.10",
]

[dependency-groups]
dev = ["pytest>=8.0", "pytest-asyncio>=0.24"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/capture"]

[tool.pytest.ini_options]
pythonpath = ["src"]
asyncio_mode = "auto"
testpaths = ["tests"]
```

```python
# src/capture/__init__.py
__version__ = "0.1.0"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_scaffolding.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pyproject.toml src/capture/__init__.py tests/test_scaffolding.py
git commit -m "feat: scaffold capture package on Python 3.12"
```

---

