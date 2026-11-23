# -*- coding: utf-8 -*-
"""NotaryTrack ASC 上架填料（照 countdown 母版；前置：build 47 VALID 已在 ASC）
七语满填：en/ja/de/fr/es + zh-Hans/zh-Hant（健哥规矩：新 App 简繁从 v1 带）
措辞纪律：track/log/record only，禁 diagnose/notarize/compliant journal（州法规雷区）
"""
import time, json, base64, sys, hashlib, urllib.request
import os

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEY_ID = "L3UHT69Y77"
ISSUER_ID = "98812827-46d0-4c8f-9b91-35d4f783e6df"
P8_PATH = r"E:\AI-Projects\个人成长\50-Skills\密钥\苹果\AuthKey_L3UHT69Y77.p8"
APP_ID = "6832398956"   # NotaryTrack
VER = "1.0"
STORE = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\store"
PRIVACY_URL = "https://postwriter.cn/seo/notarytrack-privacy.html"
APP_NAME = "NotaryTrack"

def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes

key = load_pem_private_key(open(P8_PATH, "rb").read(), password=None)
h = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
p = b64url(json.dumps({"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}).encode())
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
jwt = f"{h}.{p}.{b64url(raw(sig))}"

def asc(url, data=None, method=None):
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body,
        headers={"Authorization": "Bearer " + jwt, "Content-Type": "application/json"}, method=method or ("POST" if data else "GET"))
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.status, json.loads(resp.read() or b"{}")
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read() or b"{}")
        except Exception as ex:
            if attempt == 3: return -1, {"err": str(ex)}
            time.sleep(3)

EN_DESC = """The bookkeeping app built for notary signing agents.

Log every signing. Get paid. Stay compliant.

NotaryTrack keeps your title company contacts, signing fees, trip fees and notarial acts organized — so invoice day is five minutes, not a spreadsheet nightmare.

▸ CLIENT PROFILES
Title companies and signing services: contact info, payment terms, and an automatic average days-to-pay for each. Know who pays fast and who chases you.

▸ SIGNING LOG
Fee, trip fee, and notarial acts per signing. Mark Done / No-show / Paid with one tap. Overdue payments flag automatically at 30 and 45 days.

▸ COMMISSION REMINDER
Your commission expiry tracked with a 90-day heads-up — never let it lapse while you're busy.

▸ MONTHLY SUMMARY
Signings, income, and unpaid totals for the month — ready for your tax preparer.

▸ FOLLOW-UP NUDGES
Business clients quiet for 30 days (or individuals 90) appear on your follow-up list. Relationships stay warm.

PRIVATE BY DESIGN
No account. No cloud. No ads. No analytics. No network access at all — your records never leave your device.

FREE AND SIMPLE
Unlimited clients, unlimited signings, all features free. Deleting the app removes everything instantly — because nothing was ever sent anywhere."""

LOCALES = {
    "en-US": {"subtitle": "Signing agent book & fee log",
              "keywords": "notary signing agent,loan signer,title company,notary journal,fee tracker,notary public,escrow",
              "description": EN_DESC},
    "ja": {"subtitle": "署理エージェントの記録帳",
           "keywords": "公証,署理,記録,報酬,顧客管理,コミッション,期限,月次",
           "description": "公証署理エージェント（Signing Agent）のための記録アプリ。\n\nすべての署理を記録。報酬を逃さない。\n\nNotaryTrack は顧客（タイトル会社）の連絡先、署理報酬、公証行為を整理——請求日は5分で済みます。\n\n▸ 顧客プロファイル\nタイトル会社ごとの連絡先、支払条件、平均入金日数を自動記録。早い支払い先と遅い先が一目瞭然。\n\n▸ 署理記録\n一件ごとの報酬、公証行為。完了/キャンセル/入金済みをワンタップで記録。30日・45日超の未入金を自動警告。\n\n▸ 資格期限リマインダー\nコミッションの有効期限を90日前から通知——忙しくても失効しない。\n\n▸ 月次サマリー\n署理数・収入・未入金——税務準備はこれで完了。\n\nプライバシー設計：アカウントなし・クラウドなし・広告なし。ネットワークアクセス自体がなく、データは端末から出ません。\n\n無料でシンプル：顧客も署理も無制限、全機能無料。"},
    "de-DE": {"subtitle": "Kundenbuch für Notare",
           "keywords": "Notar,Kundenbuch,Gebühren,Termine,Fristen,Verwaltung,Mobil,Commission",
           "description": "Das Buchhaltungsbuch für mobile Notare und Signing Agents. Jede Beurkundung erfassen. Bezahlt werden. Konform bleiben. NotaryTrack organisiert Ihre Kunden (Titelfirmen), Gebühren, Fahrtkosten und Beurkundungen — der Rechnungstag dauert fünf Minuten statt eines Tabellen-Albtraums. ▸ KUNDENPROFILE Titelfirmen und Signing Services: Kontakt, Zahlungsziele und automatisch berechnete durchschnittliche Zahlungstage. Sie sehen auf einen Blick, wer schnell zahlt. ▸ SIGNING-PROTOKOLL Gebühr, Fahrtkosten-Pauschale und Beurkundungen pro Termin. Erledigt / No-Show / Bezahlt mit einem Tipp. Überfällige Zahlungen werden automatisch nach 30 und 45 Tagen markiert. ▸ BESTELLUNG-ERINNERUNG Ihre Commission-Laufzeit mit 90-Tage-Vorwarnung — läuft nie ab, während Sie beschäftigt sind. ▸ MONATSSUMME Termine, Einnahmen und offene Posten des Monats — bereit für Ihren Steuerberater. PRIVAT VON DESIGN: Kein Konto, keine Cloud, keine Werbung, kein Netzwerkzugriff — Ihre Daten verlassen das Gerät nie. KOSTENLOS: Unbegrenzte Kunden und signings, alle Funktionen gratis."},
    "fr-FR": {"subtitle": "Carnet notaire signing agent",
           "keywords": "notaire,signing agent,carnet client,honoraires,commission,échéances,suivi,paiements,mobile",
           "description": "Le carnet de gestion pour notaires signing agents à domicile. Connectez chaque signature. Soyez payé. Restez conforme. NotaryTrack organise vos clients (sociétés de titres), honoraires, frais de déplacement et actes notariés — le jour de facturation prend cinq minutes au lieu d'un cauchemar de tableur. ▸ FICHES CLIENTS Sociétés de titres et services de signature : contact, conditions de paiement et délai moyen de paiement calculé automatiquement. Voyez qui paie vite et qui traîne. ▸ JOURNAL DE SIGNATURES Honoraires, frais de déplacement et actes notariés par séance. Marquez Terminé / No-show / Payé en un geste. Les impayés sont signalés automatiquement à 30 et 45 jours. ▸ RAPPEL DE COMMISSION Votre commission suivie avec un préavis de 90 jours — n'expire jamais pendant vos périodes chargées. ▸ RÉSUMÉ MENSUEL Signatures, revenus et impayés du mois — prêt pour votre préparateur fiscal. CONFIDENTIALITÉ PAR CONCEPTION : aucun compte, aucun cloud, aucune pub, aucun accès réseau — vos données ne quittent jamais votre appareil. GRATUIT : clients et signatures illimités, toutes les fonctions gratuites."},
    "es-ES": {"subtitle": "Libro notario signing agent",
           "keywords": "notario,signing agent,libro clientes,honorarios,plazos,seguimiento,pagos,móvil,escrow",
           "description": "El libro de registro para notarios signing agents a domicilio. Registre cada firma. Le paguen. Manténgase conforme. NotaryTrack organiza sus clientes (compañías de títulos), honorarios, gastos de viaje y actas notariales — el día de facturación toma cinco minutos en lugar de una pesadilla de hojas de cálculo. ▸ FICHAS DE CLIENTE Compañías de títulos y servicios de firma: contacto, condiciones de pago y días promedio hasta el pago calculados automáticamente. Vea quién paga rápido y quién le debe. ▸ REGISTRO DE FIRMAS Honorarios, tarifa de viaje y actas notariales por cita. Marque Completada / No-show / Pagada con un toque. Los pagos vencidos se marcan automáticamente a los 30 y 45 días. ▸ RECORDATORIO DE COMISIÓN Su comisión seguida con aviso de 90 días — nunca caduca mientras está ocupado. ▸ RESUMEN MENSUAL Firmas, ingresos y pendientes del mes — listo para su preparador de impuestos. PRIVACIDAD POR DISEÑO: sin cuenta, sin nube, sin anuncios, sin acceso a red — sus datos nunca salen del dispositivo. GRATIS: clientes y firmas ilimitadas, todas las funciones gratis."},
    "zh-Hans": {"subtitle": "公证签署代理人的记账本",
           "keywords": "公证员,签署代理,客户管理,收入记录,车马费,委托证,到期提醒,月度报表,记账本,移动公证",
           "description": "为移动公证签署代理人打造的登记本。\n\n每一单都有记录，每一笔都不漏。\n\nNotaryTrack 把客户（产权公司/签约服务）、费用、车马费和公证行为整理得清清楚楚——对账日五分钟搞定，不用翻表格。\n\n▸ 客户档案\n产权公司和签约服务：联系方式、付款周期、自动计算的\"平均回款天数\"——谁付款快谁拖拉一目了然。\n\n▸ 签署单记录\n每单的费用、跑趟费、公证行为数。完成/放鸽子/已收款一键标记。超30天、超45天未收款自动标红提醒。\n\n▸ 委托证到期提醒\n委托证有效期提前90天预警——再忙也不会过期失效。\n\n▸ 月度总结\n本月单数、收入、未收款——报税材料随时就绪。\n\n隐私设计：无账号、无云端、无广告、无任何联网——数据永远不离开设备。\n\n免费简洁：客户和签署单不限量，全功能免费。"},
    "zh-Hant": {"subtitle": "公證簽署代理人的記賬本",
           "keywords": "公證員,簽署代理,客戶管理,收入記錄,車馬費,委託證,到期提醒,月度報表,記賬本,行動公證",
           "description": "為行動公證簽署代理人打造的登記本。每一單都有記錄，每一筆都不漏。NotaryTrack 把客戶（產權公司/簽約服務）、費用、車馬費和公證行為整理得清清楚楚——對賬日五分鐘搞定，不用翻表格。▸ 客戶檔案 產權公司和簽約服務：聯絡方式、付款週期、自動計算的「平均回款天數」——誰付款快誰拖拉一目瞭然。▸ 簽署單記錄 每單的費用、跑趟費、公證行為數。完成/放鴿子/已收款一鍵標記。超30天、超45天未收款自動標紅提醒。▸ 委託證到期提醒 委託證有效期提前90天預警——再忙也不會過期失效。▸ 月度總結 本月單數、收入、未收款——報稅材料隨時就緒。▸ 隱私設計 無帳號、無雲端、無廣告、無任何聯網——資料永遠不離開裝置。▸ 免費簡潔 客戶和簽署單不限量，全功能免費。"},
}

# 字符预算 assert（30/100 硬限）
for loc, info in LOCALES.items():
    assert len(info["subtitle"]) <= 30, f"{loc} subtitle 超限: {len(info['subtitle'])}"
    assert len(info["keywords"]) <= 100, f"{loc} keywords 超限: {len(info['keywords'])}"
    print(f"budget {loc}: subtitle={len(info['subtitle'])}/30 keywords={len(info['keywords'])}/100 OK")

# 1. 版本
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=5")
vers = r.get("data", [])
if not vers:
    print("[1] 无版本（异常）"); sys.exit(1)
ver_id = vers[0]["id"]
if vers[0]["attributes"].get("versionString") != VER:
    asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}",
        {"data": {"type": "appStoreVersions", "id": ver_id, "attributes": {"versionString": VER}}}, method="PATCH")
print(f"[1] 版本 {VER} id={ver_id} state={vers[0]['attributes'].get('appStoreState')}")

# 2. App 信息层（语言注册+名称+副标题+隐私URL）——subtitle在这层
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}?include=appInfos")
app_info_id = None
for inc in r.get("included", []):
    if inc["type"] == "appInfos":
        app_info_id = inc["id"]; break
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appInfos/{app_info_id}/appInfoLocalizations")
info_existing = {l["attributes"]["locale"]: l["id"] for l in r.get("data", [])}
for locale, info in LOCALES.items():
    attrs = {"name": APP_NAME, "subtitle": info["subtitle"], "privacyPolicyUrl": PRIVACY_URL}
    if locale in info_existing:
        st, rr = asc(f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{info_existing[locale]}",
                     {"data": {"type": "appInfoLocalizations", "id": info_existing[locale], "attributes": attrs}}, method="PATCH")
    else:
        st, rr = asc("https://api.appstoreconnect.apple.com/v1/appInfoLocalizations", {"data": {
            "type": "appInfoLocalizations", "attributes": {"locale": locale, **attrs},
            "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}}}})
    print(f"[2] App信息 {locale}: {'OK' if st in (200, 201) else f'{st} ' + json.dumps(rr)[:200]}")

# 3. 版本文案层（description/keywords/supportUrl）——keywords在这层
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
existing = {l["attributes"]["locale"]: l["id"] for l in r.get("data", [])}
en_loc = None
for locale, info in LOCALES.items():
    payload = {"type": "appStoreVersionLocalizations", "attributes": {
        "locale": locale, "keywords": info["keywords"], "description": info["description"],
        "supportUrl": "https://postwriter.cn"}}
    if locale in existing:
        patch_attrs = {k: v for k, v in payload["attributes"].items() if k != "locale"}
        if locale == "en-US": en_loc = existing[locale]
        st, rr = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{existing[locale]}",
                     {"data": {"type": "appStoreVersionLocalizations", "id": existing[locale], "attributes": patch_attrs}}, method="PATCH")
    else:
        payload["relationships"] = {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}
        st, rr = asc("https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations", {"data": payload})
        if locale == "en-US" and st in (200, 201): en_loc = rr["data"]["id"]
    print(f"[3] 版本文案 {locale}: {'OK' if st in (200, 201) else f'{st} ' + json.dumps(rr)[:200]}")

# 4. 截图上传（en-US locale，APP_IPHONE_67）——已有截图集则跳过重复上传
if not en_loc:
    st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
    for l in r.get("data", []):
        if l["attributes"]["locale"] == "en-US": en_loc = l["id"]
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{en_loc}/appScreenshotSets")
set_id = None
already = False
for s in r.get("data", []):
    if s["attributes"].get("screenshotDisplayType") == "APP_IPHONE_67":
        set_id = s["id"]; break
if set_id:
    st2, r2 = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshotSets/{set_id}/appScreenshots")
    if r2.get("data"):
        already = True
        print(f"[4] 截图集已有 {len(r2['data'])} 张，跳过上传")
if not already:
    if not set_id:
        st, r = asc("https://api.appstoreconnect.apple.com/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": en_loc}}}}})
        if st in (200, 201) and r.get("data"):
            d0 = r["data"]
            set_id = d0[0]["id"] if isinstance(d0, list) else d0["id"]
        else:
            print(f"[4] 截图集创建失败 {st}"); sys.exit(1)
    print(f"[4] 截图集 {set_id}")
    for i in range(1, 4):
        path = os.path.join(STORE, f"shot{i}.png")
        data = open(path, "rb").read()
        md5 = base64.b64encode(hashlib.md5(data).digest()).decode()
        st, r = asc("https://api.appstoreconnect.apple.com/v1/appScreenshots", {
            "data": {"type": "appScreenshots", "attributes": {"fileName": f"shot{i}.png", "fileSize": len(data)},
                     "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
        if st not in (200, 201):
            print(f"  shot{i} reserve FAIL {st} {json.dumps(r)[:150]}"); continue
        upload = r["data"]["attributes"]["uploadOperations"][0]
        headers = {hh["name"]: hh["value"] for hh in upload.get("requestHeaders", [])}
        req = urllib.request.Request(upload["url"], data=data, headers=headers, method=upload["method"])
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                up_ok = resp.status in (200, 201)
        except Exception:
            up_ok = False
        if up_ok:
            st2, r2 = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{r['data']['id']}",
                          {"data": {"type": "appScreenshots", "id": r["data"]["id"],
                                    "attributes": {"uploaded": True, "sourceFileChecksum": md5}}}, method="PATCH")
            print(f"  shot{i}: {'OK' if st2 in (200, 201) else 'confirm FAIL'}")
        time.sleep(2)

print("[5] 完成——网页剩：版权/隐私标签(不收集)/定价(免费)/供应地区(摘除大陆)/登录信息不勾/发布方式手动")
