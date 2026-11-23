import SwiftUI
import UserNotifications

// MARK: - 签署单编辑器（新建/编辑）——费用/里程/行为计数/状态

struct SigningEditor: View {
    @Binding var data: Store.Data
    let preselectedClientId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var clientId: UUID?
    @State private var date = Date()
    @State private var address = ""
    @State private var fee = 0.0              // 健哥令①：不预填
    @State private var notaryFeePortion = 0.0
    @State private var tripFee = 0.0
    @State private var minutes = 60
    @State private var buffer = 15
    @State private var serviceType: ServiceType = .loan
    @State private var borrowDocs = 0         // 健哥令①：默认 0
    @State private var trustDocs = 0
    @State private var otherDocs = 0
    @State private var remindMe = false       // 健哥令①：默认关，用户自己开
    @State private var remindMinutesBefore = 30 // 健哥令①：分钟制（30/45/60/120/180/240/360/600）
    @State private var notaryFeeHint = L("Flat fee usually $0", "打包价通常 $0")
    @State private var note = ""

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
        notaryFeeHint = (t == .general || t == .hospital || t == .estate) ? L("$10-25 per signature (state fee)", "每签 $10-25（按州价）") : L("Flat fee usually $0", "打包价通常 $0")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L("Client", "客户")) {
                    if data.clients.isEmpty {
                        Text(L("Add a client first (Clients tab).", "先加客户（客户页）。"))
                            .font(.footnote)
                            .foregroundColor(.orange)
                    } else {
                        Picker(L("Client", "客户"), selection: $clientId) {
                            ForEach(data.clients) { c in
                                Text(c.company).tag(Optional(c.id))
                            }
                        }
                    }
                }
                Section(L("Time & Place", "时间与地点")) {
                    // A8 服务类型
                    Picker(L("Type", "类型"), selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { t in
                            Text("\(t.emoji) \(t.display)").tag(t)
                        }
                    }
                    .onChange(of: serviceType) { t in
                        applyTypeDefaults(t)
                    }
                    Text(L("Suggested: ~\(minutes) min at the table · notary fee \(notaryFeeHint)", "建议：桌上约 \(minutes) 分钟 · 公证费 \(notaryFeeHint)"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker(L("Date & time", "日期时间"), selection: $date)
                    TextField(L("Signing location (property address)", "签署地点（房产地址）"), text: $address)
                    Stepper(L("Table time \(minutes) min", "桌上 \(minutes) 分钟"), value: $minutes, in: 15...240, step: 15)
                    // 健哥令①：闹钟放车程缓冲下面
                    Stepper(L("Drive buffer \(buffer) min", "车程缓冲 \(buffer) 分钟"), value: $buffer, in: 0...60, step: 5)
                    Toggle(L("Reminder (alert)", "提醒（闹钟）"), isOn: $remindMe)
                    if remindMe {
                        // 健哥令①：30/45 分钟加入
                        Picker(L("Remind me", "提前提醒"), selection: $remindMinutesBefore) {
                            Text(L("30 min before", "提前30分钟")).tag(30)
                            Text(L("45 min before", "提前45分钟")).tag(45)
                            Text(L("1 hour before", "提前1小时")).tag(60)
                            Text(L("2 hours before", "提前2小时")).tag(120)
                            Text(L("3 hours before", "提前3小时")).tag(180)
                            Text(L("4 hours before", "提前4小时")).tag(240)
                            Text(L("6 hours before", "提前6小时")).tag(360)
                            Text(L("10 hours before", "提前10小时")).tag(600)
                        }
                        Text(L("Notified \(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60)h" : "\(remindMinutesBefore) min") before — leave time for the \(buffer) min drive.", "提前 \(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60) 小时" : "\(remindMinutesBefore) 分钟") 通知——留出 \(buffer) 分钟车程。"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Section(L("Fees", "费用")) {
                    HStack {
                        Text(L("Total fee $", "总费用 $"))
                        TextField("0", value: $fee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    // A4 公证费拆分
                    HStack {
                        Text(L("Notary portion $ (SE-exempt)", "公证费 $（免SE税）"))
                        TextField("0", value: $notaryFeePortion, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(L("Trip fee $", "跑趟费 $"))
                        TextField("0", value: $tripFee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(L("Notary portion is exempt from self-employment tax (IRC §1402).", "公证费部分免自雇税（IRC §1402）。"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section(L("Notarial Acts", "公证行为")) {
                    Stepper(L("Loan docs: \(borrowDocs)", "借款文件：\(borrowDocs)"), value: $borrowDocs, in: 0...20)
                    Stepper(L("Trust docs: \(trustDocs)", "信托文件：\(trustDocs)"), value: $trustDocs, in: 0...20)
                    Stepper(L("Misc acts: \(otherDocs)", "其他行为：\(otherDocs)"), value: $otherDocs, in: 0...20)
                }
                Section(L("Notes", "备注")) {
                    TextField(L("Order # / special instructions…", "订单号 / 特殊说明…"), text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(L("New Signing", "新签署单"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save", "保存")) { save() }
                        .disabled(clientId == nil)
                }
            }
            .onAppear {
                if clientId == nil {
                    clientId = preselectedClientId ?? data.clients.first?.id
                }
            }
        }
    }


    private func save() {
        guard let cid = clientId else { return }
        data.signings.append(Signing(clientId: cid, date: date, address: address, fee: fee,
                                     notaryFeePortion: notaryFeePortion, tripFee: tripFee,
                                     minutes: minutes, driveBufferMinutes: buffer,
                                     serviceType: serviceType, borrowDocs: borrowDocs,
                                     trustDocs: trustDocs, otherDocs: otherDocs, note: note))
        Store.save(data)
        scheduleLocalReminder()
        dismiss()
    }

    /// 本地通知：预约前 remindMinutesBefore 分钟
    private func scheduleLocalReminder() {
        guard remindMe else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let triggerDate = date.addingTimeInterval(-Double(remindMinutesBefore) * 60)
            guard triggerDate > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = L("Signing reminder", "签署提醒")
            content.body = L("Leave in \(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60)h" : "\(remindMinutesBefore) min") — \(minutes) min at table + \(buffer) min drive. Bring supplies & tools.", "\(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60) 小时" : "\(remindMinutesBefore) 分钟")后出发（桌上 \(minutes) 分钟 + 车程 \(buffer) 分钟）。带齐耗材工具。")
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(req)
        }
    }
}

// MARK: - 客户编辑器

struct ClientEditor: View {
    @Binding var data: Store.Data
    let existing: Client?
    @Environment(\.dismiss) private var dismiss

    @State private var company = ""
    @State private var contactName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var isBusiness = true

    var body: some View {
        NavigationStack {
            Form {
                Section(L("Client", "客户")) {
                    TextField(L("Title company / signing service", "标题公司 / 签约服务公司"), text: $company)
                    // A9 回访节奏：企业30天/个人90天
                    Picker(L("Client type", "客户类型"), selection: $isBusiness) {
                        Text(L("Business (30-day follow-up)", "企业（30天回访）")).tag(true)
                        Text(L("Individual (90-day follow-up)", "个人（90天回访）")).tag(false)
                    }
                }
                Section(L("Contact", "联系方式")) {
                    TextField(L("Contact (loan officer / coordinator)", "联系人（贷款官/协调员）"), text: $contactName)
                    TextField(L("Phone", "电话"), text: $phone)
                        .keyboardType(.phonePad)
                    TextField(L("Email", "邮箱"), text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section(L("Notes", "备注")) {
                    TextField(L("Payment terms / preferences / notes…", "结算周期 / 偏好 / 备注…"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(existing == nil ? L("New Client", "新客户") : L("Edit Client", "编辑客户"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save", "保存")) { save() }
                        .disabled(company.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let c = existing else { return }
        company = c.company; contactName = c.contactName; phone = c.phone; email = c.email; notes = c.notes; isBusiness = c.isBusiness
    }

    private func save() {
        if var c = existing {
            if let i = data.clients.firstIndex(where: { $0.id == c.id }) {
                c.company = company; c.contactName = contactName; c.phone = phone; c.email = email; c.notes = notes; c.isBusiness = isBusiness
                data.clients[i] = c
            }
        } else {
            data.clients.append(Client(company: company, contactName: contactName, phone: phone, email: email, notes: notes, isBusiness: isBusiness))
        }
        Store.save(data)
        dismiss()
    }
}

// MARK: - 委托证编辑器（N5 到期提醒）

struct CommissionEditor: View {
    @Binding var data: Store.Data
    @Environment(\.dismiss) private var dismiss

    @State private var holderName = ""
    @State private var state = ""
    @State private var expiry = Date()
    @State private var commissionNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(L("Notary Commission", "公证委托证")) {
                    TextField(L("Commission holder name", "持证人姓名"), text: $holderName)
                    TextField(L("State (CA / TX / FL…)", "州（CA / TX / FL…）"), text: $state)
                    TextField(L("Commission number", "委托证编号"), text: $commissionNumber)
                    DatePicker(L("Expiry date", "到期日"), selection: $expiry, displayedComponents: .date)
                }
                Section {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: expiry)).day ?? 0
                    if days < 0 {
                        Label(L("Expired \(-days) days ago", "已过期 \(-days) 天"), systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } else if days <= 90 {
                        Label(L("Expires in \(days) days — start renewal", "\(days) 天后到期——开始续证"), systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    } else {
                        Label(L("Expires in \(days) days", "\(days) 天后到期"), systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle(L("Commission", "委托证"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save", "保存")) {
                        data.commission = Commission(holderName: holderName, state: state, expiry: expiry, commissionNumber: commissionNumber)
                        Store.save(data)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let c = data.commission else { return }
        holderName = c.holderName; state = c.state; expiry = c.expiry; commissionNumber = c.commissionNumber
    }
}
