# -*- coding: utf-8 -*-
"""v1.5 补丁②：NotaryTrackApp.swift + Store.swift 全量双语（健哥11-24令，跟随系统语言）"""
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios"

def patch(path, pairs):
    p = ROOT + "\\" + path
    src = open(p, encoding="utf-8").read()
    for i, (old, new) in enumerate(pairs):
        n = src.count(old)
        assert n >= 1, f"{path} 第{i+1}处未命中: {old[:70]!r}"
        src = src.replace(old, new)
    open(p, "w", encoding="utf-8", newline="\n").write(src)
    print(f"{path}: {len(pairs)}处全中")

patch("Shared\\Store.swift", [
    ('case .loan: return "Loan Signing"', 'case .loan: return L("Loan Signing", "贷款签署")'),
    ('case .general: return "General Notary"', 'case .general: return L("General Notary", "普通公证")'),
    ('case .apostille: return "Apostille"', 'case .apostille: return L("Apostille", "海牙认证")'),
    ('case .hospital: return "Hospital/Facility"', 'case .hospital: return L("Hospital/Facility", "医院/机构")'),
    ('case .estate: return "Estate Planning"', 'case .estate: return L("Estate Planning", "遗产规划")'),
    ('case .other: return "Other"', 'case .other: return L("Other", "其他")'),
    ('switch self { case .scheduled: return "Scheduled"; case .done: return "Done"; case .noshow: return "No-show" }',
     'switch self { case .scheduled: return L("Scheduled", "已约"); case .done: return L("Done", "完成"); case .noshow: return L("No-show", "没来") }'),
])

patch("NotaryTrack\\NotaryTrackApp.swift", [
    # RootView tabs
    ('Label("Today", systemImage: "calendar")', 'Label(L("Today", "今日"), systemImage: "calendar")'),
    ('Label("Signings", systemImage: "doc.text")', 'Label(L("Signings", "签署单"), systemImage: "doc.text")'),
    ('Label("Clients", systemImage: "person.2")', 'Label(L("Clients", "客户"), systemImage: "person.2")'),
    ('Label("Me", systemImage: "person.crop.circle")', 'Label(L("Me", "我的"), systemImage: "person.crop.circle")'),
    # commissionWarn
    ('return "委托证已过期 \\(-days) 天——不能接单，快续！"',
     'return L("Commission expired \\(-days) days ago — no signings allowed. Renew now!", "委托证已过期 \\(-days) 天——不能接单，快续！")'),
    ('return "委托证 \\(days) 天后到期（\\(c.state)）——开始续证流程"',
     'return L("Commission expires in \\(days) days (\\(c.state)) — start renewal", "委托证 \\(days) 天后到期（\\(c.state)）——开始续证流程")'),
    # 今日空态
    ('Text("Your signing agent book")', 'Text(L("Your signing agent book", "你的公证签署台账"))'),
    ('Text("Add a client (title company) first, then log signings. Fees, trip fees, notarial acts — nothing missed.")',
     'Text(L("Add a client (title company) first, then log signings. Fees, trip fees, notarial acts — nothing missed.", "先加客户（标题公司），再记签署单。费用、跑趟费、公证行为——一样不漏。"))'),
    ('Section("Due for follow-up")', 'Section(L("Due for follow-up", "该回访了"))'),
    ('Text("\\(days) days since last signing (\\(threshold == 30 ? "business" : "individual") · \\(threshold)-day norm)")',
     'Text(L("\\(days) days since last signing (\\(threshold == 30 ? "business" : "individual") · \\(threshold)-day norm)", "\\(days) 天没新单（\\(threshold == 30 ? "企业" : "个人") · \\(threshold)天标准）"))'),
    ('Text("No signings yet — tap + to add.")', 'Text(L("No signings yet — tap + to add.", "还没有签署单——点右上角 + 添加。"))'),
    ('.navigationTitle("Today")', '.navigationTitle(L("Today", "今日"))'),
    ('Label("New Signing", systemImage: "plus")', 'Label(L("New Signing", "新签署单"), systemImage: "plus")'),
    ('Label("Commission", systemImage: "credentialing")', 'Label(L("Commission", "委托证"), systemImage: "credentialing")'),
    # 日期分组格式跟随语言
    ('''        df.dateFormat = "M月d日 EEEE"
        df.locale = Locale(identifier: "zh_CN")''',
     '''        if AppLang.current == .en {
            df.dateFormat = "MMM d EEEE"
            df.locale = Locale(identifier: "en_US")
        } else {
            df.dateFormat = "M月d日 EEEE"
            df.locale = Locale(identifier: "zh_CN")
        }'''),
    # SigningRow
    ('''        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")''',
     '''        f.timeStyle = .short
        f.locale = Locale(identifier: AppLang.current == .en ? "en_US" : "zh_CN")'''),
    ('"Unknown client"', 'L("Unknown client", "未知客户")'),
    ('Label("Trip fee $" + String(format: "%.0f", signing.tripFee), systemImage: "car")',
     'Label(L("Trip fee $", "跑趟费 $") + String(format: "%.0f", signing.tripFee), systemImage: "car")'),
    ('Label("Paid", systemImage: "checkmark.seal")', 'Label(L("Paid", "已收"), systemImage: "checkmark.seal")'),
    ('Label("Unpaid", systemImage: "hourglass")', 'Label(L("Unpaid", "未收"), systemImage: "hourglass")'),
    ('Label("Done", systemImage: "checkmark.circle.fill")', 'Label(L("Done", "完成"), systemImage: "checkmark.circle.fill")'),
    ('Label("No-show", systemImage: "xmark.circle")', 'Label(L("No-show", "没来"), systemImage: "xmark.circle")'),
    ('Label("Mark Paid", systemImage: "dollarsign.arrow.circlepath")', 'Label(L("Mark Paid", "标记已收"), systemImage: "dollarsign.arrow.circlepath")'),
    # SigningRowMetrics
    ('Text("· Trip fee $" + String(format: "%.0f", s.tripFee))', 'Text(L("· Trip fee $", "· 跑趟费 $") + String(format: "%.0f", s.tripFee))'),
    ('Text("· " + (s.paid ? "已收" : "未收"))', 'Text("· " + (s.paid ? L("Paid", "已收") : L("Unpaid", "未收")))'),
    # SigningRowHeader
    ('Text("No-show").font(.caption2)', 'Text(L("No-show", "没来")).font(.caption2)'),
    ('Text("Overdue \\(s.unpaidDays)d")', 'Text(L("Overdue \\(s.unpaidDays)d", "逾期\\(s.unpaidDays)天"))'),
    ('?? "未知"', '?? L("Unknown", "未知")'),
    # SigningListView 空态
    ('Text("No signings yet")', 'Text(L("No signings yet", "还没有签署单"))'),
    ('Text("Log your first signing: client, fee, mileage, notarial acts.")',
     'Text(L("Log your first signing: client, fee, notarial acts.", "记第一单：客户、费用、公证行为。"))'),
    ('Label("\\(monthSummary.overdueCount) overdue, totaling $\\(monthSummary.overdueAmount, specifier: "%.0f") (30+ days)",',
     'Label(L("\\(monthSummary.overdueCount) overdue, totaling $\\(monthSummary.overdueAmount, specifier: "%.0f") (30+ days)", "\\(monthSummary.overdueCount) 单逾期，合计 $\\(monthSummary.overdueAmount, specifier: "%.0f")（超30天）"),'),
    ('Section("This Month")', 'Section(L("This Month", "本月"))'),
    ('StatCell("Signings",', 'StatCell(L("Signings", "单数"),'),
    ('StatCell("Income",', 'StatCell(L("Income", "收入"),'),
    ('StatCell("Trip fees",', 'StatCell(L("Trip fees", "跑趟费"),'),
    ('Label("Notary (SE-exempt) $"', 'Label(L("Notary (SE-exempt) $", "公证费（免SE税）$")'),
    ('Label("Service $"', 'Label(L("Service $", "服务费 $")'),
    ('Label("Est. SE tax $" + String(format: "%.0f", monthSummary.taxablePortion * 0.153) + "（应税部分×15.3%）", systemImage: "percent")',
     'Label(L("Est. SE tax $", "预估SE税 $") + String(format: "%.0f", monthSummary.taxablePortion * 0.153) + L(" (taxable × 15.3%)", "（应税部分×15.3%）"), systemImage: "percent")'),
    ('Label("\\(monthSummary.unpaid) signings unpaid", systemImage: "exclamationmark.circle")',
     'Label(L("\\(monthSummary.unpaid) signings unpaid", "\\(monthSummary.unpaid) 单未收款"), systemImage: "exclamationmark.circle")'),
    ('Section("Year to Date")', 'Section(L("Year to Date", "今年累计"))'),
    ('Section("All Signings")', 'Section(L("All Signings", "全部签署单"))'),
    ('.navigationTitle("Signings")', '.navigationTitle(L("Signings", "签署单"))'),
    # SigningDetailView
    ('Section("Clients")', 'Section(L("Clients", "客户"))'),
    ('Section("This Signing")', 'Section(L("This Signing", "本单"))'),
    ('LabeledRow("Date",', 'LabeledRow(L("Date", "日期"),'),
    ('LabeledRow("Location",', 'LabeledRow(L("Location", "地点"),'),
    ('LabeledRow("Type",', 'LabeledRow(L("Type", "类型"),'),
    ('LabeledRow("Total fee",', 'LabeledRow(L("Total fee", "总费用"),'),
    ('LabeledRow("├ Notary (exempt)",', 'LabeledRow(L("├ Notary (exempt)", "├ 公证费（免税）"),'),
    ('LabeledRow("├ Service (taxable)",', 'LabeledRow(L("├ Service (taxable)", "├ 服务费（应税）"),'),
    ('LabeledRow("├ Trip fee",', 'LabeledRow(L("├ Trip fee", "├ 跑趟费"),'),
    ('LabeledRow("Status", ["Scheduled", "Done", "No-show"][statusIndex])',
     'LabeledRow(L("Status", "状态"), [L("Scheduled", "已约"), L("Done", "完成"), L("No-show", "没来")][statusIndex])'),
    ('LabeledRow("Payment", current.paid ? "Paid" : "Unpaid")',
     'LabeledRow(L("Payment", "收款"), current.paid ? L("Paid", "已收") : L("Unpaid", "未收"))'),
    ('LabeledRow("Overdue", "\\(current.unpaidDays) days unpaid")',
     'LabeledRow(L("Overdue", "逾期"), L("\\(current.unpaidDays) days unpaid", "\\(current.unpaidDays) 天未收"))'),
    ('Section("Notarial Acts")', 'Section(L("Notarial Acts", "公证行为"))'),
    ('LabeledRow("Loan docs",', 'LabeledRow(L("Loan docs", "借款文件"),'),
    ('LabeledRow("Trust docs",', 'LabeledRow(L("Trust docs", "信托文件"),'),
    ('LabeledRow("Other",', 'LabeledRow(L("Other", "其他"),'),
    ('Section("Payment")', 'Section(L("Payment", "收款"))'),
    ('Label("Mark Unpaid", systemImage: "arrow.uturn.backward")', 'Label(L("Mark Unpaid", "改回未收"), systemImage: "arrow.uturn.backward")'),
    ('Label("Mark Paid (clear overdue)", systemImage: "checkmark.seal.fill")', 'Label(L("Mark Paid (clear overdue)", "标记已收（清逾期）"), systemImage: "checkmark.seal.fill")'),
    ('Section("Notes")', 'Section(L("Notes", "备注"))'),
    ('.navigationTitle("Signing Details")', '.navigationTitle(L("Signing Details", "签署单详情"))'),
    # ClientListView
    ('Text("No clients yet")', 'Text(L("No clients yet", "还没有客户"))'),
    ('Text("Clients are title companies / signing services. Track contacts and payment habits.")',
     'Text(L("Clients are title companies / signing services. Track contacts and payment habits.", "客户=标题公司/签约服务公司。记联系人和付款习惯。"))'),
    ('Text("\\(c.noShowCount) no-shows")', 'Text(L("\\(c.noShowCount) no-shows", "\\(c.noShowCount) 次没来"))'),
    ('Text("\\(count) signings · \\(c.contactName.isEmpty ? "无联系人" : c.contactName)")',
     'Text(L("\\(count) signings · \\(c.contactName.isEmpty ? "no contact" : c.contactName)", "\\(count) 单 · \\(c.contactName.isEmpty ? "无联系人" : c.contactName)"))'),
    ('.navigationTitle("Clients")', '.navigationTitle(L("Clients", "客户"))'),
    # ClientDetailView
    ('return ("未评级（还没收过款）", .secondary)', 'return (L("Not rated (no payments yet)", "未评级（还没收过款）"), .secondary)'),
    ('return ("✅ 优选（平均 \\(Int(d)) 天付款）", .green)', 'return (L("✅ Preferred (avg \\(Int(d)) days to pay)", "✅ 优选（平均 \\(Int(d)) 天付款）"), .green)'),
    ('return ("⚠️ 注意（平均 \\(Int(d)) 天付款）", .orange)', 'return (L("⚠️ Watch (avg \\(Int(d)) days to pay)", "⚠️ 注意（平均 \\(Int(d)) 天付款）"), .orange)'),
    ('return ("🔴 拉黑观察（平均 \\(Int(d)) 天付款）", .red)', 'return (L("🔴 Blacklist-watch (avg \\(Int(d)) days to pay)", "🔴 拉黑观察（平均 \\(Int(d)) 天付款）"), .red)'),
    ('Section("Payment Behavior")', 'Section(L("Payment Behavior", "付款行为"))'),
    ('LabeledRow("Avg days to pay",', 'LabeledRow(L("Avg days to pay", "平均付款天数"),'),
    ('Section("Contact")', 'Section(L("Contact", "联系方式"))'),
    ('LabeledRow("Contact",', 'LabeledRow(L("Contact", "联系人"),'),
    ('Label("\\(current.noShowCount) no-shows on record", systemImage: "exclamationmark.triangle")',
     'Label(L("\\(current.noShowCount) no-shows on record", "记录在案：\\(current.noShowCount) 次没来"), systemImage: "exclamationmark.triangle")'),
    ('Section("Signing History")', 'Section(L("Signing History", "签署历史"))'),
    # FeedbackView
    ('Section("Feedback")', 'Section(L("Feedback", "反馈意见"))'),
    ('Text("Any errors? Anything clunky? Missing features? Just write it.")',
     'Text(L("Any errors? Anything clunky? Missing features? Just write it.", "有错？用着不顺？缺功能？直接写。"))'),
    ('Label(sent ? "已打开邮件——发送即完成反馈" : "发送反馈（走你的邮件）", systemImage: "paperplane.fill")',
     'Label(sent ? L("Mail opened — send to finish", "已打开邮件——发送即完成反馈") : L("Send feedback (via your mail)", "发送反馈（走你的邮件）"), systemImage: "paperplane.fill")'),
    ('Text("Feedback goes straight to the developer by email. Nothing is stored in the app.")',
     'Text(L("Feedback goes straight to the developer by email. Nothing is stored in the app.", "反馈通过邮件直达开发者，App不留任何数据。"))'),
    ('.navigationTitle("Me")', '.navigationTitle(L("Me", "我的"))'),
    # OverdueList
    ('LabeledRow("Overdue signings",', 'LabeledRow(L("Overdue signings", "逾期单数"),'),
    ('LabeledRow("Total overdue",', 'LabeledRow(L("Total overdue", "逾期总额"),'),
    ('Section("Process Each")', 'Section(L("Process Each", "逐单处理"))'),
    ('.navigationTitle("Overdue")', '.navigationTitle(L("Overdue", "逾期"))'),
    ('Text("Overdue \\(signing.unpaidDays) days")', 'Text(L("Overdue \\(signing.unpaidDays) days", "逾期 \\(signing.unpaidDays) 天"))'),
    ('Label("Mark Paid", systemImage: "checkmark.seal.fill")', 'Label(L("Mark Paid", "标记已收"), systemImage: "checkmark.seal.fill")'),
    # 导出 signingText
    ('l.append("【签署单】\\(client?.company ?? "未知客户")")',
     'l.append(L("【Signing】\\(client?.company ?? L("Unknown client", "未知客户"))", "【签署单】\\(client?.company ?? "未知客户")"))'),
    ('l.append("时间：\\(df.string(from: s.date))")', 'l.append(L("Time: \\(df.string(from: s.date))", "时间：\\(df.string(from: s.date))"))'),
    ('l.append("地点：\\(s.address)")', 'l.append(L("Location: \\(s.address)", "地点：\\(s.address)"))'),
    ('l.append("Type: " + s.serviceType.display)', 'l.append(L("Type: ", "类型：") + s.serviceType.display)'),
    ('l.append("总费用：$" + String(format: "%.0f", s.fee) + "（公证费免税 $" + String(format: "%.0f", s.notaryFeePortion) + " + 服务费应税 $" + String(format: "%.0f", s.taxablePortion) + "）")',
     'l.append(L("Total: $", "总费用：$") + String(format: "%.0f", s.fee) + L(" (notary SE-exempt $", "（公证费免税 $") + String(format: "%.0f", s.notaryFeePortion) + L(" + service taxable $", " + 服务费应税 $") + String(format: "%.0f", s.taxablePortion) + L(")", "）"))'),
    ('l.append("跑趟费：$" + String(format: "%.0f", s.tripFee))', 'l.append(L("Trip fee: $", "跑趟费：$") + String(format: "%.0f", s.tripFee))'),
    ('l.append("状态：\\(s.status == .done ? "完成" : s.status == .noshow ? "没成功" : "已约") · \\(s.paid ? "已收" : "未收")")',
     'l.append(L("Status: \\(s.status == .done ? "Done" : s.status == .noshow ? "No-show" : "Scheduled") · \\(s.paid ? "Paid" : "Unpaid")", "状态：\\(s.status == .done ? "完成" : s.status == .noshow ? "没成功" : "已约") · \\(s.paid ? "已收" : "未收")"))'),
    ('l.append("公证行为：借款 \\(s.borrowDocs) / 信托 \\(s.trustDocs) / 其他 \\(s.otherDocs)")',
     'l.append(L("Notarial acts: loan \\(s.borrowDocs) / trust \\(s.trustDocs) / other \\(s.otherDocs)", "公证行为：借款 \\(s.borrowDocs) / 信托 \\(s.trustDocs) / 其他 \\(s.otherDocs)"))'),
    ('l.append("备注：\\(s.note)")', 'l.append(L("Note: \\(s.note)", "备注：\\(s.note)"))'),
    # 导出 monthText
    ('l.append("【本月签署单总结】\\(df.string(from: Date()))")',
     'l.append(L("【Monthly Signing Summary】\\(df.string(from: Date()))", "【本月签署单总结】\\(df.string(from: Date()))"))'),
    ('l.append("单数：\\(done.count)")', 'l.append(L("Signings: \\(done.count)", "单数：\\(done.count)"))'),
    ('l.append("总收入：$" + String(format: "%.0f", income) )', 'l.append(L("Total income: $", "总收入：$") + String(format: "%.0f", income) )'),
    ('l.append("  其中公证费（SE 免税）：$" + String(format: "%.0f", notary) )',
     'l.append(L("  Notary portion (SE-exempt): $", "  其中公证费（SE 免税）：$") + String(format: "%.0f", notary) )'),
    ('l.append("  其中服务费（应税）：$" + String(format: "%.0f", income - notary) )',
     'l.append(L("  Service portion (taxable): $", "  其中服务费（应税）：$") + String(format: "%.0f", income - notary) )'),
    ('l.append("⚠️ 未收款 \\(unpaid.count) 单，合计 $" + String(format: "%.0f", unpaid.reduce(0) { $0 + $1.fee }) + "：")',
     'l.append(L("⚠️ Unpaid \\(unpaid.count) signings, totaling $", "⚠️ 未收款 \\(unpaid.count) 单，合计 $") + String(format: "%.0f", unpaid.reduce(0) { $0 + $1.fee }) + L(":", "："))'),
    ('+ "（\\(u.unpaidDays) 天）")', '+ L(" (\\(u.unpaidDays) days)", "（\\(u.unpaidDays) 天）"))'),
    ('l.append("——逐单明细——")', 'l.append(L("—— Per signing ——", "——逐单明细——"))'),
    ('+ " " + (s.paid ? "已收" : "未收"))', '+ " " + (s.paid ? L("Paid", "已收") : L("Unpaid", "未收")))'),
    # 月历
    ('''        df.dateFormat = "yyyy年M月"
        df.locale = Locale(identifier: "zh_CN")''',
     '''        if AppLang.current == .en {
            df.dateFormat = "MMMM yyyy"
            df.locale = Locale(identifier: "en_US")
        } else {
            df.dateFormat = "yyyy年M月"
            df.locale = Locale(identifier: "zh_CN")
        }'''),
    ('let weekdays = ["日", "一", "二", "三", "四", "五", "六"]',
     'let weekdays = AppLang.current == .en ? ["S", "M", "T", "W", "T", "F", "S"] : ["日", "一", "二", "三", "四", "五", "六"]'),
])
print("主文件+Store 双语完成")
