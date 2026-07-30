"""
Validator that enforces 1:1 mapping between schema containers/cases and spec files.

Checks that each feature and use-case markdown file declares exactly one schema
container in its YAML frontmatter ``schema_containers`` field. Multi-container
consolidation violates the architecture and is rejected.
"""

import os
import re
from typing import List

import yaml

from .base import IValidator
from ..core.workspace import WorkspaceRepository


def _extract_frontmatter(content: str):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not m:
        return None
    try:
        return yaml.safe_load(m.group(1).replace('\x01', ''))
    except Exception:
        return None


class SchemaCardinalityValidator(IValidator):
    def validate(self, repo: WorkspaceRepository, **kwargs) -> List[str]:
        rules = repo.get_codebase_rules()
        backlog_dirs = rules.backlog_directories
        
        schemas_dir_rel = getattr(backlog_dirs, "schemas", None)
        if not schemas_dir_rel:
            return []
        schemas_dir = os.path.join(repo.workspace_dir, schemas_dir_rel)
        if not os.path.exists(schemas_dir):
            return []
        schema_files = [f for f in os.listdir(schemas_dir) if not f.startswith('.')]
        if not schema_files:
            return []

        features_dir = os.path.join(repo.workspace_dir, backlog_dirs.features)
        use_cases_dir_rel = getattr(backlog_dirs, "use_cases", None)
        use_cases_dir = (
            os.path.join(repo.workspace_dir, use_cases_dir_rel)
            if use_cases_dir_rel
            else None
        )

        errors = []

        for dir_label, target_dir, file_type in [
            ("features", features_dir, "Feature"),
            ("use-cases", use_cases_dir, "Use Case"),
        ]:
            if not target_dir or not os.path.exists(target_dir):
                continue
            for filename in sorted(os.listdir(target_dir)):
                if not filename.endswith(".md"):
                    continue
                filepath = os.path.join(target_dir, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                except Exception:
                    continue

                fm = _extract_frontmatter(content)
                if fm is None:
                    continue

                containers = fm.get("schema_containers", None)
                if containers is None:
                    errors.append(
                        f"{file_type} '{filename}': schema_containers is missing from frontmatter. "
                        f"Every {file_type.lower()} must declare exactly one schema container "
                        f"(e.g. path: 'module/container', node_type: container)."
                    )
                    continue

                if not isinstance(containers, list):
                    errors.append(
                        f"{file_type} '{filename}': schema_containers must be a list, "
                        f"got {type(containers).__name__}"
                    )
                    continue

                n = len(containers)
                if n == 0:
                    errors.append(
                        f"{file_type} '{filename}': schema_containers is empty. "
                        f"Every {file_type.lower()} must declare exactly one schema container "
                        f"(e.g. path: 'module/container', node_type: container)."
                    )
                elif n > 1:
                    paths = [c.get("path", "?") if isinstance(c, dict) else str(c) for c in containers]
                    errors.append(
                        f"{file_type} '{filename}': Consolidation violation — "
                        f"schema_containers has {n} entries ({', '.join(paths)}). "
                        f"Each {file_type.lower()} must map to exactly one schema container. "
                        f"Split into separate files."
                    )

        return errors
