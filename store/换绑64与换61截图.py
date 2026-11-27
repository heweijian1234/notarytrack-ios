# -*- coding: utf-8 -*-
"""NotaryTrack 取消审核后的修复脚本（2026-11-27 健哥令"换"）
解锁后一键跑两件事：
1. 6.3 寸槽位（APP_IPHONE_61）5 张旧图（安卓三角状态栏）→ 删旧传新（mid/ 目录 1179x2556）
2. 审核线 build 57 → 换绑 build 64（含 v1.5 双语）
跑前提：submission 29543e63 已到 CANCELED/COMPLETE 终态（版本解锁）
"""
import time, json, base64, sys, hashlib, urllib.request, os

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEY_ID = "L3UHT69Y77"
ISSUER_ID = "98812827-46d0-4c8f-9b91-35d4f783e6df"
P8_PATH = r"E:\AI-Projects\个人成长\50-Skills\密钥\苹果\AuthKey_L3UHT69Y77.p8"
APP_ID = "6832398956"   # NotaryTrack
BUILD64_ID = "3f0c9395-05dd-4c22-95a2-a1eb397035b1"
MID_DIR = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\store\screenshots_v2\mid"
SHOT_NAMES = ["01-today", "02-new-signing", "03-signings-list", "04-monthly-income", "05-clients-overdue"]

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

def asc(url, data=None, method=None):
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body,
        headers={"Authorization": "Bearer " + jwt, "Content-Type": "application/json"},
        method=method or ("POST" if data else "GET"))
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")

# 0. 前置确认：submission 已终态、版本已解锁
st, r = asc("https://api.appstoreconnect.apple.com/v1/apps/%s/appStoreVersions?filter%%5Bplatform%%5D=IOS&limit=1" % APP_ID)
ver = r["data"][0]
ver_id = ver["id"]
state = ver["attributes"]["appStoreState"]
print(f"[0] 版本 {ver['attributes']['versionString']} state={state}")
if state not in ("REJECTED", "DEVELOPER_REJECTED", "DEVELOPER_REMOVED_FROM_SALE", "PREORDER_READY_FOR_APP_STORE", "READY_FOR_SALE"):
    # CANCELED 后一般回 DEVELOPER_REJECTED
    print("⚠️ 版本可能还没解锁（期待 DEVELOPER_REJECTED），继续尝试…")

# 1. 61 槽位换图
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
en_loc = None
for l in r.get("data", []):
    if l["attributes"]["locale"] == "en-US":
        en_loc = l["id"]
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{en_loc}/appScreenshotSets")
set61 = None
for s in r.get("data", []):
    if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_61":
        set61 = s["id"]
print(f"[1] 61槽位 {set61}")
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshotSets/{set61}/appScreenshots")
old = r.get("data", [])
for sh in old:
    st2, _ = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{sh['id']}", method="DELETE")
    print(f"  删 {sh['attributes']['fileName']}: {st2}")
    time.sleep(1)
for n in SHOT_NAMES:
    path = os.path.join(MID_DIR, n + ".png")
    data = open(path, "rb").read()
    md5 = base64.b64encode(hashlib.md5(data).digest()).decode()
    st, r = asc("https://api.appstoreconnect.apple.com/v1/appScreenshots", {"data": {
        "type": "appScreenshots", "attributes": {"fileName": "mid_" + n + ".png", "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set61}}}}})
    if st not in (200, 201):
        print(f"  mid_{n} reserve FAIL {st} " + json.dumps(r)[:150]); continue
    up = r["data"]["attributes"]["uploadOperations"][0]
    headers = {hh["name"]: hh["value"] for hh in up.get("requestHeaders", [])}
    req = urllib.request.Request(up["url"], data=data, headers=headers, method=up["method"])
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            ok = resp.status in (200, 201)
    except Exception:
        ok = False
    if ok:
        st2, r2 = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{r['data']['id']}",
            {"data": {"type": "appScreenshots", "id": r["data"]["id"],
                      "attributes": {"uploaded": True, "sourceFileChecksum": md5}}}, method="PATCH")
        print(f"  mid_{n}: {'OK' if st2 in (200, 201) else 'confirm FAIL ' + str(st2)}")
    else:
        print(f"  mid_{n}: 上传失败")
    time.sleep(2)

# 2. 换绑 build 64
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}",
    {"data": {"type": "appStoreVersions", "id": ver_id,
              "relationships": {"build": {"data": {"type": "builds", "id": BUILD64_ID}}}}}, method="PATCH")
print(f"[2] 换绑 build 64: {st}")
if st not in (200, 201):
    print(json.dumps(r, ensure_ascii=False)[:400])
else:
    st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/builds")
    for b in r.get("data", []):
        print(f"  回读绑定 build = {b['attributes'].get('version')}")

print("[3] 完成——下一步：重提审核（submission 重新 submit）")
