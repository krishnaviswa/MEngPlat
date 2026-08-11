#!/usr/bin/env python3
"""Regenerate mobile/openapi.json and mobile/packages/merchanthub_api from the
live FastAPI schema. Run this after backend routes/schemas change.

Requires a JRE and openapi-generator-cli-7.14.0.jar. Portable defaults below match
the original Windows layout (Temurin JRE under C:/src/jre, generator JAR under
C:/src/openapi-generator/, Flutter under C:/src/flutter) — see README.md Mobile
client section. Override with JAVA_BIN / OPENAPI_GENERATOR_JAR / FLUTTER_BIN /
DART_BIN if yours live elsewhere.

Usage (from repo root or mobile/):
    python mobile/scripts/generate_api_client.py
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = REPO_ROOT / "backend"
MOBILE_DIR = REPO_ROOT / "mobile"
OPENAPI_JSON = MOBILE_DIR / "openapi.json"
CLIENT_OUT_DIR = MOBILE_DIR / "packages" / "merchanthub_api"

JAVA_BIN = os.environ.get("JAVA_BIN", "C:/src/jre/bin/java")
OPENAPI_GENERATOR_JAR = os.environ.get(
    "OPENAPI_GENERATOR_JAR", "C:/src/openapi-generator/openapi-generator-cli-7.14.0.jar"
)
FLUTTER_BIN = os.environ.get("FLUTTER_BIN", "C:/src/flutter/bin/flutter")
DART_BIN = os.environ.get("DART_BIN", "C:/src/flutter/bin/dart")


def _blank_to_none(value: object) -> object:
    return None if value == "" else value


def _fix_nullable(node: object) -> None:
    """Rewrite Pydantic v2's 3.1-style `anyOf: [type, null]` into real OAS
    3.0 `nullable: true`. FastAPI's `openapi_version` param only stamps the
    top-level version string -- it doesn't rewrite nested schemas -- so
    without this, openapi-generator's dart-dio null-guard heuristic misses
    optional-without-a-default query params (they get serialized as `''`
    instead of omitted, which 422s non-string types server-side)."""
    if isinstance(node, dict):
        any_of = node.get("anyOf")
        if isinstance(any_of, list) and len(any_of) == 2:
            null_branches = [b for b in any_of if isinstance(b, dict) and b.get("type") == "null"]
            other_branches = [b for b in any_of if not (isinstance(b, dict) and b.get("type") == "null")]
            if len(null_branches) == 1 and len(other_branches) == 1:
                other = dict(other_branches[0])
                other["nullable"] = True
                for key, value in node.items():
                    if key != "anyOf":
                        other[key] = value
                node.clear()
                node.update(other)
        for value in node.values():
            _fix_nullable(value)
    elif isinstance(node, list):
        for item in node:
            _fix_nullable(item)


def export_openapi_schema() -> None:
    sys.path.insert(0, str(BACKEND_DIR))
    os.environ.setdefault("PYTHONPATH", str(BACKEND_DIR))
    from fastapi.openapi.utils import get_openapi  # noqa: PLC0415

    from app.main import app  # noqa: PLC0415

    schema = get_openapi(
        title=app.title,
        version=app.version,
        openapi_version="3.0.3",
        description=app.description,
        routes=app.routes,
    )
    _fix_nullable(schema)
    OPENAPI_JSON.write_text(json.dumps(schema, indent=2))
    print(f"Exported {OPENAPI_JSON} ({len(schema['paths'])} paths)")


def run_generator() -> None:
    subprocess.run(
        [
            JAVA_BIN,
            "-jar",
            OPENAPI_GENERATOR_JAR,
            "generate",
            "-i",
            str(OPENAPI_JSON),
            "-g",
            "dart-dio",
            "-o",
            str(CLIENT_OUT_DIR),
            "--additional-properties="
            "pubName=merchanthub_api,pubLibrary=merchanthub_api,nullableFields=true,serializationLibrary=built_value",
        ],
        check=True,
    )


def build_dart_client() -> None:
    subprocess.run([FLUTTER_BIN, "pub", "get"], cwd=CLIENT_OUT_DIR, check=True)
    subprocess.run([DART_BIN, "run", "build_runner", "build"], cwd=CLIENT_OUT_DIR, check=True)
    subprocess.run([FLUTTER_BIN, "pub", "get"], cwd=MOBILE_DIR, check=True)


if __name__ == "__main__":
    export_openapi_schema()
    run_generator()
    build_dart_client()
    print("Done. Run `flutter analyze` and `flutter test` in mobile/ to confirm nothing broke.")
