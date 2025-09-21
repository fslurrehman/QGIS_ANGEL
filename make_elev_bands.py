# make_elev_bands.py
# Usage:
#   micromamba run -n qgis310 python make_elev_bands.py \
#       --in proj/data/dem_filled.tif \
#       --out proj/data/elev_bands.gpkg \
#       --interval 10

import os, argparse
from qgis_env import configure_qgis_env

def main():
    ap = argparse.ArgumentParser(description="Create elevation slice polygons from a DEM using GDAL Contour Polygons.")
    ap.add_argument("--prefix", default=None, help="QGIS prefix path (env root). If omitted, uses sys.prefix.")
    ap.add_argument("--in", dest="inp", default="proj/data/dem_filled.tif",
                    help="Input DEM path (default: proj/data/dem_filled.tif)")
    ap.add_argument("--out", dest="out", default="proj/data/elev_bands.gpkg",
                    help="Output vector path (default: proj/data/elev_bands.gpkg)")
    ap.add_argument("--interval", dest="interval", type=float, default=10.0,
                    help="Interval between contours in elevation units (default: 10)")
    ap.add_argument("--field", dest="field", default="elev",
                    help="Attribute field name (default: elev)")
    args = ap.parse_args()

    PREFIX = configure_qgis_env(args.prefix)

    from qgis.core import QgsApplication
    QgsApplication.setPrefixPath(PREFIX, True)
    QgsApplication.setPluginPath(os.path.join(PREFIX, "lib", "qgis", "plugins"))
    print("DEBUG: prefix:", QgsApplication.prefixPath(), "plugin:", QgsApplication.pluginPath())
    from processing.core.Processing import Processing
    import processing

    QgsApplication.setPrefixPath(PREFIX, True)
    app = QgsApplication([], False)
    app.initQgis()
    Processing.initialize()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)

    params = {
        "INPUT": args.inp,
        "BAND": 1,
        "INTERVAL": float(args.interval),
        "FIELD_NAME": args.field,
        "CREATE_3D": False,
        "NODATA": None,
        "IGNORE_NODATA": True,
        "OFFSET": 0.0,
        "EXTRA": "",
        "OUTPUT": args.out,
    }

    res = processing.run("gdal:contour_polygon", params)
    print("Wrote:", res["OUTPUT"])

    app.exitQgis()

if __name__ == "__main__":
    main()
