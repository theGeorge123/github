import pathlib,sys,xml.etree.ElementTree as ET
p=pathlib.Path(sys.argv[1]);items=list(ET.parse(p).iter('Item'));scripts=[]
for item in items:
 if item.attrib['class'] in {'Script','LocalScript','ModuleScript'}:
  prop=item.find("Properties/string[@name='Name']");scripts.append((item.attrib['class'],prop.text if prop is not None else ''))
runnable=[x for x in scripts if x[0] in {'Script','LocalScript'}]
if runnable!=[('Script','DebateLiveProbe')]:raise SystemExit(f'FAIL: probe runnable entrypoints {runnable}')
for forbidden in ['Bootstrap','DataService','MatchService','ProfileStore','RewardService','WorldService']:
 if any(name==forbidden for _,name in scripts):raise SystemExit(f'FAIL: forbidden probe module {forbidden}')
print(f'PASS: isolated probe with {len(scripts)} scripts and one server entrypoint')
