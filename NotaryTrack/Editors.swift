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
    @State private var supplyCost = 2.50
    @State private var remindMe = false       // 健哥令①：默认关，用户自己开
    @State private var remindMinutesBefore = 30 // 健哥令①：分钟制（30/45/60/120/180/240/360/600）
    @State private var notaryFeeHint = "打包价通常 $0"
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
        notaryFeeHint = (t == .general || t == .hospital || t == .estate) ? "每签 $10-25（按州价）" : "打包价通常 $0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    if data.clients.isEmpty {
                        Text("Add a client first (Clients tab).")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    } else {
                        Picker("Client", selection: $clientId) {
                            ForEach(data.clients) { c in
                                Text(c.company).tag(Optional(c.id))
                            }
                        }
                    }
                }
                Section("Time & Place") {
                    // A8 服务类型
                    Picker("Type", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { t in
                            Text("\(t.emoji) \(t.display)").tag(t)
                        }
                    }
                    .onChange(of: serviceType) { t in
                        applyTypeDefaults(t)
                    }
                    Text("Suggested: ~\(minutes) min at the table · notary fee \(notaryFeeHint)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("Date & time", selection: $date)
                    TextField("Signing location (property address)", text: $address)
                    Stepper("Table time \(minutes) min", value: $minutes, in: 15...240, step: 15)
                    // 健哥令①：闹钟放车程缓冲下面
                    Stepper("Drive buffer \(buffer) min", value: $buffer, in: 0...60, step: 5)
                    Toggle("Reminder (alert)", isOn: $remindMe)
                    if remindMe {
                        // 健哥令①：30/45 分钟加入
                        Picker("Remind me", selection: $remindMinutesBefore) {
                            Text("30 min before").tag(30)
                            Text("45 min before").tag(45)
                            Text("1 hour before").tag(60)
                            Text("2 hours before").tag(120)
                            Text("3 hours before").tag(180)
                            Text("4 hours before").tag(240)
                            Text("6 hours before").tag(360)
                            Text("10 hours before").tag(600)
                        }
                        Text("Notified \(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60)h" : "\(remindMinutesBefore) min") before — leave time for the \(buffer) min drive.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Section("Fees & Mileage") {
                    HStack {
                        Text("Total fee $")
                        TextField("0", value: $fee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    // A4 公证费拆分
                    HStack {
                        Text("Notary portion $ (SE-exempt)")
                        TextField("0", value: $notaryFeePortion, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Trip fee $")
                        TextField("0", value: $tripFee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    // 健哥令②：耗材成本自填
                    HStack {
                        Text("Supplies $ (print/paper/ink)")
                        TextField("2.5", value: $supplyCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("Notary portion is exempt from self-employment tax (IRC §1402). Net profit includes supply cost.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section("Notarial Acts") {
                    Stepper("Loan docs: \(borrowDocs)", value: $borrowDocs, in: 0...20)
                    Stepper("Other docs: \(trustDocs)", value: $trustDocs, in: 0...20)
                    Stepper("Misc acts: \(otherDocs)", value: $otherDocs, in: 0...20)
                }
                Section("Notes") {
                    TextField("Order # / special instructions…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Signing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
        data.settings.supplyCostPerSigning = supplyCost   // 记住耗材单价
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
            content.title = "签署提醒"
            content.body = "\(remindMinutesBefore >= 60 ? "\(remindMinutesBefore / 60) 小时" : "\(remindMinutesBefore) 分钟")后出发（桌上 \(minutes) 分钟 + 车程 \(buffer) 分钟）。带齐耗材工具。"
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
                Section("Client") {
                    TextField("Title company / signing service", text: $company)
                    // A9 回访节奏：企业30天/个人90天
                    Picker("Client type", selection: $isBusiness) {
                        Text("Business (30-day follow-up)").tag(true)
                        Text("Individual (90-day follow-up)").tag(false)
                    }
                }
                Section("Contact") {
                    TextField("Contact (loan officer / coordinator)", text: $contactName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Notes") {
                    TextField("Payment terms / preferences / notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(existing == nil ? "New Client" : "Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
                Section("Notary Commission") {
                    TextField("Commission holder name", text: $holderName)
                    TextField("State (CA / TX / FL…)", text: $state)
                    TextField("Commission number", text: $commissionNumber)
                    DatePicker("Expiry date", selection: $expiry, displayedComponents: .date)
                }
                Section {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: expiry)).day ?? 0
                    if days < 0 {
                        Label("Expired \(-days) days ago", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } else if days <= 90 {
                        Label("Expires in \(days) days — start renewal", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    } else {
                        Label("Expires in \(days) days", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Commission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
