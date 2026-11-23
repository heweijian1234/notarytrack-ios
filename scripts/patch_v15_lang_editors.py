# -*- coding: utf-8 -*-
"""v1.5 补丁③：Editors.swift 全量双语（健哥11-24令）"""
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
p = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\NotaryTrack\Editors.swift"
src = open(p, encoding="utf-8").read()

pairs = [
    # SigningEditor
    ('@State private var notaryFeeHint = "打包价通常 $0"', '@State private var notaryFeeHint = L("Flat fee usually $0", "打包价通常 $0")'),
    ('notaryFeeHint = (t == .general || t == .hospital || t == .estate) ? "每签 $10-25（按州价）" : "打包价通常 $0"',
     'notaryFeeHint = (t == .general || t == .hospital || t == .estate) ? L("$10-25 per signature (state fee)", "每签 $10-25（按州价）") : L("Flat fee usually $0", "打包价通常 $0")'),
    ('Section("Client")', 'Section(L("Client", "客户"))'),
    ('Text("Add a client first (Clients tab).")', 'Text(L("Add a client first (Clients tab).", "先加客户（客户页）。"))'),
    ('Picker("Client", selection: $clientId)', 'Picker(L("Client", "客户"), selection: $clientId)'),
    ('Section("Time & Place")', 'Section(L("Time & Place", "时间与地点"))'),
    ('Picker("Type", selection: $serviceType)', 'Picker(L("Type", "类型"), selection: $serviceType)'),
    ('Text("Suggested: ~\\(minutes) min at the table · notary fee \\(notaryFeeHint)")',
     'Text(L("Suggested: ~\\(minutes) min at the table · notary fee \\(notaryFeeHint)", "建议：桌上约 \\(minutes) 分钟 · 公证费 \\(notaryFeeHint)"))'),
    ('DatePicker("Date & time", selection: $date)', 'DatePicker(L("Date & time", "日期时间"), selection: $date)'),
    ('TextField("Signing location (property address)", text: $address)', 'TextField(L("Signing location (property address)", "签署地点（房产地址）"), text: $address)'),
    ('Stepper("Table time \\(minutes) min", value: $minutes, in: 15...240, step: 15)',
     'Stepper(L("Table time \\(minutes) min", "桌上 \\(minutes) 分钟"), value: $minutes, in: 15...240, step: 15)'),
    ('Stepper("Drive buffer \\(buffer) min", value: $buffer, in: 0...60, step: 5)',
     'Stepper(L("Drive buffer \\(buffer) min", "车程缓冲 \\(buffer) 分钟"), value: $buffer, in: 0...60, step: 5)'),
    ('Toggle("Reminder (alert)", isOn: $remindMe)', 'Toggle(L("Reminder (alert)", "提醒（闹钟）"), isOn: $remindMe)'),
    ('Picker("Remind me", selection: $remindMinutesBefore)', 'Picker(L("Remind me", "提前提醒"), selection: $remindMinutesBefore)'),
    ('Text("30 min before").tag(30)', 'Text(L("30 min before", "提前30分钟")).tag(30)'),
    ('Text("45 min before").tag(45)', 'Text(L("45 min before", "提前45分钟")).tag(45)'),
    ('Text("1 hour before").tag(60)', 'Text(L("1 hour before", "提前1小时")).tag(60)'),
    ('Text("2 hours before").tag(120)', 'Text(L("2 hours before", "提前2小时")).tag(120)'),
    ('Text("3 hours before").tag(180)', 'Text(L("3 hours before", "提前3小时")).tag(180)'),
    ('Text("4 hours before").tag(240)', 'Text(L("4 hours before", "提前4小时")).tag(240)'),
    ('Text("6 hours before").tag(360)', 'Text(L("6 hours before", "提前6小时")).tag(360)'),
    ('Text("10 hours before").tag(600)', 'Text(L("10 hours before", "提前10小时")).tag(600)'),
    ('Text("Notified \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60)h" : "\\(remindMinutesBefore) min") before — leave time for the \\(buffer) min drive.")',
     'Text(L("Notified \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60)h" : "\\(remindMinutesBefore) min") before — leave time for the \\(buffer) min drive.", "提前 \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60) 小时" : "\\(remindMinutesBefore) 分钟") 通知——留出 \\(buffer) 分钟车程。"))'),
    ('Section("Fees & Mileage")', 'Section(L("Fees", "费用"))'),
    ('Text("Total fee $")', 'Text(L("Total fee $", "总费用 $"))'),
    ('Text("Notary portion $ (SE-exempt)")', 'Text(L("Notary portion $ (SE-exempt)", "公证费 $（免SE税）"))'),
    ('Text("Trip fee $")', 'Text(L("Trip fee $", "跑趟费 $"))'),
    ('Text("Notary portion is exempt from self-employment tax (IRC §1402).")',
     'Text(L("Notary portion is exempt from self-employment tax (IRC §1402).", "公证费部分免自雇税（IRC §1402）。"))'),
    ('Section("Notarial Acts")', 'Section(L("Notarial Acts", "公证行为"))'),
    ('Stepper("Loan docs: \\(borrowDocs)", value: $borrowDocs, in: 0...20)',
     'Stepper(L("Loan docs: \\(borrowDocs)", "借款文件：\\(borrowDocs)"), value: $borrowDocs, in: 0...20)'),
    ('Stepper("Other docs: \\(trustDocs)", value: $trustDocs, in: 0...20)',
     'Stepper(L("Trust docs: \\(trustDocs)", "信托文件：\\(trustDocs)"), value: $trustDocs, in: 0...20)'),
    ('Stepper("Misc acts: \\(otherDocs)", value: $otherDocs, in: 0...20)',
     'Stepper(L("Misc acts: \\(otherDocs)", "其他行为：\\(otherDocs)"), value: $otherDocs, in: 0...20)'),
    ('Section("Notes")', 'Section(L("Notes", "备注"))'),
    ('TextField("Order # / special instructions…", text: $note, axis: .vertical)',
     'TextField(L("Order # / special instructions…", "订单号 / 特殊说明…"), text: $note, axis: .vertical)'),
    ('.navigationTitle("New Signing")', '.navigationTitle(L("New Signing", "新签署单"))'),
    ('Button("Cancel") { dismiss() }', 'Button(L("Cancel", "取消")) { dismiss() }'),
    ('Button("Save") { save() }', 'Button(L("Save", "保存")) { save() }'),
    # 本地通知
    ('content.title = "签署提醒"', 'content.title = L("Signing reminder", "签署提醒")'),
    ('content.body = "\\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60) 小时" : "\\(remindMinutesBefore) 分钟")后出发（桌上 \\(minutes) 分钟 + 车程 \\(buffer) 分钟）。带齐耗材工具。"',
     'content.body = L("Leave in \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60)h" : "\\(remindMinutesBefore) min") — \\(minutes) min at table + \\(buffer) min drive. Bring supplies & tools.", "\\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60) 小时" : "\\(remindMinutesBefore) 分钟")后出发（桌上 \\(minutes) 分钟 + 车程 \\(buffer) 分钟）。带齐耗材工具。")'),
    # ClientEditor
    ('TextField("Title company / signing service", text: $company)', 'TextField(L("Title company / signing service", "标题公司 / 签约服务公司"), text: $company)'),
    ('Picker("Client type", selection: $isBusiness)', 'Picker(L("Client type", "客户类型"), selection: $isBusiness)'),
    ('Text("Business (30-day follow-up)").tag(true)', 'Text(L("Business (30-day follow-up)", "企业（30天回访）")).tag(true)'),
    ('Text("Individual (90-day follow-up)").tag(false)', 'Text(L("Individual (90-day follow-up)", "个人（90天回访）")).tag(false)'),
    ('TextField("Contact (loan officer / coordinator)", text: $contactName)', 'TextField(L("Contact (loan officer / coordinator)", "联系人（贷款官/协调员）"), text: $contactName)'),
    ('TextField("Phone", text: $phone)', 'TextField(L("Phone", "电话"), text: $phone)'),
    ('TextField("Email", text: $email)', 'TextField(L("Email", "邮箱"), text: $email)'),
    ('TextField("Payment terms / preferences / notes…", text: $notes, axis: .vertical)',
     'TextField(L("Payment terms / preferences / notes…", "结算周期 / 偏好 / 备注…"), text: $notes, axis: .vertical)'),
    ('.navigationTitle(existing == nil ? "New Client" : "Edit Client")',
     '.navigationTitle(existing == nil ? L("New Client", "新客户") : L("Edit Client", "编辑客户"))'),
    # CommissionEditor
    ('Section("Notary Commission")', 'Section(L("Notary Commission", "公证委托证"))'),
    ('TextField("Commission holder name", text: $holderName)', 'TextField(L("Commission holder name", "持证人姓名"), text: $holderName)'),
    ('TextField("State (CA / TX / FL…)", text: $state)', 'TextField(L("State (CA / TX / FL…)", "州（CA / TX / FL…）"), text: $state)'),
    ('TextField("Commission number", text: $commissionNumber)', 'TextField(L("Commission number", "委托证编号"), text: $commissionNumber)'),
    ('DatePicker("Expiry date", selection: $expiry, displayedComponents: .date)', 'DatePicker(L("Expiry date", "到期日"), selection: $expiry, displayedComponents: .date)'),
    ('Label("Expired \\(-days) days ago", systemImage: "exclamationmark.triangle.fill")',
     'Label(L("Expired \\(-days) days ago", "已过期 \\(-days) 天"), systemImage: "exclamationmark.triangle.fill")'),
    ('Label("Expires in \\(days) days — start renewal", systemImage: "exclamationmark.triangle")',
     'Label(L("Expires in \\(days) days — start renewal", "\\(days) 天后到期——开始续证"), systemImage: "exclamationmark.triangle")'),
    ('Label("Expires in \\(days) days", systemImage: "checkmark.circle")',
     'Label(L("Expires in \\(days) days", "\\(days) 天后到期"), systemImage: "checkmark.circle")'),
    ('.navigationTitle("Commission")', '.navigationTitle(L("Commission", "委托证"))'),
    ('Button("保存") {', 'Button(L("Save", "保存")) {'),
]

for i, (old, new) in enumerate(pairs):
    n = src.count(old)
    assert n >= 1, f"第{i+1}处未命中: {old[:70]!r}"
    src = src.replace(old, new)
open(p, "w", encoding="utf-8", newline="\n").write(src)
print(f"Editors.swift: {len(pairs)}处全中")
