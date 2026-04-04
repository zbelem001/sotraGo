import requests
import json
q = """
[out:json][timeout:25];
relation["route"="bus"]["operator"~"SOTRACO", i](12.3, -1.6, 12.4, -1.4);
out body geom;
"""
res = requests.post("https://overpass-api.de/api/interpreter", data={"data": q})
with open("test_out.json", "w") as f: json.dump(res.json(), f, indent=2)
print("done")
