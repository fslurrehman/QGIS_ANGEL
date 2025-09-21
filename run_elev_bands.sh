#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${ENV_NAME:-qgis310}"
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-/opt/mamba}"
MAMBA_BIN="${MAMBA_BIN:-$MAMBA_ROOT_PREFIX/bin/micromamba}"

if [[ ! -x "$MAMBA_BIN" ]]; then
  MAMBA_BIN="$(command -v micromamba || true)"
fi
if [[ -z "${MAMBA_BIN:-}" || ! -x "$MAMBA_BIN" ]]; then
  echo "❌ micromamba not found. Set MAMBA_BIN or run setup.sh." >&2; exit 1
fi
export PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

if ! "$MAMBA_BIN" env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo "❌ Env '$ENV_NAME' not found under $MAMBA_ROOT_PREFIX"; exit 1
fi

INPUT="${1:-proj/data/dem_filled.tif}"
OUTPUT="${2:-proj/data/elev_bands.gpkg}"
INTERVAL="${3:-10}"
mkdir -p "$(dirname "$OUTPUT")"

ENV_ROOT="$("$MAMBA_BIN" run -n "$ENV_NAME" python -c 'import sys; print(sys.prefix)')"

echo "Using MAMBA_ROOT_PREFIX: $MAMBA_ROOT_PREFIX"
echo "Using micromamba:        $MAMBA_BIN"
echo "Using ENV_NAME:          $ENV_NAME"
echo "Resolved ENV_ROOT:       $ENV_ROOT"
echo "Input:                   $INPUT"
echo "Output:                  $OUTPUT"
echo "Interval:                $INTERVAL"

# --- Silence PDAL plugin scanning (kills Draco warnings) ---
export PDAL_DRIVER_PATH="/nonexistent"
export PDAL_DISABLE_PLUGIN_LOADING="1"


# --- hard-quiet PDAL Draco plugin warnings by removing the plugin .so's ---
for so in "$ENV_ROOT/lib/libpdal_plugin_reader_draco.so" \
          "$ENV_ROOT/lib/libpdal_plugin_writer_draco.so"; do
  [[ -f "$so" ]] && rm -f "$so"
done

# --- run with env overrides as an extra belt-and-suspenders ---
env PDAL_DISABLE_PLUGIN_LOADING=TRUE PDAL_DRIVER_PATH=/nonexistent \
"$MAMBA_BIN" run -n "$ENV_NAME" python make_elev_bands.py \
  --in "$INPUT" \
  --out "$OUTPUT" \
  --interval "$INTERVAL" \
  --prefix "$ENV_ROOT"

echo "✅ Wrote: $OUTPUT"
