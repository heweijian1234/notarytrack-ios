# -*- coding: utf-8 -*-
"""英文回改第二批——剩余 87 处（NotaryTrackApp 31 + Editors 56）"""
import io, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# ===== NotaryTrackApp.swift =====
f = 'NotaryTrack/NotaryTrackApp.swift'
src = io.open(f, encoding='utf-8').read()
R1 = [
    ('Label("跑趟费 $"', 'Label("Trip fee $"'),
    ('Text("· 净利 $"', 'Text("· Net $"'),
    ('Text("· 跑趟费 $"', 'Text("· Trip fee $"'),
    ('Text("逾期\\(s.unpaidDays)天")', 'Text("Overdue \\(s.unpaidDays)d")'),
    ('StatCell("净利", "$"', 'StatCell("Net", "$"'),
    ('StatCell("跑趟费", "$"', 'StatCell("Trip fees", "$"'),
    ('Label("公证费(免税) $"', 'Label("Notary (SE-exempt) $"'),
    ('Label("服务费 $"', 'Label("Service $"'),
    ('Label("预估自雇税 $"', 'Label("Est. SE tax $"'),
    ('Label("\\(monthSummary.unpaid) 单已签未收款")', 'Label("\\(monthSummary.unpaid) signings unpaid")'),
    ('StatCell("单数", "', 'StatCell("Signings", "'),
    ('StatCell("净利", "$"', 'StatCell("Net", "$"'),
    ('StatCell("跑趟费", "$"', 'StatCell("Trip fees", "$"'),
    ('Label("公证费(免税) $" + String(format: "%.0f", yearSummary.notaryPortion), systemImage: "checkmark.shield")', 'Label("Notary (SE-exempt) $" + String(format: "%.0f", yearSummary.notaryPortion), systemImage: "checkmark.shield")'),
    ('Label("服务费 $" + String(format: "%.0f", yearSummary.taxablePortion), systemImage: "doc.text")', 'Label("Service $" + String(format: "%.0f", yearSummary.taxablePortion), systemImage: "doc.text")'),
    ('Text("· 净利 $" + String(format: "%.0f", s.netProfit(supplyCost: 2.50)))', 'Text("· Net $" + String(format: "%.0f", s.netProfit(supplyCost: 2.50)))'),
    ('Text("· 跑趟费 $" + String(format: "%.0f", s.tripFee))', 'Text("· Trip fee $" + String(format: "%.0f", s.tripFee))'),
    ('Label("\\(current.noShowCount) 次没成功记录", systemImage: "exclamationmark.triangle")', 'Label("\\(current.noShowCount) no-shows on record", systemImage: "exclamationmark.triangle")'),
    ('Label("\\(current.noShowCount) 次没成功", systemImage: "exclamationmark.triangle")', 'Label("\\(current.noShowCount) no-shows", systemImage: "exclamationmark.triangle")'),
    ('Text("咬人").font(.caption2)', 'Text("BITES").font(.caption2)'),
    ('Text("谨慎").font(.caption2)', 'Text("CARE").font(.caption2)'),
    ('Label("状态：\\(current.status.display)", systemImage:', 'Label("Status: \\(current.status.display)", systemImage:'),
    ('Label("爱吃：\\(current.favoriteFood)", systemImage: "fork.knife")', 'Label("Loves: \\(current.favoriteFood)", systemImage: "fork.knife")'),
    ('Label("爱摸：\\(current.favoritePetting)", systemImage: "hand.tap")', 'Label("Loves: \\(current.favoritePetting)", systemImage: "hand.tap")'),
    ('Section("主人")', 'Section("Owner")'),
    ('Section("喜好（沟通时用）")', 'Section("Favorites")'),
    ('Section("美容配方")', 'Section("Grooming Recipe")'),
    ('Section("特殊工具携带")', 'Section("Special Tools")'),
    ('Section("健康与脾气")', 'Section("Health & Temperament")'),
    ('Label("疫苗", systemImage: "syringe")', 'Label("Vaccine", systemImage: "syringe")'),
    ('LabeledRow("借款合同", "\\(current.borrowDocs) 份")', 'LabeledRow("Loan docs", "\\(current.borrowDocs)")'),
    ('LabeledRow("信托文件", "\\(current.trustDocs) 份")', 'LabeledRow("Trust docs", "\\(current.trustDocs)")'),
    ('LabeledRow("其他", "\\(current.otherDocs) 份")', 'LabeledRow("Other", "\\(current.otherDocs)")'),
    ('LabeledRow("联系人", current.contactName)', 'LabeledRow("Contact", current.contactName)'),
    ('LabeledRow("费用", "$"', 'LabeledRow("Fee", "$"'),
    ('LabeledRow("状态", ["已约", "完成", "没来"][statusIndex])', 'LabeledRow("Status", ["Scheduled", "Done", "No-show"][statusIndex])'),
    ('LabeledRow("收款", current.paid ? "已收" : "未收")', 'LabeledRow("Payment", current.paid ? "Paid" : "Unpaid")'),
    ('Section("签署历史")', 'Section("History")'),
    ('Section("公证行为计数") {\n                LabeledRow("借款合同", "', 'Section("Notarial Acts") {\n                LabeledRow("Loan docs", "'),
    ('LabeledRow("信托文件", "', 'LabeledRow("Trust docs", "'),
    ('LabeledRow("其他", "', 'LabeledRow("Other", "'),
    ('Text("客户=标题公司/签约服务。记录联系人和结算习惯。")', 'Text("Clients are title companies / signing services. Track contacts and payment habits.")'),
    ('Text("本月签署单总结")', 'Text("Monthly Signing Summary")'),
    ('Section("签署历史")', 'Section("History")'),
    ('Section("备注") { Text(current.notes) }', 'Section("Notes") { Text(current.notes) }'),
    ('Text("已经提交审核了")', 'Text("Submitted for review")'),
    ('Text("没来").font(.caption2)', 'Text("No-show").font(.caption2)'),
]
miss = []
for old, new in R1:
    if old in src:
        src = src.replace(old, new)
    else:
        miss.append(old[:46])
io.open(f, 'w', encoding='utf-8').write(src)
for mmiss in miss:
    print('MISS R1:', mmiss)

# ===== Editors.swift =====
f2 = 'NotaryTrack/Editors.swift'
src2 = io.open(f2, encoding='utf-8').read()
R2 = [
    ('Section("客户")', 'Section("Client")'),
    ('Text("请先在「客户」页添加标题公司。")', 'Text("Add a client first (Clients tab).")'),
    ('Section("时间地点")', 'Section("Time & Place")'),
    ('Text("该类型建议：桌上约 \\(minutes) 分钟 · 公证费 \\(notaryFeeHint)")', 'Text("Suggested: ~\\(minutes) min at the table · notary fee \\(notaryFeeHint)")'),
    ('DatePicker("时间", selection: $date)', 'DatePicker("Date & time", selection: $date)'),
    ('TextField("签署地点（房产地址）", text: $address)', 'TextField("Signing location (property address)", text: $address)'),
    ('Stepper("桌上 \\(minutes) 分钟", value: $minutes, in: 15...240, step: 15)', 'Stepper("Table time \\(minutes) min", value: $minutes, in: 15...240, step: 15)'),
    ('Stepper("车程缓冲 \\(buffer) 分钟", value: $buffer, in: 0...60, step: 5)', 'Stepper("Drive buffer \\(buffer) min", value: $buffer, in: 0...60, step: 5)'),
    ('Toggle("提醒（闹钟）", isOn: $remindMe)', 'Toggle("Reminder (alert)", isOn: $remindMe)'),
    ('Text("提前 30 分钟").tag(30)', 'Text("30 min before").tag(30)'),
    ('Text("提前 45 分钟").tag(45)', 'Text("45 min before").tag(45)'),
    ('Text("提前 1 小时").tag(60)', 'Text("1 hour before").tag(60)'),
    ('Text("提前 2 小时").tag(120)', 'Text("2 hours before").tag(120)'),
    ('Text("提前 3 小时").tag(180)', 'Text("3 hours before").tag(180)'),
    ('Text("提前 4 小时").tag(240)', 'Text("4 hours before").tag(240)'),
    ('Text("提前 6 小时").tag(360)', 'Text("6 hours before").tag(360)'),
    ('Text("提前 10 小时").tag(600)', 'Text("10 hours before").tag(600)'),
    ('Text("预约前 \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60) 小时" : "\\(remindMinutesBefore) 分钟")通知你出发。")', 'Text("Notified \\(remindMinutesBefore >= 60 ? "\\(remindMinutesBefore / 60)h" : "\\(remindMinutesBefore) min") before — leave time for the \\(buffer) min drive.")'),
    ('Section("费用与里程")', 'Section("Fees & Mileage")'),
    ('Text("总费用 $")', 'Text("Total fee $")'),
    ('Text("其中公证费 $（免税）")', 'Text("Notary portion $ (SE-exempt)")'),
    ('Text("跑趟费 $")', 'Text("Trip fee $")'),
    ('Text("公证费部分免自雇税（IRS §1402）· 净利已含耗材成本")', 'Text("Notary portion is exempt from self-employment tax (IRC §1402). Net profit includes supply cost.")'),
    ('Section("公证行为计数")', 'Section("Notarial Acts")'),
    ('Stepper("借款合同 \\(borrowDocs) 份", value: $borrowDocs, in: 0...20)', 'Stepper("Loan docs: \\(borrowDocs)", value: $borrowDocs, in: 0...20)'),
    ('Stepper("信托文件 \\(trustDocs) 份", value: $trustDocs, in: 0...20)', 'Stepper("Other docs: \\(trustDocs)", value: $trustDocs, in: 0...20)'),
    ('Stepper("其他 \\(otherDocs) 份", value: $otherDocs, in: 0...20)', 'Stepper("Misc acts: \\(otherDocs)", value: $otherDocs, in: 0...20)'),
    ('Section("备注") {\n                    TextField("订单号/特殊要求…", text: $note, axis: .vertical)', 'Section("Notes") {\n                    TextField("Order # / special instructions…", text: $note, axis: .vertical)'),
    ('.navigationTitle("新建签署单")', '.navigationTitle("New Signing")'),
    ('TextField("标题公司/签约服务名", text: $company)', 'TextField("Title company / signing service", text: $company)'),
    ('Picker("客户类型", selection: $isBusiness) {\n                        Text("企业（30天回访）").tag(true)\n                        Text("个人（90天回访）").tag(false)\n                    }', 'Picker("Client type", selection: $isBusiness) {\n                        Text("Business (30-day follow-up)").tag(true)\n                        Text("Individual (90-day follow-up)").tag(false)\n                    }'),
    ('TextField("联系人（贷款官/协调员）", text: $contactName)', 'TextField("Contact (loan officer / coordinator)", text: $contactName)'),
    ('TextField("电话", text: $phone)', 'TextField("Phone", text: $phone)'),
    ('TextField("邮箱", text: $email)', 'TextField("Email", text: $email)'),
    ('TextField("结算周期/偏好/注意事项…", text: $notes, axis: .vertical)', 'TextField("Payment terms / preferences / notes…", text: $notes, axis: .vertical)'),
    ('.navigationTitle(existing == nil ? "新建客户" : "编辑客户")', '.navigationTitle(existing == nil ? "New Client" : "Edit Client")'),
    ('Button("取消") { dismiss() }', 'Button("Cancel") { dismiss() }'),
    ('Button("保存") { save() }', 'Button("Save") { save() }'),
    ('TextField("委托证 holder name", text: $holderName)', 'TextField("Commission holder name", text: $holderName)'),
    ('Section("委托证（Notary Commission）")', 'Section("Notary Commission")'),
    ('TextField("持证人姓名", text: $holderName)', 'TextField("Commission holder name", text: $holderName)'),
    ('TextField("州（如 CA / TX / FL）", text: $state)', 'TextField("State (CA / TX / FL…)", text: $state)'),
    ('TextField("证号", text: $commissionNumber)', 'TextField("Commission number", text: $commissionNumber)'),
    ('DatePicker("到期日", selection: $expiry, displayedComponents: .date)', 'DatePicker("Expiry date", selection: $expiry, displayedComponents: .date)'),
    ('Label("已过期 \\(-days) 天", systemImage: "exclamationmark.triangle.fill")', 'Label("Expired \\(-days) days ago", systemImage: "exclamationmark.triangle.fill")'),
    ('Label("\\(days) 天后到期——建议开始续证", systemImage: "exclamationmark.triangle")', 'Label("Expires in \\(days) days — start renewal", systemImage: "exclamationmark.triangle")'),
    ('Label("\\(days) 天后到期", systemImage: "checkmark.circle")', 'Label("Expires in \\(days) days", systemImage: "checkmark.circle")'),
    ('.navigationTitle("委托证设置")', '.navigationTitle("Commission")'),
    ('Text("还没有客户")', 'Text("No clients yet")'),
    ('Text("客户=标题公司/签约服务。记录联系人和结算习惯。")', 'Text("Clients are title companies / signing services. Track contacts and payment habits.")'),
    ('LabeledRow("联系人", current.contactName)', 'LabeledRow("Contact", current.contactName)'),
    ('LabeledRow("时间", current.date.formatted(date: .long, time: .shortened))', 'LabeledRow("Date", current.date.formatted(date: .long, time: .shortened))'),
    ('LabeledRow("地点", current.address)', 'LabeledRow("Location", current.address)'),
    ('LabeledRow("费用", "$"', 'LabeledRow("Fee", "$"'),
    ('LabeledRow("状态", ["已约", "完成", "没来"][statusIndex])', 'LabeledRow("Status", ["Scheduled", "Done", "No-show"][statusIndex])'),
    ('LabeledRow("收款", current.paid ? "已收" : "未收")', 'LabeledRow("Payment", current.paid ? "Paid" : "Unpaid")'),
    ('LabeledRow("借款合同", "\\(current.borrowDocs) 份")', 'LabeledRow("Loan docs", "\\(current.borrowDocs)")'),
    ('LabeledRow("信托文件", "\\(current.trustDocs) 份")', 'LabeledRow("Trust docs", "\\(current.trustDocs)")'),
    ('LabeledRow("其他", "\\(current.otherDocs) 份")', 'LabeledRow("Other", "\\(current.otherDocs)")'),
    ('Section("公证行为计数") {\n                LabeledRow("借款合同", "', 'Section("Notarial Acts") {\n                LabeledRow("Loan docs", "'),
    ('Section("签署历史")', 'Section("History")'),
    ('Button(role: .destructive) {\n                            markUnpaid()\n                        } label: {\n                            Label("改回未收款", systemImage: "arrow.uturn.backward")\n                        }', 'Button(role: .destructive) {\n                            markUnpaid()\n                        } label: {\n                            Label("Mark Unpaid", systemImage: "arrow.uturn.backward")\n                        }'),
    ('Button {\n                            markPaid()\n                        } label: {\n                            Label("标记已收款（清逾期）", systemImage: "checkmark.seal.fill")\n                        }', 'Button {\n                            markPaid()\n                        } label: {\n                            Label("Mark Paid (clear overdue)", systemImage: "checkmark.seal.fill")\n                        }'),
    ('Text("没有来")', 'Text("No-show")'),
]
miss2 = []
for old, new in R2:
    if old in src2:
        src2 = src2.replace(old, new)
    else:
        miss2.append(old[:46])
io.open(f2, 'w', encoding='utf-8').write(src2)
for mmiss in miss2:
    print('MISS R2:', mmiss)
print('part2 done')
