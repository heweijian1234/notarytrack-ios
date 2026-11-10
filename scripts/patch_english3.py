# -*- coding: utf-8 -*-
"""英文回改第三批——剩余 24 处"""
import io

R = [
    # NotaryTrackApp.swift
    ('NotaryTrack/NotaryTrackApp.swift', 'Label("\\(monthSummary.unpaid) 单已签未收款")', 'Label("\\(monthSummary.unpaid) signings unpaid")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Section("客户")', 'Section("Clients")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Section("本单")', 'Section("This Signing")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("类型", current.serviceType.emoji + " " + current.serviceType.rawValue)', 'LabeledRow("Type", current.serviceType.display)'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("总费用", "$"', 'LabeledRow("Total fee", "$"'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("└ 公证费(免税)", "$"', 'LabeledRow("├ Notary (exempt)", "$"'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("└ 服务费(应税)", "$"', 'LabeledRow("├ Service (taxable)", "$"'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("└ 跑趟费", "$"', 'LabeledRow("├ Trip fee", "$"'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("净利(扣耗材)", "$"', 'LabeledRow("Net (after supplies)", "$"'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("逾期", "\\(current.unpaidDays) 天未收")', 'LabeledRow("Overdue", "\\(current.unpaidDays) days unpaid")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Section("收款处理")', 'Section("Payment")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Text("\\(c.noShowCount) 次改期")', 'Text("\\(c.noShowCount) no-shows")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Text("\\(count) 单 · \\(c.contactName.isEmpty ?', 'Text("\\(count) signings · \\(c.contactName.isEmpty ?'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Section("付款表现")', 'Section("Payment Behavior")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'LabeledRow("平均付款天数", "\\(Int(d)) 天")', 'LabeledRow("Avg days to pay", "\\(Int(d))")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Section("反馈意见")', 'Section("Feedback")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Text("哪里出现了错误？用着哪里不顺？缺什么功能？直接写。")', 'Text("Any errors? Anything clunky? Missing features? Just write it.")'),
    ('NotaryTrack/NotaryTrackApp.swift', 'Text("已经提交审核了")', 'Text("Submitted for review")'),
    # Editors.swift
    ('NotaryTrack/Editors.swift', 'Picker("客户", selection: $clientId)', 'Picker("Client", selection: $clientId)'),
    ('NotaryTrack/Editors.swift', 'Picker("类型", selection: $serviceType)', 'Picker("Type", selection: $serviceType)'),
    ('NotaryTrack/Editors.swift', 'Picker("提前", selection: $remindMinutesBefore)', 'Picker("Remind me", selection: $remindMinutesBefore)'),
    ('NotaryTrack/Editors.swift', 'Text("耗材成本 $（打印/纸/墨）")', 'Text("Supplies $ (print/paper/ink)")'),
    ('NotaryTrack/Editors.swift', 'Section("联系")', 'Section("Contact")'),
    ('NotaryTrack/Editors.swift', 'Section("备注")', 'Section("Notes")'),
    ('NotaryTrack/Editors.swift', 'Button("保存") { save() }', 'Button("Save") { save() }'),
]
for f, old, new in R:
    src = io.open(f, encoding='utf-8').read()
    if old in src:
        src = src.replace(old, new)
        io.open(f, 'w', encoding='utf-8').write(src)
    else:
        print('MISS:', f.split("/")[-1], old[:40])
print('part3 done')
