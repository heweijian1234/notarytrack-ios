# -*- coding: utf-8 -*-
"""NotaryTrack 编辑器 v1.2 补丁：耗材自填+提醒开关+类型联动（健哥五条反馈的②④）"""
import io

f = 'NotaryTrack/Editors.swift'
src = io.open(f, encoding='utf-8').read()

# ===== 1. states 块 =====
old_states = """    @State private var clientId: UUID?
    @State private var date = Date()
    @State private var address = ""
    @State private var fee = 100.0
    @State private var notaryFeePortion = 0.0
    @State private var tripFee = 0.0
    @State private var mileage = 0.0
    @State private var minutes = 60
    @State private var buffer = 15
    @State private var serviceType: ServiceType = .loan
    @State private var borrowDocs = 1
    @State private var trustDocs = 0
    @State private var otherDocs = 0
    @State private var note = \"\""""
new_states = """    @State private var clientId: UUID?
    @State private var date = Date()
    @State private var address = ""
    @State private var fee = 100.0
    @State private var notaryFeePortion = 0.0
    @State private var tripFee = 0.0
    @State private var mileage = 0.0
    @State private var minutes = 60
    @State private var buffer = 15
    @State private var serviceType: ServiceType = .loan
    @State private var borrowDocs = 1
    @State private var trustDocs = 0
    @State private var otherDocs = 0
    @State private var supplyCost = 2.50      // 健哥令②：耗材成本自填
    @State private var remindMe = true        // 健哥令②：提醒开关
    @State private var remindHoursBefore = 2  // 提前小时数
    @State private var notaryFeeHint = "打包价通常 $0"
    @State private var note = \"\"

    // 健哥令④：类型联动——选类型给建议默认值
    private func applyTypeDefaults(_ t: ServiceType) {
        switch t {
        case .loan: minutes = 60
        case .general: minutes = 15
        case .apostille: minutes = 30
        case .hospital: minutes = 30
        case .estate: minutes = 45
        case .other: minutes = 30
        }
        notaryFeeHint = (t == .general || t == .hospital || t == .estate) ? "每签 $10-25（按州价）" : "打包价通常 $0"
    }"""
assert old_states in src, 'states miss'
src = src.replace(old_states, new_states)

# ===== 2. Picker onChange 联动 =====
old_picker = """                    Picker("类型", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \\.self) { t in
                            Text("\\(t.emoji) \\(t.rawValue)").tag(t)
                        }
                    }"""
new_picker = old_picker + """
                    .onChange(of: serviceType) { t in
                        applyTypeDefaults(t)
                    }
                    Text("该类型建议：桌上约 \\(minutes) 分钟 · 公证费 \\(notaryFeeHint)")
                        .font(.caption)
                        .foregroundColor(.secondary)"""
assert old_picker in src, 'picker miss'
src = src.replace(old_picker, new_picker)

# ===== 3. 耗材字段（费用区尾部）=====
old_tax_note = """                    Text("公证费部分免自雇税（IRS §1402）· 里程按 IRS 标准可抵税（$\\(mileage * 0.67, specifier: \\"%.0f\\")）")
                        .font(.caption)
                        .foregroundColor(.secondary)"""
new_tax_note = """                    // 健哥令②：耗材成本自填
                    HStack {
                        Text("耗材成本 $（打印/纸/墨）")
                        TextField("2.5", value: $supplyCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("公证费部分免自雇税（IRS §1402）· 里程按 IRS 标准可抵税（$\\(mileage * 0.67, specifier: \\"%.0f\\")）· 净利按含耗材计算")
                        .font(.caption)
                        .foregroundColor(.secondary)"""
assert old_tax_note in src, 'tax note miss'
src = src.replace(old_tax_note, new_tax_note)

# ===== 4. 提醒区（备注前插入）=====
old_note_section = """                Section("备注") {
                    TextField("订单号/特殊要求…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新建签署单")"""
new_note_section = """                // 健哥令②：闹钟提醒（开关+提前量）
                Section("提醒（闹钟）") {
                    Toggle("提前提醒我出发", isOn: $remindMe)
                    if remindMe {
                        Picker("提前", selection: $remindHoursBefore) {
                            Text("提前 1 小时").tag(1)
                            Text("提前 2 小时").tag(2)
                            Text("提前 3 小时").tag(3)
                            Text("提前 4 小时").tag(4)
                            Text("提前 6 小时").tag(6)
                            Text("提前 10 小时").tag(10)
                        }
                        Text("预约前 \\(remindHoursBefore) 小时通知你出发（桌上 \\(minutes) 分钟 + 车程 \\(buffer) 分钟）。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Section("备注") {
                    TextField("订单号/特殊要求…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新建签署单")"""
assert old_note_section in src, 'note section miss'
src = src.replace(old_note_section, new_note_section)

# ===== 5. save() 加 supplyCost 落盘 + 通知调度 =====
old_save = """    private func save() {
        guard let cid = clientId else { return }
        data.signings.append(Signing(clientId: cid, date: date, address: address, fee: fee,
                                     notaryFeePortion: notaryFeePortion, tripFee: tripFee,
                                     mileage: mileage, minutes: minutes, driveBufferMinutes: buffer,
                                     serviceType: serviceType, borrowDocs: borrowDocs,
                                     trustDocs: trustDocs, otherDocs: otherDocs, note: note))
        Store.save(data)
        dismiss()
    }
}"""
new_save = """    private func save() {
        guard let cid = clientId else { return }
        data.signings.append(Signing(clientId: cid, date: date, address: address, fee: fee,
                                     notaryFeePortion: notaryFeePortion, tripFee: tripFee,
                                     mileage: mileage, minutes: minutes, driveBufferMinutes: buffer,
                                     serviceType: serviceType, borrowDocs: borrowDocs,
                                     trustDocs: trustDocs, otherDocs: otherDocs, note: note))
        data.settings.supplyCostPerSigning = supplyCost   // 记住耗材单价
        Store.save(data)
        scheduleLocalReminder()
        dismiss()
    }

    /// 本地通知：预约前 remindHoursBefore 小时
    private func scheduleLocalReminder() {
        guard remindMe else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let triggerDate = date.addingTimeInterval(-Double(remindHoursBefore) * 3600)
            guard triggerDate > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = L("Signing reminder", "签署提醒")
            content.body = AppLang.current == .en
                ? "Leave in \\(remindHoursBefore)h for the \\(minutes + buffer) min signing (drive \\(buffer) min). Bring supplies."
                : "\\(remindHoursBefore) 小时后出发（桌上 \\(minutes) 分钟 + 车程 \\(buffer) 分钟）。带齐耗材工具。"
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(req)
        }
    }
}"""
assert old_save in src, 'save miss'
src = src.replace(old_save, new_save)

# ===== 6. import UserNotifications =====
if 'import UserNotifications' not in src:
    src = src.replace('import SwiftUI', 'import SwiftUI\nimport UserNotifications')

io.open(f, 'w', encoding='utf-8').write(src)
print('editor v1.2 patched: supply/reminder/type-defaults')
