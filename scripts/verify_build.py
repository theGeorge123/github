import argparse, collections, pathlib, xml.etree.ElementTree as ET
parser=argparse.ArgumentParser(description="Verify production Rojo script sources against the source tree.")
parser.add_argument("place",type=pathlib.Path);args=parser.parse_args();root=pathlib.Path(__file__).resolve().parents[1]
required=[root/"src/ServerScriptService/Core/DebateProbeDefinitions.lua",root/"src/ServerScriptService/AI/DebateProbeAdapter.lua",root/"src/ServerScriptService/Services/DebateProbeService.lua"]
for path in required:
 if not path.is_file():raise SystemExit(f"FAIL: required source missing: {path.relative_to(root)}")
malformed=[path for path in (root/"src").rglob("*") if path.is_file() and "src" in path.relative_to(root/"src").parts]
if malformed:raise SystemExit("FAIL: malformed nested source paths: "+", ".join(str(p.relative_to(root)) for p in malformed))
expected=collections.Counter(path.read_text() for path in (root/"src").rglob("*.lua"));actual=collections.Counter();classes=collections.Counter()
for item in ET.parse(args.place).iter("Item"):
 class_name=item.attrib["class"]
 if class_name not in {"Script","LocalScript","ModuleScript"}:continue
 source=item.find("Properties/*[@name='Source']")
 if source is None:raise SystemExit(f"Missing Source for {class_name}")
 actual[source.text or ""]+=1;classes[class_name]+=1
if expected!=actual:raise SystemExit("FAIL: built scripts differ from src/ (missing, duplicate, or unexpected source)")
if classes["Script"]!=1 or classes["LocalScript"]!=1:raise SystemExit(f"FAIL: unexpected runnable entrypoints: {classes}")
print(f"PASS: {sum(actual.values())} exact script sources; one server and one client entrypoint")
