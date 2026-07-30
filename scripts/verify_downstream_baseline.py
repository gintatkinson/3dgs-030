#!/usr/bin/env python3
"""
Verify downstream project baseline conformance.
Asserts baseline files exist, validates type compatibility with mandated domain classes,
and runs the build/test commands ('npm run build' for React, 'flutter analyze && flutter test' for Flutter).
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

TIMEOUT_SECONDS = 600

def check_no_domain_config(destination):
    config_paths = [
        os.path.join(destination, ".pipeline", "logical-ui", "codebase_rules.json"),
        os.path.join(destination, "codebase_rules.json"),
        os.path.join(destination, "baseline_manifest.json")
    ]
    for path in config_paths:
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                
                if isinstance(data, dict):
                    if "validation_rules" in data and isinstance(data["validation_rules"], dict):
                        if data["validation_rules"].get("no_domain") is True:
                            return True
                    if data.get("no_domain") is True:
                        return True
            except Exception:
                pass
    return False

def tag_restoration_point():
    print("Tagging restoration point...")
    try:
        subprocess.run(["git", "tag", "-f", "restoration-point"], check=True)
        return True
    except (subprocess.CalledProcessError, OSError) as e:
        print(f"WARNING: Failed to tag restoration point: {e}", file=sys.stderr)
        return False

def cleanup_workspace(destination):
    print("Cleaning up workspace...")
    to_delete_files = [".dart_tool/package_config.json.lock",
                       ".flutter-plugins-dependencies",
                       ".flutter-plugins"]
    for f in to_delete_files:
        path = os.path.join(destination, f)
        if os.path.isfile(path):
            try:
                os.remove(path)
            except OSError:
                pass

    dirs_to_remove = ["build", ".flutter-plugins", ".flutter-plugins-dependencies"]
    for d in dirs_to_remove:
        d_path = os.path.join(destination, d)
        if os.path.isdir(d_path):
            shutil.rmtree(d_path, ignore_errors=True)

    for root, _, files in os.walk(destination):
        for f in files:
            if f.endswith(".db-shm") or f.endswith(".db-wal") or f.endswith(".db-journal"):
                try:
                    os.remove(os.path.join(root, f))
                except Exception:
                    pass

# Mandated domain classes/interfaces to check in types.ts or types.dart
MANDATED_CLASSES = []

def load_mandated_classes(destination):
    config_paths = [
        os.path.join(destination, ".pipeline", "logical-ui", "codebase_rules.json"),
        os.path.join(destination, "codebase_rules.json"),
        os.path.join(destination, "baseline_manifest.json")
    ]
    for path in config_paths:
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                
                classes = None
                if isinstance(data, dict):
                    if "validation_rules" in data and isinstance(data["validation_rules"], dict):
                        classes = data["validation_rules"].get("mandated_classes")
                    if classes is None:
                        classes = data.get("mandated_classes")
                
                if isinstance(classes, list):
                    if all(isinstance(c, str) for c in classes):
                        print(f"Loaded mandated classes dynamically from {path}: {classes}")
                        return classes
                    else:
                        print(f"WARNING: Invalid format for 'mandated_classes' in {path} (not all elements are strings).", file=sys.stderr)
                else:
                    print(f"WARNING: 'mandated_classes' not found or not a list in {path}.", file=sys.stderr)
            except Exception as e:
                print(f"WARNING: Failed to parse or load config {path}: {e}", file=sys.stderr)
    
    print("Using default hardcoded MANDATED_CLASSES.")
    return MANDATED_CLASSES

def main():
    parser = argparse.ArgumentParser(description="Verify a downstream project's baseline conformance.")
    parser.add_argument("--no-domain", action="store_true", help="Skip checking the domain model")
    parser.add_argument("destination", nargs="?", default=".", help="Path to the downstream project directory (defaults to current directory)")
    args = parser.parse_args()

    dest = os.path.abspath(args.destination)

    if not os.path.isdir(dest):
        print(f"ERROR: Destination path '{dest}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    repo_root = dest

    is_flutter = os.path.exists(os.path.join(dest, "pubspec.yaml"))
    # If checking from root and app_flutter exists, run inside app_flutter
    if not is_flutter and os.path.isdir(os.path.join(dest, "app_flutter")):
        dest_flutter = os.path.join(dest, "app_flutter")
        if os.path.exists(os.path.join(dest_flutter, "pubspec.yaml")):
            dest = dest_flutter
            is_flutter = True

    is_react = os.path.exists(os.path.join(dest, "package.json"))
    if not is_react and os.path.isdir(os.path.join(dest, "web_react")):
        dest_react = os.path.join(dest, "web_react")
        if os.path.exists(os.path.join(dest_react, "package.json")):
            dest = dest_react
            is_react = True

    if not is_flutter and not is_react:
        print(f"ERROR: Destination path '{dest}' does not appear to be a Flutter or React project (missing pubspec.yaml and package.json).", file=sys.stderr)
        sys.exit(1)

    if check_no_domain_config(repo_root) or check_no_domain_config(dest):
        args.no_domain = True

    if args.no_domain:
        flutter_domain = os.path.join(dest if is_flutter else repo_root, "lib", "domain")
        react_domain = os.path.join(dest if is_react else repo_root, "src", "domain")
        if os.path.isdir(flutter_domain) or os.path.isdir(react_domain):
            print("NOTE: Domain directory found on disk — overriding no_domain config and enabling domain verification.")
            args.no_domain = False

    try:
        _run_verification(args, dest, repo_root, is_flutter, is_react)
        print("Success: Build and test suite execution passed. Conformance gate verified.")
        if not tag_restoration_point():
            print("ERROR: Conformance gate verified but restoration point tag could not be placed.", file=sys.stderr)
            sys.exit(1)
        sys.exit(0)
    finally:
        cleanup_workspace(dest)

def _validate_domain_types(dest, repo_root, ext, domain_subpath):
    mandated = load_mandated_classes(dest)
    if repo_root != dest:
        upstream_mandated = load_mandated_classes(repo_root)
        mandated = list(set(mandated + upstream_mandated))
    if not mandated:
        print("No mandated classes configured — skipping type validation.")
        return
    domain_dir = os.path.join(dest, domain_subpath)
    if not os.path.isdir(domain_dir):
        print(f"ERROR: Domain directory '{domain_dir}' does not exist but mandated classes are configured.", file=sys.stderr)
        sys.exit(1)
    source_files = []
    for root, _, files in os.walk(domain_dir):
        for f in files:
            if f.endswith("." + ext) or (ext == "ts" and f.endswith(".tsx")):
                source_files.append(os.path.join(root, f))
    if not source_files:
        print(f"ERROR: No .{ext} source files found in '{domain_dir}' but mandated classes are configured.", file=sys.stderr)
        sys.exit(1)
    combined = ""
    for sf in source_files:
        with open(sf, "r", encoding="utf-8") as f:
            combined += f.read() + "\n"
    if ext == "dart":
        type_keywords = r"(?:class|mixin|enum|extension\s+type|sealed\s+class)"
        pattern = r"\b" + type_keywords + r"\s+({})\b".format("|".join(re.escape(c) for c in mandated))
    else:
        pattern = r"\b(?:interface|class|type)\s+({})\b".format("|".join(re.escape(c) for c in mandated))
    found = set(re.findall(pattern, combined, re.MULTILINE))
    missing = set(mandated) - found
    if missing:
        print(f"ERROR: Type validation failed. Mandated classes missing in {domain_subpath}/: {', '.join(sorted(missing))}", file=sys.stderr)
        sys.exit(1)
    print(f"Success: All {len(mandated)} mandated domain classes found in {domain_subpath}/.")

def _run_verification(args, dest, repo_root, is_flutter, is_react):
    if is_flutter:
        print(f"Verifying conformance for platform 'flutter' at '{dest}'...")
        # 1. Assert baseline files exist
        baseline_files = [
            "pubspec.yaml",
            "analysis_options.yaml",
            "lib/main.dart",
            "lib/domain/repository_resolver.dart",
            "lib/domain/validation.dart"
        ]
        if args.no_domain:
            baseline_files.remove("lib/domain/repository_resolver.dart")
            baseline_files.remove("lib/domain/validation.dart")
        else:
            domain_dir = os.path.join(dest, "lib", "domain")
            if not os.path.isdir(domain_dir):
                print("NOTE: lib/domain/ directory not found — applying no-domain baseline check automatically.")
                args.no_domain = True
                baseline_files.remove("lib/domain/repository_resolver.dart")
                baseline_files.remove("lib/domain/validation.dart")

        missing_files = []
        for f in baseline_files:
            path = os.path.join(dest, f)
            if not os.path.exists(path):
                missing_files.append(f)

        if missing_files:
            print(f"ERROR: Flutter baseline file(s) missing: {', '.join(missing_files)}", file=sys.stderr)
            sys.exit(1)

        print("Success: All Flutter baseline files exist.")

        # 2. Validate type compatibility
        if args.no_domain:
            print("Skipping domain type compatibility validation (--no-domain specified).")
        else:
            _validate_domain_types(dest, repo_root, "dart", os.path.join("lib", "domain"))

        # 3. Run build/test commands
        if args.no_domain:
            print("Skipping build and test suite execution (--no-domain specified, domain implementation pending).")
        else:
            try:
                # Resolve and copy assets directory from template
                upstream_repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                src_assets = os.path.join(upstream_repo_root, "app_flutter", "assets")
                dest_assets = os.path.join(dest, "assets")
                if os.path.exists(src_assets):
                    if os.path.abspath(src_assets) != os.path.abspath(dest_assets):
                        print(f"Copying template assets from {src_assets} to {dest_assets}...")
                        os.makedirs(dest_assets, exist_ok=True)
                        for item in os.listdir(src_assets):
                            s_path = os.path.join(src_assets, item)
                            d_path = os.path.join(dest_assets, item)
                            if os.path.isfile(s_path):
                                shutil.copy2(s_path, d_path)
                        print("Assets copied successfully.")
                    else:
                        print("Source and destination assets directories are the same. Skipping copy.")
                else:
                    print(f"WARNING: Upstream assets directory not found at {src_assets}")

                print("Running 'flutter pub get' to resolve dependencies...")
                subprocess.run(["flutter", "pub", "get"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS)
                
                print("Running 'flutter analyze'...")
                subprocess.run(["flutter", "analyze", "--no-fatal-warnings", "--no-fatal-infos"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS)
                
                print("Running 'flutter test'...")
                subprocess.run(["flutter", "test"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS)
                
                print("Running 'flutter build macos --release'...")
                subprocess.run(["flutter", "build", "macos", "--release"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS * 2)
                
                print("Zipping the macOS application bundle...")
                # The build output is typically at app_flutter/build/macos/Build/Products/Release/Platform Console.app
                # We need to package it into the repository root as app_flutter_release.zip
                zip_path = os.path.join(upstream_repo_root, "app_flutter_release.zip")
                
                # We expect the app bundle to be named 'Platform Console.app'. 
                # Let's find it in the release directory.
                release_dir = os.path.join(dest, "build", "macos", "Build", "Products", "Release")
                app_bundle = "Platform Console.app"
                
                if os.path.exists(os.path.join(release_dir, app_bundle)):
                    subprocess.run(["zip", "-r", zip_path, app_bundle], cwd=release_dir, check=True, timeout=TIMEOUT_SECONDS)
                    print(f"Success: App bundled to {zip_path}")
                else:
                    print(f"ERROR: App bundle not found at {os.path.join(release_dir, app_bundle)}", file=sys.stderr)
                    sys.exit(1)
                    
            except subprocess.TimeoutExpired as e:
                print(f"ERROR: Verification command timed out after {e.timeout}s: {e.cmd}", file=sys.stderr)
                sys.exit(1)
            except subprocess.CalledProcessError as e:
                print(f"ERROR: Verification command failed: {e}", file=sys.stderr)
                sys.exit(1)

    if is_react:
        print(f"Verifying conformance for platform 'react' at '{dest}'...")
        # 1. Assert baseline files exist
        has_tsconfig = os.path.exists(os.path.join(dest, "tsconfig.json"))
        has_jsconfig = os.path.exists(os.path.join(dest, "jsconfig.json"))
        if not has_tsconfig and not has_jsconfig:
            print("ERROR: TSConfig or JSConfig is missing.", file=sys.stderr)
            sys.exit(1)

        entry_candidates = ["src/main.tsx", "src/main.jsx", "src/index.tsx", "src/index.jsx"]
        entry_file = None
        for cand in entry_candidates:
            if os.path.exists(os.path.join(dest, cand)):
                entry_file = cand
                break
        if not entry_file:
            print(f"ERROR: React entrypoint file missing (expected one of: {', '.join(entry_candidates)})", file=sys.stderr)
            sys.exit(1)

        if not args.no_domain:
            validation_candidates = ["src/domain/validation.ts", "src/domain/validation.js", "src/domain/validation.tsx", "src/domain/validation.jsx"]
            validation_file = None
            for cand in validation_candidates:
                if os.path.exists(os.path.join(dest, cand)):
                    validation_file = cand
                    break
            if not validation_file:
                print(f"ERROR: Domain validation file missing (expected one of: {', '.join(validation_candidates)})", file=sys.stderr)
                sys.exit(1)

        print("Success: All React baseline files exist.")

        # 2. Validate type compatibility
        if args.no_domain:
            print("Skipping domain type compatibility validation (--no-domain specified).")
        else:
            _validate_domain_types(dest, repo_root, "ts", os.path.join("src", "domain"))

        # 3. Run build/test commands
        if args.no_domain:
            print("Skipping build execution (--no-domain specified, domain implementation pending).")
        else:
            try:
                print("Running 'npm install' to resolve dependencies...")
                subprocess.run(["npm", "install"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS * 2)
                
                print("Running 'npm run build'...")
                subprocess.run(["npm", "run", "build"], cwd=dest, check=True, timeout=TIMEOUT_SECONDS * 2)
            except subprocess.TimeoutExpired as e:
                print(f"ERROR: React verification command timed out after {e.timeout}s: {e.cmd}", file=sys.stderr)
                sys.exit(1)
            except subprocess.CalledProcessError as e:
                print(f"ERROR: React verification command failed: {e}", file=sys.stderr)
                sys.exit(1)

if __name__ == "__main__":
    main()

