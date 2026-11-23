# NotaryTrack 审核信息包（提前备齐——GroomerBook 2.1 拒审教训的预防版）

> 用途：健哥网页提交审核前，将以下全文贴入 App Review Information → Notes。
> 录屏：健哥需先录（脚本见文末），录完传给我部署外网直链，替换下方占位链接。

```
Thank you for reviewing NotaryTrack (v1.0). Below is all requested information.

1. SCREEN RECORDING
A screen recording captured on a physical iPhone (latest iOS) is available at:
https://postwriter.cn/seo/notarytrack-review-demo.mp4
It shows the complete flow from cold launch: creating a title company client, logging a signing with fee and notarial acts, marking it paid, viewing the overdue tracker, and setting a commission expiry reminder.
The app has NO account creation, NO login, NO user-generated content sharing — so account deletion, content reporting/blocking flows are not applicable. There is no paid content within the app (the app is entirely free).

2. APP PURPOSE AND TARGET AUDIENCE
NotaryTrack is a local record-keeping utility for independent notary signing agents (mobile notaries who handle loan signing appointments). It solves an operational problem: agents previously tracked title company contacts, signing fees, trip fees, notarial act counts, and commission expiry dates in paper notebooks or spreadsheets. The app organizes all of this locally, flags overdue payments automatically, and reminds the agent before their commission expires. Target audience: commissioned notary signing agents in the United States (solo operators).

3. SETUP AND MAIN FEATURES
No account or setup required — works immediately after install:
- Clients tab: tap + to add a title company / signing service (contact, phone, email, payment terms).
- Signings tab: tap + to log a signing (client, date, fee, trip fee, notarial acts, payment status). Mark Done / No-show / Paid with one tap. Overdue payments flag automatically at 30 and 45 days.
- Today tab: commission expiry warning (90-day heads-up) and follow-up nudges for quiet clients.
- Me tab: feedback via email.

4. EXTERNAL SERVICES
None. The app has no network access, no analytics, no third-party SDKs. All data is stored locally on the device. The Contacts integration is an iOS system framework invoked only by explicit user action.

5. REGIONAL DIFFERENCES
None. The app functions identically across all regions — all data is local and no region-dependent services exist. The app is designed for US notary signing agents but contains no region-locked functionality.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. NotaryTrack is a business record-keeping utility. It is NOT a notary journal and does not perform or facilitate notarization — it only tracks business records (fees, contacts, dates). All content is original.

Demo account: Not applicable — the app requires no account or login.
```

## 录屏脚本（健哥照此录，TestFlight build 31+，1.5-2 分钟）

```
1. 冷启动 NotaryTrack（从图标点开）
2. Clients tab → + → 填公司名 "ABC Title" → 联系人/电话 → 保存
3. Signings tab → + → 选 ABC Title → 费用 $150 → 公证行为计数 → 保存
4. 今日页 → 点这单「完成」→ 点「标记已收款」
5. 再造一单 → 点「没来」→ 看 no-show 计数
6. 签署单页 → 展示月结（单数/收入/公证费免税/服务费/年度累计）
7. 菜单 → 委托证设置 → 填日期 → 看 90 天预警条
（结束——全程 90 秒内）
```

## 提交操作清单（录屏到位后）

1. 录屏转码（H.264 mp4）→ scp VPS `/opt/postwriter/seo_pages/notarytrack-review-demo.mp4`
2. 本文件上方占位链接替换为真实直链 → curl 验证 200
3. Notes 全文贴入 ASC「App 审核」→ 备注（或 API PATCH appStoreReviewDetail）
4. 网页两步：①版本页「更新审核」②「App 审核」页「提交审核」
5. 完成后 AI 回读确认 WAITING_FOR_REVIEW
