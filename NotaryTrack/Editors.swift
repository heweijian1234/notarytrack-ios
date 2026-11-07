import SwiftUI

// MARK: - 签署单编辑器（新建/编辑）——费用/里程/行为计数/状态

struct SigningEditor: View {
    @Binding var data: Store.Data
    let preselectedClientId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var clientId: UUID?
    @State private var date = Date()
    @State private var address = ""
    @State private var fee = 100.0
    @State private var mileage = 0.0
    @State private var minutes = 60
    @State private var borrowDocs = 1
    @State private var trustDocs = 0
    @State private var otherDocs = 0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("客户") {
                    if data.clients.isEmpty {
                        Text("请先在「客户」页添加标题公司。")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    } else {
                        Picker("客户", selection: $clientId) {
                            ForEach(data.clients) { c in
                                Text(c.company).tag(Optional(c.id))
                            }
                        }
                    }
                }
                Section("时间地点") {
                    DatePicker("时间", selection: $date)
                    TextField("签署地点（房产地址）", text: $address)
                    Stepper("预计 \(minutes) 分钟", value: $minutes, in: 15...240, step: 15)
                }
                Section("费用与里程") {
                    HStack {
                        Text("费用 $")
                        TextField("100", value: $fee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("往返里程 mi")
                        TextField("0", value: $mileage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("里程按 IRS 标准可抵税（\($mileage.wrappedValue * 0.7, specifier: "%.0f") 美元抵扣额）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section("公证行为计数") {
                    Stepper("借款合同 \(borrowDocs) 份", value: $borrowDocs, in: 0...20)
                    Stepper("信托文件 \(trustDocs) 份", value: $trustDocs, in: 0...20)
                    Stepper("其他 \(otherDocs) 份", value: $otherDocs, in: 0...20)
                }
                Section("备注") {
                    TextField("订单号/特殊要求…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新建签署单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
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
                                     mileage: mileage, minutes: minutes, borrowDocs: borrowDocs,
                                     trustDocs: trustDocs, otherDocs: otherDocs, note: note))
        Store.save(data)
        dismiss()
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

    var body: some View {
        NavigationStack {
            Form {
                Section("客户") {
                    TextField("标题公司/签约服务名", text: $company)
                }
                Section("联系") {
                    TextField("联系人（贷款官/协调员）", text: $contactName)
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("备注") {
                    TextField("结算周期/偏好/注意事项…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(existing == nil ? "新建客户" : "编辑客户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(company.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let c = existing else { return }
        company = c.company; contactName = c.contactName; phone = c.phone; email = c.email; notes = c.notes
    }

    private func save() {
        if var c = existing {
            if let i = data.clients.firstIndex(where: { $0.id == c.id }) {
                c.company = company; c.contactName = contactName; c.phone = phone; c.email = email; c.notes = notes
                data.clients[i] = c
            }
        } else {
            data.clients.append(Client(company: company, contactName: contactName, phone: phone, email: email, notes: notes))
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
                Section("委托证（Notary Commission）") {
                    TextField("持证人姓名", text: $holderName)
                    TextField("州（如 CA / TX / FL）", text: $state)
                    TextField("证号", text: $commissionNumber)
                    DatePicker("到期日", selection: $expiry, displayedComponents: .date)
                }
                Section {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: expiry)).day ?? 0
                    if days < 0 {
                        Label("已过期 \(-days) 天", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } else if days <= 90 {
                        Label("\(days) 天后到期——建议开始续证", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    } else {
                        Label("\(days) 天后到期", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("委托证设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
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
