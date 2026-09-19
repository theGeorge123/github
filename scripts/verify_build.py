import argparse
import collections
import pathlib
import xml.etree.ElementTree as ET


parser = argparse.ArgumentParser(description="Verify production Rojo script sources against the source tree.")
parser.add_argument("place", type=pathlib.Path)
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
expected = collections.Counter(path.read_text() for path in (root / "src").rglob("*.lua"))
actual = collections.Counter()
classes = collections.Counter()
for item in ET.parse(args.place).iter("Item"):
    class_name = item.attrib["class"]
    if class_name not in {"Script", "LocalScript", "ModuleScript"}:
        continue
    source = item.find("Properties/*[@name='Source']")
    if source is None:
        raise SystemExit(f"Missing Source for {class_name}")
    actual[source.text or ""] += 1
    classes[class_name] += 1
if expected != actual:
    raise SystemExit("FAIL: built scripts differ from src/ (missing, duplicate, or unexpected source)")
if classes["Script"] != 1 or classes["LocalScript"] != 1:
    raise SystemExit(f"FAIL: unexpected runnable entrypoints: {classes}")
print(f"PASS: {sum(actual.values())} exact script sources; one server and one client entrypoint")
