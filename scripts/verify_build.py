import argparse, collections, pathlib, xml.etree.ElementTree as ET
parser=argparse.ArgumentParser(description="Verify production Rojo script sources against the source tree.")
parser.add_argument("place",type=pathlib.Path);args=parser.parse_args();root=pathlib.Path(__file__).resolve().parents[1]
required=[root/"src/ServerScriptService/Core/DebateProbeDefinitions.lua",root/"src/ServerScriptService/AI/DebateProbeAdapter.lua",root/"src/ServerScriptService/Services/DebateProbeService.lua",root/"src/ServerScriptService/Core/AIDiagnostics.lua"]
for path in required:
 if not path.is_file():raise SystemExit(f"FAIL: required source missing: {path.relative_to(root)}")
malformed=[path for path in (root/"src").rglob("*") if path.is_file() and "src" in path.relative_to(root/"src").parts]
if malformed:raise SystemExit("FAIL: malformed nested source paths: "+", ".join(str(p.relative_to(root)) for p in malformed))
config=(root/"src/ReplicatedStorage/Shared/Config.lua").read_text();client=(root/"src/StarterPlayer/StarterPlayerScripts/Client.client.lua").read_text();bootstrap=(root/"src/ServerScriptService/Bootstrap.server.lua").read_text();world=(root/"src/ServerScriptService/Services/DebateWorldService.lua").read_text()
if "DebateLiveEnabled = false" not in config or "DebateProbe = {Enabled=false" not in config:raise SystemExit("FAIL: live debate/probe launch gates changed")
if "SCRIPTED PRACTICE — NO WINNER OR SCORE • NOT A REAL OPPONENT" not in client:raise SystemExit("FAIL: permanent scripted-practice label changed")
if "DebateProbeService" in bootstrap or "RobloxTextGeneratorProbeExecutor" in bootstrap:raise SystemExit("FAIL: live probe is wired into production bootstrap")
if 'ServerStorage:FindFirstChild("TempleAssets")' not in world or 'ReplicatedStorage"):FindFirstChild("TempleAssets")' in world:raise SystemExit("FAIL: decorative templates must remain server-only")
for bad_id in ("1843529607","1843529634","911342077","911342977"):
 if bad_id in world:raise SystemExit(f"FAIL: known invalid audio asset remains configured: {bad_id}")
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
