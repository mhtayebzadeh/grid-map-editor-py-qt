"""
Cross-platform file path helpers.

QML hands files around as URLs ("file:///C:/Users/..."); stripping "file://" by hand
breaks on Windows ("/C:/...") and for names with spaces or non-ASCII characters
("%20", "%D8%..."). OpenCV's imread/imwrite cannot open non-ASCII paths on Windows.
"""

import sys
from pathlib import Path

import cv2
import numpy as np
from PySide6.QtCore import QObject, QUrl, Slot


def uri_to_path(uri: str) -> str:
    """Convert a QML file URL (or an already local path) to a local filesystem path"""
    if not uri:
        return ""
    if uri.startswith("file:"):
        return QUrl(uri).toLocalFile()
    # Leftover from code that stripped "file://" from "file:///C:/..." on Windows
    if sys.platform == "win32" and len(uri) > 2 and uri[0] == "/" and uri[2] == ":":
        return uri[1:]
    return uri


def path_to_uri(path: str) -> str:
    """Convert a local filesystem path to a file URL usable as a QML image source"""
    if not path:
        return ""
    if path.startswith("file:"):
        return path
    return QUrl.fromLocalFile(str(Path(path))).toString()


def imread(path, flags=cv2.IMREAD_COLOR):
    """cv2.imread that also works with non-ASCII paths on Windows"""
    try:
        data = np.fromfile(str(path), dtype=np.uint8)
    except OSError:
        return None
    return cv2.imdecode(data, flags)


def imwrite(path, image) -> bool:
    """cv2.imwrite that also works with non-ASCII paths on Windows"""
    ok, encoded = cv2.imencode(Path(path).suffix or ".png", image)
    if ok:
        encoded.tofile(str(path))
    return ok


class PathHelper(QObject):
    """Exposed to QML as 'pathHelper'"""

    @Slot("QVariant", result=str)
    def toLocalPath(self, url):
        return uri_to_path(url.toString() if isinstance(url, QUrl) else str(url))

    @Slot(str, result=str)
    def toUrl(self, path):
        return path_to_uri(path)
