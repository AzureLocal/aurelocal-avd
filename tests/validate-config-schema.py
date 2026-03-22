"""
Validate all config YAML files against the JSON Schema.
Usage: python tests/validate-config-schema.py
"""

import json
import sys
from pathlib import Path

try:
    import yaml
    from jsonschema import validate, ValidationError
except ImportError:
    print("Install dependencies: pip install pyyaml jsonschema")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = REPO_ROOT / "config" / "schema" / "variables.schema.json"
EXAMPLE_CONFIG = REPO_ROOT / "config" / "variables.example.yml"
EXAMPLES_DIR = REPO_ROOT / "config" / "examples"


def load_schema():
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def validate_file(filepath, schema):
    data = yaml.safe_load(filepath.read_text(encoding="utf-8"))
    validate(instance=data, schema=schema)


def main():
    schema = load_schema()
    errors = 0
    validated = 0

    # Validate main example
    targets = []
    if EXAMPLE_CONFIG.exists():
        targets.append(EXAMPLE_CONFIG)
    if EXAMPLES_DIR.exists():
        targets.extend(sorted(EXAMPLES_DIR.glob("*.yml")))

    if not targets:
        print("No config files found to validate.")
        sys.exit(0)

    for f in targets:
        print(f"Validating {f.relative_to(REPO_ROOT)}...", end=" ")
        try:
            validate_file(f, schema)
            print("OK")
            validated += 1
        except ValidationError as e:
            print(f"FAIL\n  {e.message}")
            errors += 1
        except Exception as e:
            print(f"ERROR\n  {e}")
            errors += 1

    print(f"\n{validated} passed, {errors} failed out of {len(targets)} total.")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
