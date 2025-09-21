#!/usr/bin/env bash
set -euo pipefail

# ===============================
# Config
# ===============================
PREFIX="/opt/mamba"            # micromamba root
ENV_NAME="qgis310"
PY_VER="3.10"
QGIS_VER="3.28"                # pairs well with Python 3.10 in Colab
HEADLESS_QT="1"                # keep 1 for Colab/headless
DISABLE_PDAL_PLUGINS="1"       # silences the Draco warnings
# Set to 0 and uncomment the install line below if you want Draco I/O.

# ===============================
# Bootstrap micromamba
# ===============================
export MAMBA_ROOT_PREFIX="$PREFIX"
mkdir -p "$PREFIX/bin"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Download just the micromamba binary
wget -qO "$tmpdir/micromamba.tar.bz2" \
  "https://micromamba.snakepit.net/api/micromamba/linux-64/latest"
tar -xjf "$tmpdir/micromamba.tar.bz2" -C "$PREFIX" bin/micromamba
chmod +x "$PREFIX/bin/micromamba"

# Add to PATH now
export PATH="$PREFIX/bin:$PATH"
hash -r

# Enable shell hook (lets us "activate")
eval "$("$PREFIX/bin/micromamba" shell hook -s bash)"

# Sanity check
micromamba --version

# ===============================
# Create environment if missing
# ===============================
if ! micromamba env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  micromamba create -y -n "$ENV_NAME" -c conda-forge \
    "python=$PY_VER" "qgis=$QGIS_VER"
fi

# Activate env for this script
set +u
micromamba activate "$ENV_NAME"
set -u

# ===============================
# Headless Qt (Colab-safe)
# ===============================
if [[ "${HEADLESS_QT}" == "1" ]]; then
  export QT_QPA_PLATFORM="offscreen"
  export XDG_RUNTIME_DIR="/tmp/runtime-qgis"
  install -d -m 700 "$XDG_RUNTIME_DIR"
fi

# ===============================
# PDAL plugins: silence Draco noise
# ===============================
if [[ "${DISABLE_PDAL_PLUGINS}" == "1" ]]; then
  # Tell PDAL to NOT scan plugins (avoids libdraco.so.* warnings)
  export PDAL_DRIVER_PATH="/nonexistent"
  export PDAL_DISABLE_PLUGIN_LOADING="1"
else
  # If you actually need Draco (LASzip/Draco I/O), try enabling this instead:
  # micromamba install -y -n "$ENV_NAME" -c conda-forge "draco=1.5.3" || true
  :
fi

# ===============================
# Smoke tests
# ===============================
qgis_process --version

python - <<'PY'
import os, sys
PREFIX = sys.prefix
os.environ.update({
  "QT_QPA_PLATFORM": os.environ.get("QT_QPA_PLATFORM",""),
  "QGIS_PREFIX_PATH": PREFIX,
  "QGIS_PLUGINPATH": os.path.join(PREFIX,"lib","qgis","plugins"),
  "PROJ_LIB": os.path.join(PREFIX,"share","proj"),
  "GDAL_DATA": os.path.join(PREFIX,"share","gdal"),
  "XDG_RUNTIME_DIR": os.environ.get("XDG_RUNTIME_DIR","/tmp"),
})
from qgis.core import QgsApplication
app = QgsApplication([], False); app.initQgis()
print("QGIS Python OK")
app.exitQgis()
PY

echo
echo "✅ QGIS environment '${ENV_NAME}' is ready."
echo "   Micromamba root: ${MAMBA_ROOT_PREFIX}"
if [[ "${HEADLESS_QT}" == "1" ]]; then
  echo "   Qt offscreen mode set, runtime dir: ${XDG_RUNTIME_DIR}"
fi
if [[ "${DISABLE_PDAL_PLUGINS}" == "1" ]]; then
  echo "   PDAL plugin scanning disabled (no Draco warnings)."
fi
