import urllib.request
import re
import os

os.makedirs("assets/free_resources", exist_ok=True)

pages = [
    ("oriental_roof_tiles", "https://opengameart.org/content/oriental-roof-tiles"),
    ("japanese_buildings", "https://opengameart.org/content/japanese-buildings-isometric-strategy-game-mockup"),
    ("pastoral_overworld", "https://opengameart.org/content/pastoral-overworld"),
    ("outdoor_32x32", "https://opengameart.org/content/2d-outdoor-32x32-tileset"),
    ("home_objects", "https://opengameart.org/content/home-objects")
]

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

for name, url in pages:
    print(f"Fetching {name} from {url}...")
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            links = re.findall(r'href=["\'](https?://[^"\']+\.(?:png|gif|zip|jpg))["\']', html)
            if not links:
                links = re.findall(r'href=["\'](/sites/default/files/[^"\']+)["\']', html)
                links = ["https://opengameart.org" + l for l in links]
            print(f"  Found {len(links)} links: {links[:3]}")
            for l in links[:2]:
                fname = os.path.basename(l.split('?')[0])
                dest = os.path.join("assets/free_resources", f"{name}_{fname}")
                print(f"  Downloading {l} -> {dest}")
                req_file = urllib.request.Request(l, headers=headers)
                with urllib.request.urlopen(req_file, timeout=15) as f_in, open(dest, 'wb') as f_out:
                    f_out.write(f_in.read())
                print(f"  Saved {dest} ({os.path.getsize(dest)} bytes)")
    except Exception as e:
        print(f"  Failed: {e}")
