import json
import sys
import time
from pathlib import Path

NOW = 1_800_000_000
DAY = 86400
INDEX = "application/vnd.oci.image.index.v1+json"
MANIFEST = "application/vnd.oci.image.manifest.v1+json"

out = Path(sys.argv[1])
packages = {
  "ws-server": [],
  "ws-server%2Fcache": [],
  "ws-server%2Ftestbench": [],
  "workspace": [],
}
manifests = {}
next_id = [1000]


def digest(n):
  return f"sha256:{n:064x}"


def version(package, n, tags, age):
  next_id[0] += 1
  stamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(NOW - age * DAY))
  packages[package].append(
    {
      "id": next_id[0],
      "name": digest(n),
      "created_at": stamp,
      "updated_at": stamp,
      "metadata": {"container": {"tags": tags}},
    }
  )


def index(n, children):
  manifests[digest(n)] = {
    "mediaType": INDEX,
    "manifests": [{"digest": digest(c), "mediaType": MANIFEST} for c in children],
  }


version("ws-server", 1, ["latest"], 1)
index(1, [2, 3, 4])
version("ws-server", 2, ["build-aaa"], 40)
version("ws-server", 3, ["build-aaa-arm64"], 40)
version("ws-server", 4, [], 40)
version("ws-server", 5, ["pr-1"], 2)
version("ws-server", 6, ["pr-2"], 2)
version("ws-server", 7, ["pr-3", "build-bbb"], 3)
version("ws-server", 8, ["build-old"], 40)
version("ws-server", 9, ["build-young"], 29)
version("ws-server", 10, [], 3)
version("ws-server", 11, [], 10)
version("ws-server", 12, ["pr-4"], 20)
index(12, [13, 14])
version("ws-server", 13, [], 20)
version("ws-server", 14, [], 20)
version("ws-server", 50, ["pr-3"], 1)

version("workspace", 50, ["dev", "build-ccc"], 60)
version("workspace", 60, ["v0.5.2", "v0.5"], 30)
index(60, [61, 62, 63])
for n in (61, 62, 63):
  version("workspace", n, [], 30)
version("workspace", 70, ["pr-800"], 15)
version("workspace", 71, ["pr-801"], 15)
for i in range(150):
  version("workspace", 1000 + i, [], 8 if i % 2 == 0 else 3)

version("ws-server%2Fcache", 90, ["latest"], 2)
index(90, [])
version("ws-server%2Fcache", 91, ["arm64"], 2)
version("ws-server%2Fcache", 92, [], 30)
version("ws-server%2Ftestbench", 95, ["dev"], 1)
version("ws-server%2Ftestbench", 96, ["pr-2"], 1)

(out / "man").mkdir(parents=True, exist_ok=True)
(out / "pr").mkdir(parents=True, exist_ok=True)

for package, versions in packages.items():
  pages = [versions[i : i + 100] for i in range(0, len(versions), 100)] or [[]]
  (out / f"{package}.json").write_text(json.dumps(pages))

for d, m in manifests.items():
  (out / "man" / d).write_text(json.dumps(m))

for repo, number, state in [
  ("ws-server", 1, "OPEN"),
  ("ws-server", 2, "CLOSED"),
  ("ws-server", 3, "MERGED"),
  ("ws-server", 4, "CLOSED"),
  ("workspace", 800, "MERGED"),
  ("workspace", 801, "OPEN"),
]:
  (out / "pr" / f"{repo}-{number}").write_text(state)
