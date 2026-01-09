#!/bin/bash

# --- Inputs from Docker CMD ---
REPO_NAME=$1
REPO_BRANCH=${2:-"master"}
SKIP_LFS=${3:-0}

# Validate Mandatory Input
if [ -z "$REPO_NAME" ]; then
    echo "ERROR: Repository name is required as the first argument."
    exit 1
fi

echo "--- Environment Sanity Check ---"
python3 -c "import torch; print(f'PyTorch: {torch.__version__} | CUDA: {torch.version.cuda} | GPU: {torch.cuda.is_available()}')"

# --- Repo Logic ---
REPO_DIR="/work/$REPO_NAME"
REPO_URL="https://github.com/aravindadithya/$REPO_NAME"

git config --global --add safe.directory "$REPO_DIR"

if [ -d "$REPO_DIR" ]; then
    echo "Updating $REPO_NAME ($REPO_BRANCH)..."
    cd "$REPO_DIR" || exit 1
    GIT_LFS_SKIP_SMUDGE=$SKIP_LFS git pull origin "$REPO_BRANCH"
else
    echo "Cloning $REPO_NAME ($REPO_BRANCH)..."
    cd /work || exit 1
    GIT_LFS_SKIP_SMUDGE=$SKIP_LFS git clone --branch "$REPO_BRANCH" "$REPO_URL"
fi

cd /work

# --- Start Visdom ---
python3 -m visdom.server -port 8097 > /dev/null 2>&1 &
echo "Visdom started on port 8097"

# --- Start Jupyter Lab ---
echo "Starting Jupyter Lab on port 8888..."
# Explicitly setting the shell helps the terminal show up
export SHELL=/bin/bash
exec python3 -m jupyterlab --port=8888 --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.terminado_settings={'shell_command': ['/bin/bash']}