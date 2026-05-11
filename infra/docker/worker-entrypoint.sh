#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python}"
if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  else
    echo "[entrypoint] python executable not found" >&2
    exit 1
  fi
fi

export FORCE_CUDA="${FORCE_CUDA:-1}"
export MAX_JOBS="${MAX_JOBS:-$(nproc)}"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"

detect_and_export_torch_lib_path() {
  local torch_lib_dir
  if torch_lib_dir="$(${PYTHON_BIN} - <<'PY'
import os

try:
    import torch
except Exception:
    raise SystemExit(1)

print(os.path.join(os.path.dirname(torch.__file__), "lib"))
PY
)"; then
    export LD_LIBRARY_PATH="${torch_lib_dir}:${LD_LIBRARY_PATH:-}"
  fi
}

require_python_module() {
  local import_name="$1"
  local hint_message="$2"
  if ${PYTHON_BIN} -c "import ${import_name}" >/dev/null 2>&1; then
    return
  fi
  echo "[entrypoint] missing python module '${import_name}'. ${hint_message}" >&2
  exit 1
}

detect_and_export_torch_lib_path
require_python_module "torch" "Run the image dependency installation during build."
require_python_module "diff_surfel_rasterization" "Ensure diff-surfel-rasterization was installed during build."
require_python_module "simple_knn" "Ensure simple-knn was installed during build."
require_python_module "imageio" "Ensure imageio was installed during build."
require_python_module "scipy" "Ensure scipy was installed during build."
require_python_module "plyfile" "Ensure plyfile was installed during build."
require_python_module "cv2" "Ensure opencv-python-headless was installed during build."
require_python_module "lpips" "Ensure lpips was installed during build."
require_python_module "matplotlib" "Ensure matplotlib was installed during build."
require_python_module "open3d" "Ensure open3d was installed during build."
require_python_module "mediapy" "Ensure mediapy was installed during build."
require_python_module "trimesh" "Ensure trimesh was installed during build."

detect_and_export_torch_lib_path

exec ${PYTHON_BIN} /workspace/repo/apps/worker/main.py
