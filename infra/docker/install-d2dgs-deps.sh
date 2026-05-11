#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python}"
D2DGS_ROOT="${D2DGS_ROOT:-/workspace/repo/services/2d-gaussian-splatting}"
WHEELHOUSE="${WHEELHOUSE:-/workspace/repo/infra/docker/wheels}"
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-8.0;8.6;8.9}"

TORCH_WHEEL="torch-2.1.0+cu121-cp310-cp310-linux_x86_64.whl"
TORCHVISION_WHEEL="torchvision-0.16.0+cu121-cp310-cp310-linux_x86_64.whl"
TORCHAUDIO_WHEEL="torchaudio-2.1.0+cu121-cp310-cp310-linux_x86_64.whl"

IMAGEIO_WHEEL="imageio-2.35.1-py3-none-any.whl"
SCIPY_WHEEL="scipy-1.10.1-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
PLYFILE_WHEEL="plyfile-1.0.3-py3-none-any.whl"
OPENCV_WHEEL="opencv_python_headless-4.10.0.84-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
SKIMAGE_WHEEL="scikit_image-0.21.0-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
LPIPS_WHEEL="lpips-0.1.4-py3-none-any.whl"
MATPLOTLIB_WHEEL="matplotlib-3.7.5-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
OPEN3D_WHEEL="open3d-0.18.0-cp310-cp310-manylinux_2_27_x86_64.whl"

require_file() {
  local file_path="$1"
  if [ ! -f "${file_path}" ]; then
    echo "[build] missing file: ${file_path}" >&2
    exit 1
  fi
}

require_dir() {
  local dir_path="$1"
  if [ ! -d "${dir_path}" ]; then
    echo "[build] missing directory: ${dir_path}" >&2
    exit 1
  fi
}

require_dir "${D2DGS_ROOT}"
require_dir "${WHEELHOUSE}"

require_file "${WHEELHOUSE}/${TORCH_WHEEL}"
require_file "${WHEELHOUSE}/${TORCHVISION_WHEEL}"
require_file "${WHEELHOUSE}/${TORCHAUDIO_WHEEL}"

require_file "${D2DGS_ROOT}/submodules/diff-surfel-rasterization/setup.py"
require_file "${D2DGS_ROOT}/submodules/simple-knn/setup.py"
require_file "${WHEELHOUSE}/${IMAGEIO_WHEEL}"
require_file "${WHEELHOUSE}/${SCIPY_WHEEL}"
require_file "${WHEELHOUSE}/${PLYFILE_WHEEL}"
require_file "${WHEELHOUSE}/${OPENCV_WHEEL}"
require_file "${WHEELHOUSE}/${SKIMAGE_WHEEL}"
require_file "${WHEELHOUSE}/${LPIPS_WHEEL}"
require_file "${WHEELHOUSE}/${MATPLOTLIB_WHEEL}"
require_file "${WHEELHOUSE}/${OPEN3D_WHEEL}"

echo "[build] installing torch local wheels"
${PYTHON_BIN} -m pip install --no-deps \
  "${WHEELHOUSE}/${TORCH_WHEEL}" \
  "${WHEELHOUSE}/${TORCHVISION_WHEEL}" \
  "${WHEELHOUSE}/${TORCHAUDIO_WHEEL}"

${PYTHON_BIN} -m pip install "numpy<2"

export FORCE_CUDA="${FORCE_CUDA:-1}"
export MAX_JOBS="${MAX_JOBS:-$(nproc)}"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"

echo "[build] building CUDA extensions"
echo "[build] TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}"
${PYTHON_BIN} -m pip install --no-build-isolation "${D2DGS_ROOT}/submodules/diff-surfel-rasterization"
${PYTHON_BIN} -m pip install --no-build-isolation "${D2DGS_ROOT}/submodules/simple-knn"

echo "[build] installing local wheelhouse packages"
${PYTHON_BIN} -m pip install --no-deps \
  "${WHEELHOUSE}/${IMAGEIO_WHEEL}" \
  "${WHEELHOUSE}/${PLYFILE_WHEEL}" \
  "${WHEELHOUSE}/${LPIPS_WHEEL}"

${PYTHON_BIN} -m pip install \
  "${WHEELHOUSE}/${SCIPY_WHEEL}" \
  "${WHEELHOUSE}/${OPENCV_WHEEL}" \
  "${WHEELHOUSE}/${SKIMAGE_WHEEL}" \
  "${WHEELHOUSE}/${MATPLOTLIB_WHEEL}" \
  "${WHEELHOUSE}/${OPEN3D_WHEEL}"

echo "[build] installing 2d-gaussian-splatting runtime python deps"
${PYTHON_BIN} -m pip install \
  mediapy==1.2.2 \
  trimesh==4.4.9

${PYTHON_BIN} - <<'PY'
required = [
    "torch",
    "diff_surfel_rasterization",
    "simple_knn",
    "imageio",
    "scipy",
    "plyfile",
    "cv2",
    "lpips",
    "matplotlib",
    "open3d",
    "mediapy",
    "trimesh",
]

for mod in required:
    __import__(mod)
print("[build] dependency validation passed")
PY
