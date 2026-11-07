# NotaryTrack (iOS)

Notary signing agent's book — signing orders (fee / mileage / notarial-act counts / payment status), clients (title companies), commission expiry reminder, monthly summary for taxes.

## Why this exists (pain-point sourced)

See `../SaaS项目/research/公证签署代理人App-痛点清单与施工单-2026-11-07.md`:
- N1 — agents with years of experience still tracking everything in Google Sheets
- N2 — mileage = real tax deduction (IRS rate), every round trip counts
- N3 — fee tracking across multiple title companies
- N5 — commission expiry = income stops; 90-day heads-up
- N6 — notarial act counts for taxes & state reports

## Compliance positioning (v1)

**Business record tool, NOT a legal e-Journal.** No "compliant journal" claims; wording: track/log/record only, never notarize/perform. Pure local, no account, no network.

## Status

v1.0 中文测试版（健哥真机测试先行——2026-11-07 流程变更：测过才英文回改上架）

- [x] Data layer (Client/Signing/Commission + store)
- [x] UI 中文版：今日/签署单/客户 三Tab + 月度小结 + 委托证提醒
- [ ] CI 绿 → TF → 健哥测试
- [ ] 反馈修改 → 英文回改 → `/ios-appstore-launch`

## Privacy

No account. No network. Everything stays on device.

## License

MIT
