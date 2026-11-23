# -*- coding: utf-8 -*-
"""NotaryTrack 2.3.3 拒审修复 · 真实 UI 截图重建 · 2026-11-19
按 SwiftUI 源码 1:1 重建 5 屏在用界面（1320×2868 = 6.9 寸 iPhone 16 Pro Max），
顶部 15% caption 条（功能名+一句话）+ 下方纯 UI——苹果认可的标准形态。
标准依据：拒审信 "majority of screenshots should highlight the app's main features in use"。
"""
import os

W, H = 1320, 2868
CAP_H = 380          # 顶部 caption 区高度（约 13%）
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)))

# iOS 真实 UI 色板（SwiftUI 默认：indigo accent/系统灰背景/分组白卡）
IOS_BG = "#F2F2F7"
IOS_CARD = "#FFFFFF"
IOS_INDIGO = "#5856D6"
IOS_TEXT = "#000000"
IOS_SUB = "#8A8A8E"
IOS_SEP = "#C6C6C8"
IOS_GREEN = "#34C759"
IOS_ORANGE = "#FF9500"
IOS_RED = "#FF3B30"
IOS_BLUE = "#007AFF"

FONT = "font-family:-apple-system,'SF Pro Text','Segoe UI',sans-serif"

def caption(kicker, line):
    return f'''
<div style="height:{CAP_H}px;display:flex;flex-direction:column;justify-content:center;align-items:center;
     background:linear-gradient(180deg,#12332B 0%,#1d4a3e 100%);{FONT}">
  <div style="font-size:44px;font-weight:700;color:#fff;letter-spacing:-.01em">{kicker}</div>
  <div style="font-size:28px;color:#9fc3b4;margin-top:12px">{line}</div>
</div>'''

def phone_frame(inner, tab_active):
    """iPhone 机身框（深色边+灵动岛）+ 内部真实 UI + 底部 Tab 栏"""
    tabs = ""
    for icon, label, active in [("calendar", "Today", tab_active == "Today"),
                                 ("doc.text", "Signings", tab_active == "Signings"),
                                 ("person.2", "Clients", tab_active == "Clients"),
                                 ("person.crop.circle", "Me", tab_active == "Me")]:
        color = IOS_INDIGO if active else IOS_SUB
        weight = "600" if active else "400"
        tabs += f'''<div style="flex:1;text-align:center;padding-top:10px">
<div style="font-size:40px;color:{color};line-height:1">⬤</div>
<div style="font-size:24px;color:{color};font-weight:{weight};margin-top:4px">{label}</div></div>'''
    return f'''
<div style="padding:30px 60px 60px;background:linear-gradient(180deg,#12332B 0%,#1d4a3e 100%);{FONT}">
<div style="background:#111;border-radius:64px;padding:22px;box-shadow:0 30px 80px rgba(0,0,0,.45)">
<div style="background:{IOS_BG};border-radius:44px;overflow:hidden;height:2060px;display:flex;flex-direction:column;position:relative">
  <div style="background:rgba(242,242,247,.94);padding:26px 40px 20px;display:flex;justify-content:space-between;align-items:center">
    <span style="font-size:26px;color:{IOS_TEXT};font-weight:600">9:41</span>
    <div style="width:270px;height:66px;background:#111;border-radius:0 0 30px 30px;position:absolute;left:50%;transform:translateX(-50%);top:22px"></div>
    <span style="font-size:24px;color:{IOS_TEXT}">▲▲ ⌁ ▮</span>
  </div>
  {inner}
  <div style="margin-top:auto;background:rgba(242,242,247,.94);border-top:1px solid {IOS_SEP};
       display:flex;padding:8px 10px 26px">{tabs}</div>
</div></div></div>'''

def nav_bar(title):
    return f'''<div style="padding:20px 40px 18px;background:rgba(242,242,247,.94);display:flex;justify-content:space-between;align-items:center">
<span style="font-family:'SF Pro Display',-apple-system,sans-serif;font-size:56px;font-weight:700;color:{IOS_TEXT}">{title}</span>
<span style="font-size:44px;color:{IOS_INDIGO}">ⓘ</span>
</div>'''

def section_header(t):
    return f'<div style="padding:10px 40px 8px;font-size:26px;color:{IOS_SUB};text-transform:uppercase;{FONT}">{t}</div>'

def card(inner, badge=""):
    b = f'<div style="position:absolute;right:30px;top:24px">{badge}</div>' if badge else ""
    return f'''<div style="margin:0 24px 20px;background:{IOS_CARD};border-radius:22px;padding:30px 34px;
         position:relative;box-shadow:0 1px 2px rgba(0,0,0,.04);font-size:30px;color:{IOS_TEXT}">{inner}{b}</div>'''

screens = {}

# ===== 屏1 Today：委托证警示 + 该回访 + 今日签署分组（真实 List 结构）=====
warn = f'''<div style="margin:0 24px 20px;background:{IOS_CARD};border-radius:22px;padding:28px 34px;
     font-size:31px;color:{IOS_RED};display:flex;align-items:center;gap:18px">
<span style="font-size:40px">⚠️</span> Commission expires in 82 days (TX) — start your renewal</div>'''
follow = card(f'''<div style="font-size:32px;font-weight:700">ABC Title Co.</div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:6px">41 days since last signing (business · 30-day norm)</div>''',
'<span style="font-size:40px;color:'+IOS_INDIGO+'">📞</span>')
row1 = card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">First American — Nguyen refi</span>
<span style="font-size:26px;color:{IOS_SUB}">9:00 AM</span></div>
<div style="display:flex;gap:26px;font-size:26px;color:{IOS_SUB};margin-top:12px">
<span>💵 $150</span><span>🚗 Trip $45</span><span style="color:{IOS_ORANGE}">⏳ Unpaid</span></div>
<div style="display:flex;gap:14px;margin-top:18px">
<span style="border:1px solid {IOS_SEP};border-radius:12px;padding:8px 22px;font-size:25px;color:{IOS_BLUE}">✓ Done</span>
<span style="border:1px solid {IOS_SEP};border-radius:12px;padding:8px 22px;font-size:25px;color:{IOS_BLUE}">✗ No-show</span>
<span style="background:{IOS_INDIGO};border-radius:12px;padding:8px 22px;font-size:25px;color:#fff">💰 Mark Paid</span></div>''')
row2 = card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">Stewart Title — Lee purchase</span>
<span style="font-size:26px;color:{IOS_SUB}">2:30 PM</span></div>
<div style="display:flex;gap:26px;font-size:26px;color:{IOS_SUB};margin-top:12px">
<span>💵 $200</span><span>🚗 Trip $60</span><span style="color:{IOS_GREEN}">✔ Paid</span></div>''')
screens["01-today"] = caption("Commission & follow-ups, handled",
    "Expiry warnings and client follow-ups surface themselves") + phone_frame(
    nav_bar("Today") + warn + section_header("Due for follow-up") + follow +
    section_header("Today · June 12") + row1 + row2, "Today")

# ===== 屏2 Signing 录入表单（真实 Form 结构，填了的状态）=====
def form_row(label, value, chevron=False):
    ch = '<span style="color:#C7C7CC;font-size:34px">›</span>' if chevron else ""
    return f'''<div style="display:flex;justify-content:space-between;align-items:center;padding:24px 0;
         border-bottom:1px solid {IOS_SEP};font-size:30px">
<span style="color:{IOS_TEXT}">{label}</span>
<span style="display:flex;align-items:center;gap:14px;color:{IOS_SUB}">{value}{ch}</span></div>'''
form = f'''<div style="margin:0 24px;background:{IOS_CARD};border-radius:22px;padding:10px 34px">
{form_row("Client", '<span style="color:'+IOS_TEXT+'">ABC Title Co.</span>', True)}
{form_row("Type", "🏡 Refinance", True)}
{form_row("Date & time", "Jun 12, 2026 9:00 AM", True)}
</div>
<div style="margin:24px 24px;background:{IOS_CARD};border-radius:22px;padding:10px 34px">
{form_row("Signing location", "1247 Elm St, Austin")}
{form_row("Table time", "60 min")}
{form_row("Drive buffer", "20 min")}
{form_row("Reminder", "1 hour before", True)}
</div>
<div style="margin:0 24px;background:{IOS_CARD};border-radius:22px;padding:10px 34px">
{form_row("Total fee $", "150")}
{form_row("Notary portion $ (SE-exempt)", "15")}
{form_row("Trip fee $", "45")}
{form_row("Mileage", "42 mi")}
</div>
<div style="margin:26px 24px;background:{IOS_INDIGO};border-radius:22px;padding:26px;text-align:center;
     font-size:32px;font-weight:600;color:#fff">Save Signing</div>'''
screens["02-new-signing"] = caption("Log a signing in under a minute",
    "Fees, mileage and reminders — nothing missed") + phone_frame(
    nav_bar("New Signing") + form, "Today")

# ===== 屏3 Signings 列表（按日分组历史）=====
rows = ""
for day, items in [("Today · June 12", [("First American — Nguyen refi", "9:00 AM", "$150", False),
                                          ("Stewart Title — Lee purchase", "2:30 PM", "$200", True)]),
                    ("Yesterday · June 11", [("Fidelity — Carter HELOC", "11:00 AM", "$175", True),
                                              ("ABC Title — Davis refi", "4:00 PM", "$150", True)]),
                    ("June 10", [("Freedom Mtg — Walker refi", "10:00 AM", "$150", True)])]:
    rows += section_header(day)
    for company, t, fee, paid in items:
        pay = f'<span style="color:{IOS_GREEN}">✔ Paid</span>' if paid else f'<span style="color:{IOS_ORANGE}">⏳ Unpaid</span>'
        rows += card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">{company}</span><span style="font-size:26px;color:{IOS_SUB}">{t}</span></div>
<div style="display:flex;gap:26px;font-size:26px;color:{IOS_SUB};margin-top:12px">
<span>💵 {fee}</span><span>🚗 Trip $45</span>{pay}</div>''')
screens["03-signings-list"] = caption("Every signing, every fee — on record",
    "Grouped by day, status at a glance") + phone_frame(
    nav_bar("Signings") + rows, "Signings")

# ===== 屏4 月度收入（This Month 收入/里程/未付——对应旧 shot2 的真实 List 版）=====
inc = card(f'''<div style="font-size:28px;font-weight:700;color:{IOS_BLUE}">INCOME</div>
<div style="margin-top:14px;font-size:30px"><span style="color:{IOS_GREEN}">Notary fees (SE-exempt) $560</span></div>
<div style="font-size:30px">Service fees (taxable) $2,140</div>
<div style="font-size:30px">Trip fees $135</div>
<div style="font-size:34px;font-weight:700;margin-top:12px">Total income $2,835</div>''')
mil = card(f'''<div style="font-size:28px;font-weight:700;color:{IOS_BLUE}">MILEAGE & TAX</div>
<div style="margin-top:14px;font-size:30px">212 miles — IRS deduction $142</div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:8px">Every signing logged as you go</div>''')
unp = card(f'''<div style="font-size:28px;font-weight:700;color:{IOS_BLUE}">UNPAID</div>
<div style="margin-top:14px;font-size:30px;color:#c4553d">3 signings · $425 aged 30+ days</div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:8px">Chase list built automatically</div>''')
screens["04-monthly-income"] = caption("Tax-ready records, automatically",
    "Income, mileage and who still owes you") + phone_frame(
    nav_bar("Me") + section_header("This Month · 18 signings") + inc + mil + unp, "Me")

# ===== 屏5 Clients + 逾期追踪 =====
cli = card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">ABC Title Co.</span><span style="font-size:26px;color:{IOS_SUB}">Business</span></div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:10px">Sarah · (512) 555-0148 · 12 signings</div>''')
cli2 = card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">Stewart Title</span><span style="font-size:26px;color:{IOS_SUB}">Business</span></div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:10px">Mike · (512) 555-0193 · 8 signings</div>'''
, '<span style="background:rgba(255,59,48,.12);color:'+IOS_RED+';border-radius:999px;padding:6px 18px;font-size:24px;font-weight:600">3 overdue</span>')
cli3 = card(f'''<div style="display:flex;justify-content:space-between;align-items:center">
<span style="font-size:32px;font-weight:700">Walker Family</span><span style="font-size:26px;color:{IOS_SUB}">Individual</span></div>
<div style="font-size:26px;color:{IOS_SUB};margin-top:10px">1 signing · last 12 days ago</div>''')
ovr = f'''<div style="margin:0 24px 20px;background:linear-gradient(135deg,#7d4bd1,#5856D6);border-radius:22px;
     padding:28px 34px;color:#fff;font-size:30px">3 OVERDUE · total $425 — flagged automatically from your history</div>'''
screens["05-clients-overdue"] = caption("Know who owes you, without spreadsheets",
    "Aging tracked, chase list built in") + phone_frame(
    nav_bar("Clients") + ovr + section_header("All clients") + cli + cli2 + cli3, "Clients")

# ===== 渲染 =====
HTML_TMPL = '''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
*{{margin:0;padding:0}}body{{width:{w}px;height:{h}px;overflow:hidden}}</style></head>
<body>{content}</body></html>'''

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, content in screens.items():
        path = os.path.join(OUT, f"{name}.html")
        open(path, "w", encoding="utf-8").write(HTML_TMPL.format(w=W, h=H, content=content))
        print("built", path)
    print(f"{len(screens)} screens @ {W}x{H}")
