# -*- coding: utf-8 -*-
"""补丁 v2：跳过已完成的耗材段（刚正则插过），只补 states/picker/reminder/save 四段"""
import io, re

f = 'NotaryTrack/Editors.swift'
src = io.open(f, encoding='utf-8').read()

# ===== 1. states 块（加 supplyCost/remindMe/remindHoursBefore/notaryFeeHint + applyTypeDefaults）=====
if 'remindMe' not in src:
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
    print('1. states OK')

# ===== 2. Picker onChange =====
if 'applyTypeDefaults(t)' not in src:
    # 正则锚定类型 Picker 块尾
    pat = re.compile(r'(Picker\("类型", selection: \$serviceType\) \{\n(?:.*?\n)*?    \})')
    m = pat.search(src)
    assert m, 'picker regex miss'
    insert = m.group(1) + """
                    .onChange(of: serviceType) { t in
                        applyTypeDefaults(t)
                    }
                    Text("该类型建议：桌上约 \\(minutes) 分钟 · 公证费 \\(notaryFeeHint)")
                        .font(.caption)
                        .foregroundColor(.secondary)"""
    src = src[:m.start()] + insert + src[m.end():]
    print('2. picker OK')

# ===== 3. 提醒区（备注 Section 前插）=====
if '提前提醒我出发' not in src:
    old_note = """                Section("备注") {
                    TextField("订单号/特殊要求…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }"""
    new_note = """                // 健哥令②：闹钟提醒（开关+提前量）
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
                }"""
    assert old_note in src, 'note section miss'
    src = src.replace(old_note, new_note)
    print('3. reminder section OK')

# ===== 4. save() 写 supplyCost + 通知调度 =====
if 'scheduleLocalReminder' not in src:
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
            content.title = "签署提醒"
            content.body = "\\(remindHoursBefore) 小时后出发（桌上 \\(minutes) 分钟 + 车程 \\(buffer) 分钟）。带齐耗材工具。"
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
    print('4. save+reminder OK')

# ===== 5. import =====
if 'import UserNotifications' not in src:
    src = src.replace('import SwiftUI', 'import SwiftUI\nimport UserNotifications')
    print('5. import OK')

io.open(f, 'w', encoding='utf-8').write(src)
print('ALL PATCHES DONE')
