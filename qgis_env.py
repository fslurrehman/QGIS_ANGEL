# qgis_env.py
import os, sys

def configure_qgis_env(prefix: str = None):
    PREFIX = prefix or sys.prefix

    os.environ["QT_QPA_PLATFORM"] = "offscreen"
    os.environ["QGIS_PREFIX_PATH"] = PREFIX
    os.environ["QGIS_PLUGINPATH"] = os.path.join(PREFIX, "lib", "qgis", "plugins")
    os.environ["PROJ_LIB"] = os.path.join(PREFIX, "share", "proj")
    os.environ["PROJ_DATA"] = os.path.join(PREFIX, "share", "proj")
    os.environ["GDAL_DATA"] = os.path.join(PREFIX, "share", "gdal")
    os.environ["XDG_RUNTIME_DIR"] = "/tmp/runtime-qgis"
    os.makedirs("/tmp/runtime-qgis", exist_ok=True)

    sys.path += [
        os.path.join(PREFIX, "share", "qgis", "python"),
        os.path.join(PREFIX, "share", "qgis", "python", "plugins"),
    ]
    return PREFIX
