# -*- coding: utf-8 -*-
"""轮询 NotaryTrack 今天新传的 build（版本号>72）的 ASC 处理状态。
第一版误报根因：按 -uploadedDate 取最新会拿到昨天 build 72（VALID 假阳性）——
今天的新包 altool 传完后要几分钟才在 ASC 注册出记录。修法：认版本号>72 才算今天的包。
"""
import time, json, base64, sys, urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEY_ID = "L3UHT69Y77"
ISSUER_ID = "98812827-46d0-4c8f-9b91-35d4f783e6df"
P8_PATH = r"E:\AI-Projects\个人成长\50-Skills\密钥\苹果\AuthKey_L3UHT69Y77.p8"
APP_ID = "6832398956"   # NotaryTrack
MIN_BUILD = 74          # 只认比这新的包（二轮包应该是 75：push run 75 出包，dispatch run 76 传 TF）

from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes

key = load_pem_private_key(open(P8_PATH, "rb").read(), password=None)
def b64(d): return base64.urlsafe_b64encode(d).rstrip(b"=").decode()
h = b64(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
p = b64(json.dumps({"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}).encode())
sig = key.sign(f"{h}.{p}".encode(), ec.ECDSA(hashes.SHA256()))
def raw(s):
    i = 2
    if s[1] & 0x80: i += s[1] & 0x7f
    def ri():
        nonlocal i
        i += 1; ln = s[i]; i += 1
        if ln & 0x80:
            n = ln & 0x7f; ln = 0
            for _ in range(n): ln = (ln << 8) | s[i]; i += 1
        v = int.from_bytes(s[i:i+ln], "big"); i += ln; return v.to_bytes(32, "big")
    return ri() + ri()
jwt = f"{h}.{p}.{b64(raw(sig))}"

def asc(url):
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + jwt})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return json.loads(e.read() or b"{}")

deadline = time.time() + 45 * 60
last = ""
while time.time() < deadline:
    r = asc(f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=5")
    rows = r.get("data", [])
    new_builds = [b for b in rows if b["attributes"]["version"].isdigit() and int(b["attributes"]["version"]) > MIN_BUILD]
    if not new_builds:
        print(f"[{time.strftime('%H:%M:%S')}] 新包（>{MIN_BUILD}）还没在 ASC 出现，继续等…", flush=True)
        time.sleep(60)
        continue
    b = new_builds[0]
    ver = int(b["attributes"]["version"])
    state = b["attributes"]["processingState"]
    uploaded = b["attributes"].get("uploadedDate", "?")
    line = f"build {ver} uploaded={uploaded} state={state}"
    if line != last:
        print(f"[{time.strftime('%H:%M:%S')}] {line}", flush=True)
        last = line
    if state == "VALID":
        print(f"RESULT=VALID build={ver}", flush=True)
        sys.exit(0)
    if state in ("FAILED", "INVALID"):
        print(f"RESULT={state} build={ver}", flush=True)
        sys.exit(2)
    time.sleep(60)
print("RESULT=TIMEOUT_45MIN", flush=True)
sys.exit(3)
