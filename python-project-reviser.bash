#!/usr/bin/env bash

set -Eeuo pipefail

export UV_LINK_MODE=copy

readonly SUBMODULE_URL="https://github.com/tf4482/utils_python"

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd -P
)"

readonly PROJECT_DIR="$SCRIPT_DIR"
readonly APP_NAME="$(basename "$PROJECT_DIR")"

cd "$PROJECT_DIR"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info() {
    printf '\033[1;34mℹ️  %s\033[0m\n' "$*"
}

success() {
    printf '\033[1;32m✅ %s\033[0m\n' "$*"
}

warning() {
    printf '\033[1;33m⚠️  %s\033[0m\n' "$*"
}

die() {
    printf '\033[1;31m❌ Error: %s\033[0m\n' "$*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Requirements
# ---------------------------------------------------------------------------

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

require_command git
require_command uv

# ---------------------------------------------------------------------------
# Project information
# ---------------------------------------------------------------------------

project_revision() {
    local current_branch
    local repo_initialized=false

    # ------------------------------------------------------------
    # Initialize Git repository if necessary
    # ------------------------------------------------------------

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Initializing Git repository..."
        git init || return 1

        repo_initialized=true
    fi

    # ------------------------------------------------------------
    # Create initial commit for newly initialized repository
    # ------------------------------------------------------------

    if [[ "$repo_initialized" == true ]]; then
        echo "Creating initial commit..."

        git add -A || return 1

        git commit --allow-empty \
            -m "chore: 🎉 Initial commit" || return 1
    fi

    # ------------------------------------------------------------
    # Remember current branch
    # ------------------------------------------------------------

    current_branch="$(git branch --show-current)"

    echo "Current branch: $current_branch"

    # ------------------------------------------------------------
    # Create or switch to develop
    # ------------------------------------------------------------

    if git show-ref --verify --quiet refs/heads/develop; then
        echo "Switching to existing branch: develop"
        git switch develop || return 1
    else
        echo "Creating branch: develop"
        git switch -c develop || return 1
    fi

    # ------------------------------------------------------------
    # Commit current project state
    # ------------------------------------------------------------

    echo "Staging project files..."
    git add -A || return 1

    if git diff --cached --quiet; then
        echo "No changes to commit."
    else
        git commit \
            -m "chore: 🏗️ Preparation for project revision" || return 1
    fi

    # ------------------------------------------------------------
    # Ensure we are on develop
    # ------------------------------------------------------------

    git switch develop || return 1

    # ------------------------------------------------------------
    # Create feature branch
    # ------------------------------------------------------------

    if git show-ref --verify --quiet refs/heads/feature/project-revision; then
        echo "Branch feature/project-revision already exists."
        git switch feature/project-revision || return 1
    else
        echo "Creating branch: feature/project-revision"
        git switch -c feature/project-revision || return 1
    fi

    echo
    echo "Project revision branch ready."
    echo "Previous branch: $current_branch"
    echo "Current branch:  $(git branch --show-current)"
}

finish_project_revision() {
    # ------------------------------------------------------------
    # Stage all changes
    # ------------------------------------------------------------

    git add -A || return 1

    # ------------------------------------------------------------
    # Commit changes
    # ------------------------------------------------------------

    if git diff --cached --quiet; then
        echo "No changes to commit."
    else
        git commit \
            -m "feat: 💥 Changed project and dependency management, updated submodule and updated project files" ||
            return 1
    fi

    # ------------------------------------------------------------
    # Switch to develop
    # ------------------------------------------------------------

    git switch develop || return 1

    # ------------------------------------------------------------
    # Merge feature branch into develop
    # ------------------------------------------------------------

    git merge feature/project-revision || return 1

    echo
    echo "Project revision merged into develop."

}

printf '\n'
info "Project directory: $PROJECT_DIR"
info "Project name:      $APP_NAME"
printf '\n'

[[ "$APP_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] ||
    die "Invalid project name derived from directory: $APP_NAME"

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

project_revision

# ---------------------------------------------------------------------------
# Remove old Python project/environment management files
# ---------------------------------------------------------------------------

info "Removing old Python environments and project-management files..."

REMOVE_PATHS=(
    # Virtual environments
    ".venv"
    "venv"
    "env"
    "ENV"

    # uv
    "uv.lock"

    # Poetry
    "poetry.lock"

    # Pipenv
    "Pipfile"
    "Pipfile.lock"

    # PDM
    "pdm.lock"
    "pdm.toml"
    ".pdm-python"
    ".pdm-build"

    # Rye
    ".rye"

    # Hatch
    ".hatch"

    # tox / nox
    ".tox"
    ".nox"
    "tox.ini"
    "noxfile.py"

    # setuptools / legacy Python packaging
    "setup.py"
    "setup.cfg"
    "MANIFEST.in"

    # Python version manager metadata
    ".python-version"

    # Build artifacts
    "build"
    "dist"

    # Packaging metadata
    ".eggs"

    ".gitignore"
    ".editorconfig"
)

for path in "${REMOVE_PATHS[@]}"; do
    if [[ -e "$path" || -L "$path" ]]; then
        info "Removing: $path"
        rm -rf -- "$path"
    fi
done

# ---------------------------------------------------------------------------
# Remove generated Python package metadata
# ---------------------------------------------------------------------------

while IFS= read -r -d '' path; do
    info "Removing: $path"
    rm -rf -- "$path"
done < <(
    find . \
        -path './.git' -prune -o \
        -path './utils_python' -prune -o \
        \( \
        -type d \
        \( \
        -name '*.egg-info' -o \
        -name '*.dist-info' \
        \) \
        \) \
        -print0
)

# ---------------------------------------------------------------------------
# Remove old dependency files
# ---------------------------------------------------------------------------

while IFS= read -r -d '' file; do
    info "Removing old dependency file: $file"
    rm -f -- "$file"
done < <(
    find . \
        -maxdepth 1 \
        -type f \
        \( \
        -name 'requirements.txt' -o \
        -name 'requirements-*.txt' -o \
        -name 'requirements_*.txt' \
        \) \
        -print0
)

# ---------------------------------------------------------------------------
# Recreate pyproject.toml using uv
# ---------------------------------------------------------------------------

if [[ -f pyproject.toml ]]; then
    info "Removing existing pyproject.toml"
    rm -f pyproject.toml
fi

info "Initializing uv project..."

uv init \
    --name "$APP_NAME" \
    --app \
    --python 3.12 \
    --vcs none \
    --no-workspace \
    .

success "uv project initialized."

# ---------------------------------------------------------------------------
# Append tool configuration
# ---------------------------------------------------------------------------

cat >>pyproject.toml <<'EOF'

[tool.ruff]
target-version = "py312"
line-length = 100
extend-exclude = ["utils_python"]

[tool.ruff.lint]
select = [
    "E",
    "F",
    "I",
    "UP",
    "B",
    "SIM",
]

[tool.pyright]
pythonVersion = "3.12"
exclude = [
    "**/utils_python",
    "**/.venv",
    "**/.pytest_cache",
    "**/node_modules",
    "**/__pycache__",
    "**/.ruff_cache",
    "**/.*"
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
addopts = "-ra"

[tool.coverage.run]
branch = true

[tool.coverage.report]
show_missing = true
EOF

# ---------------------------------------------------------------------------
# Development dependencies
# ---------------------------------------------------------------------------

info "Installing development dependencies..."

uv add --dev \
    ruff \
    pytest \
    pytest-cov \
    pyright \
    pre-commit \
    pyinstaller \
    pip

success "Development dependencies installed."

# ---------------------------------------------------------------------------
# Pre-commit
# ---------------------------------------------------------------------------

cat >.pre-commit-config.yaml <<'EOF'
repos:
  - repo: local
    hooks:
      - id: ruff-check
        name: Ruff check
        entry: uv run ruff check --fix
        language: system
        types: [python]

      - id: ruff-format
        name: Ruff format
        entry: uv run ruff format
        language: system
        types: [python]
EOF

# ---------------------------------------------------------------------------
# Tests directory
# ---------------------------------------------------------------------------

mkdir -p tests

# ---------------------------------------------------------------------------
# Helper scripts
# ---------------------------------------------------------------------------

info "Creating helper scripts..."

cat >README.md <<EOF
# 🚀 ${APP_NAME}

Short description.

---

## ✨ Features

- ✅ Feature A
- ✅ Feature B
- ✅ Feature C
- 🔧 Easy to configure
- 🧪 Automated tests
- 📦 Dependency management with \`uv\`

---

## 📋 Requirements

- Python 3.12+
- \`uv\`
- Git


---

## 📦 Installation

Clone the repository:

\`\`\`bash
git clone https://github.com/tf4482/${APP_NAME}.git
cd ${APP_NAME}
\`\`\`
EOF

cat >.gitignore <<'EOF'
*.code-workspace
*.cover
*.egg-info/
*.lnk
*.log
*.manifest
*.nyc_output
*.py,cover
*.py[oc]
*.pyd
*.sqlite
*.sqlite3
*.swp
*.tmp

.DS_Store
.Python
Thumbs.db
desktop.ini

.cache/
.eggs/
.hypothesis/
.idea/
.ipynb_checkpoints/
.mypy_cache/
.next/
.npm/
.parcel-cache/
.pip-wheel-metadata/
.pnpm-store/
.pyre/
.pytest_cache/
.pytype/
.ruff_cache/
.venv/
.yarn-cache/
__pycache__/

bower_components/
build/
coverage/
develop-eggs/
dist/
downloads/
eggs/
env/
ENV/
ipynb_checkpoints/
jspm_packages/
lib/
lib64/
logs/
node_modules/
out/
parts/
sdist/
share/python-wheels/
temp/
test_downloads/
tmp/
typings/
var/
vendor/
venv/
wheels/

.env
.env.*
!.env.example

config.json
config.json.backup

files/*
!files/*example*

inventory/
inventory.backup/

public/build/
public/hot/
public/storage/

storage/*.key

channel_log.txt
coverage.xml
env.ini
Homestead.json
Homestead.yaml
lerna-debug.log*
npm-debug.log*
pip-delete-this-directory.txt
pip-log.txt
yarn-debug.log*
yarn-error.log*

.box_pc
.dypy.json
.fleet
.history
.lck
.led_pc
.notes*
.old
.phpunit.cache
.phpunit.result.cache
.python-type/

bootstrap.bash
bootstrap-python.bash
bootstrap.sh
local_install.bash
push.bat
sync-imports.py
deploy.bash
python-project-reviser.bash
EOF

cat >.editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml}]
indent_size = 2

[docker-compose.yml]
indent_size = 2
EOF

cat >$APP_NAME.code-workspace <<EOF
{
	"folders": [
		{
			"path": "."
		}
	]
}
EOF

cat >.notes <<EOF

Gitstuff:

git add .gitignore
git commit -m "chore: 🙈 Updated .gitignore"

git add README.md
git commit -m "📝 Updated README"

Misc:

uv run ruff check --fix .
uv run ruff format .
uv run ruff check .
uv run pyright
uv run pytest

EOF

cat >LICENSE <<'EOF'
MIT License

Copyright (c) 2026 tf4482

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

cat >config.example..yml <<'EOF'
config:
EOF

cat >deploy.bash <<'EOF'
#!/usr/bin/env bash

get_app_name() {
    python3 -c 'import tomllib; print(tomllib.load(open("pyproject.toml", "rb"))["project"]["name"])'
}

APP_NAME="$(get_app_name)"

uv sync --locked
uv run pyinstaller --onefile --name "${APP_NAME}" main.py

install -v -m 755 "./dist/${APP_NAME}" "/usr/local/bin/${APP_NAME}"
EOF

cat >sync-imports.py <<'EOF'
#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import importlib.util
import subprocess
import sys
from pathlib import Path

# Import name -> PyPI package name
PACKAGE_MAP = {
    "PIL": "Pillow",
    "bs4": "beautifulsoup4",
    "cv2": "opencv-python",
    "dateutil": "python-dateutil",
    "dotenv": "python-dotenv",
    "git": "GitPython",
    "jwt": "PyJWT",
    "magic": "python-magic",
    "sklearn": "scikit-learn",
    "yaml": "PyYAML",
}


EXCLUDED_DIRECTORIES = {
    ".git",
    ".github",
    ".idea",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    ".tox",
    ".venv",
    ".vscode",
    "__pycache__",
    "build",
    "dist",
    "htmlcov",
    "node_modules",
}


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan a Python project for missing imports.",
    )

    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Project directory to scan (default: current directory).",
    )

    parser.add_argument(
        "--install",
        action="store_true",
        help="Install missing packages using 'uv add'.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the uv commands that would be executed.",
    )

    return parser.parse_args()


def is_excluded(path: Path) -> bool:
    return any(part in EXCLUDED_DIRECTORIES for part in path.parts)


def find_python_files(project_root: Path) -> list[Path]:
    return [
        path
        for path in project_root.rglob("*.py")
        if not is_excluded(path.relative_to(project_root))
    ]


def collect_imports(files: list[Path]) -> set[str]:
    imports: set[str] = set()

    for file in files:
        try:
            source = file.read_text(encoding="utf-8")
            tree = ast.parse(source, filename=str(file))

        except (UnicodeDecodeError, SyntaxError) as error:
            print(f"⚠️  Skipping {file}: {error}")
            continue

        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name.split(".", 1)[0])

            elif isinstance(node, ast.ImportFrom):
                if node.level > 0:
                    # Relative import, e.g.:
                    # from .foo import bar
                    continue

                if node.module:
                    imports.add(node.module.split(".", 1)[0])

    return imports


def collect_local_modules(project_root: Path) -> set[str]:
    modules: set[str] = set()

    for path in project_root.rglob("*"):
        try:
            relative = path.relative_to(project_root)
        except ValueError:
            continue

        if is_excluded(relative):
            continue

        if path.is_file() and path.suffix == ".py":
            if path.name == "__init__.py":
                # Package directory itself
                modules.add(path.parent.name)
            else:
                # Individual local module
                modules.add(path.stem)

        elif path.is_dir() and (path / "__init__.py").exists():
            modules.add(path.name)

    return modules


def module_is_available(module: str) -> bool:
    try:
        return importlib.util.find_spec(module) is not None
    except (ImportError, ModuleNotFoundError, AttributeError, ValueError):
        return False


def find_missing_imports(
    imports: set[str],
    local_modules: set[str],
) -> list[str]:
    missing: list[str] = []

    for module in sorted(imports):
        if module in sys.stdlib_module_names:
            continue

        if module in local_modules:
            continue

        if module_is_available(module):
            continue

        missing.append(module)

    return missing


def get_package_name(module: str) -> str:
    return PACKAGE_MAP.get(module, module)


def install_package(package: str, dry_run: bool = False) -> bool:
    command = ["uv", "add", package]

    print(f"📦 {' '.join(command)}")

    if dry_run:
        return True

    result = subprocess.run(command, check=False)

    return result.returncode == 0


def main() -> int:
    args = parse_arguments()

    project_root = Path(args.path).resolve()

    if not project_root.is_dir():
        print(f"❌ Project directory does not exist: {project_root}")
        return 1

    print(f"🔍 Scanning: {project_root}")

    files = find_python_files(project_root)

    print(f"🐍 Python files: {len(files)}")

    imports = collect_imports(files)
    local_modules = collect_local_modules(project_root)

    missing = find_missing_imports(
        imports=imports,
        local_modules=local_modules,
    )

    if not missing:
        print("✅ No missing imports found.")
        return 0

    print()
    print(f"⚠️  Missing imports: {len(missing)}")
    print()

    for module in missing:
        package = get_package_name(module)

        if module == package:
            print(f"  • {module}")
        else:
            print(f"  • {module} -> {package}")

    if not args.install:
        print()
        print("ℹ️  Nothing was installed.")
        print("   Run again with --install to install missing packages.")
        return 0

    print()
    print("📦 Installing missing packages...")
    print()

    failed: list[str] = []

    for module in missing:
        package = get_package_name(module)

        if not install_package(package, dry_run=args.dry_run):
            failed.append(package)

    print()

    if failed:
        print("❌ Some packages could not be installed:")

        for package in failed:
            print(f"  • {package}")

        return 1

    if args.dry_run:
        print("✅ Dry run completed.")
    else:
        print("✅ Missing packages installed.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------

chmod +x deploy.bash sync-imports.py

success "Helper scripts created:"
printf '  • deploy.bash\n'
printf '  • sync-imports.py\n'

# ---------------------------------------------------------------------------
# utils_python submodule
# ---------------------------------------------------------------------------

info "Checking utils_python submodule..."

SUBMODULE_PATH="utils_python"

normalize_git_url() {
    local url="$1"

    # Treat URLs with and without trailing ".git" as equivalent.
    url="${url%.git}"

    printf '%s\n' "$url"
}

existing_submodule_url="$(
    git config \
        -f .gitmodules \
        --get "submodule.${SUBMODULE_PATH}.url" \
        2>/dev/null ||
        true
)"

normalized_expected_url="$(normalize_git_url "$SUBMODULE_URL")"
normalized_existing_url="$(normalize_git_url "$existing_submodule_url")"

# ---------------------------------------------------------------------------
# Remove existing matching submodule
# ---------------------------------------------------------------------------

if [[ -n "$existing_submodule_url" &&
    "$normalized_existing_url" == "$normalized_expected_url" ]]; then

    info "Existing utils_python submodule detected."
    info "Removing existing submodule before fresh integration..."

    # Deinitialize the submodule.
    git submodule deinit -f -- "$SUBMODULE_PATH" 2>/dev/null || true

    # Remove it from the Git index and working tree.
    git rm -f -- "$SUBMODULE_PATH" 2>/dev/null || true

    # Remove remaining submodule metadata.
    rm -rf -- ".git/modules/$SUBMODULE_PATH"

    # In case the working directory still exists.
    rm -rf -- "$SUBMODULE_PATH"

    success "Existing utils_python submodule removed."

elif [[ -n "$existing_submodule_url" ]]; then

    warning "utils_python is configured as a different submodule:"
    printf '  Current:  %s\n' "$existing_submodule_url"
    printf '  Expected: %s\n' "$SUBMODULE_URL"

    warning "Leaving the different submodule unchanged."

    SKIP_SUBMODULE_ADD=true

elif [[ -e "$SUBMODULE_PATH" ]]; then

    warning "'$SUBMODULE_PATH' already exists but is not the expected Git submodule."
    warning "Leaving the existing directory unchanged."

    SKIP_SUBMODULE_ADD=true
fi

# ---------------------------------------------------------------------------
# Add fresh submodule
# ---------------------------------------------------------------------------

if [[ "${SKIP_SUBMODULE_ADD:-false}" != true ]]; then

    info "Adding fresh utils_python submodule..."
    info "$SUBMODULE_URL"

    git submodule add \
        "$SUBMODULE_URL" \
        "$SUBMODULE_PATH"

    git submodule update \
        --init \
        --recursive \
        "$SUBMODULE_PATH"

    success "utils_python submodule integrated."

fi

# ---------------------------------------------------------------------------
# Pre-commit
# ---------------------------------------------------------------------------

info "Installing pre-commit hook..."

uv run pre-commit install ||
    warning "Pre-commit hook installation failed. Continuing..."

# ---------------------------------------------------------------------------
# Git check
# ---------------------------------------------------------------------------

info "Checking Git diff..."

git diff --check ||
    warning "Git diff check found issues. Continuing..."

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

printf '\n'
success "Project setup completed."
printf '\n'

printf 'Project:       %s\n' "$APP_NAME"
printf 'Directory:     %s\n' "$PROJECT_DIR"
printf 'Python:        3.12\n'
printf 'Environment:   .venv\n'
printf 'Package tool:  uv\n'
printf 'Submodule:     utils_python\n'

printf '\n'

if [[ -d .venv ]]; then
    shell_name="$(basename "${SHELL:-}")"

    case "$shell_name" in
    bash | zsh)
        printf 'Activate environment with:\n\n'
        printf '  source .venv/bin/activate\n'
        ;;
    fish)
        printf 'Activate environment with:\n\n'
        printf '  source .venv/bin/activate.fish\n'
        ;;
    *)
        printf 'Virtual environment is located at:\n\n'
        printf '  .venv/\n'
        ;;
    esac
fi

printf '\n'

# ---------------------------------------------------------------------------
# Detect and install missing imports
# ---------------------------------------------------------------------------

info "Scanning project for missing Python dependencies..."

uv run python ./sync-imports.py --install ||
    warning "Import synchronization failed. Continuing..."

printf '\n'
success "All setup steps completed."
printf '\n'

finish_project_revision
