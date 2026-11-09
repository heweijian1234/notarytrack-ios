import SwiftUI

@main
struct NotaryTrackApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - 根视图（三Tab：今日/签署单/客户 + 委托证工具栏入口）——中文测试版

struct RootView: View {
    @State private var data = Store.load()
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView(data: $data)
                .tabItem { Label("今日", systemImage: "calendar") }
                .tag(0)
            SigningListView(data: $data)
                .tabItem { Label("签署单", systemImage: "doc.text") }
                .tag(1)
            ClientListView(data: $data)
                .tabItem { Label("客户", systemImage: "person.2") }
                .tag(2)
        }
        .onAppear { data = Store.load() }
    }
}

// MARK: - Tab1 今日（签署单按日分组 + 委托证到期红条 N5）

struct TodayView: View {
    @Binding var data: Store.Data
    @State private var showAdd = false
    @State private var showCommission = false

    var commissionWarn: String? {
        guard let c = data.commission else { return nil }
        let days = c.daysUntilExpiry
        if days < 0 { return "委托证已过期 \(-days) 天——不能接单，快续！" }
        if days <= 90 { return "委托证 \(days) 天后到期（\(c.state)）——开始续证流程" }
        return nil
    }

    // A9 该回访了：企业客户 30 天/个人客户 90 天无新单
    var dueFollowUps: [(Client, Int, Int)] {
        let today = Calendar.current.startOfDay(for: Date())
        var result: [(Client, Int, Int)] = []
        for c in data.clients {
            let lastDone = data.signings
                .filter { $0.clientId == c.id && ($0.status == .done || $0.status == .noshow) }
                .compactMap { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: $0.date), to: today).day }
                .min() ?? Int.max
            let threshold = c.isBusiness ? 30 : 90
            if lastDone >= threshold {
                result.append((c, lastDone, threshold))
            }
        }
        return result.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if data.signings.isEmpty && data.clients.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "stamp")
                            .font(.system(size: 52))
                            .foregroundColor(.indigo)
                        Text("你的签署代理台账")
                            .font(.headline)
                        Text("先加客户（标题公司），再录签署单。费用、里程、公证行为数，一单不漏。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        if let warn = commissionWarn {
                            Section {
                                Label(warn, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        // A9 该回访了
                        if !dueFollowUps.isEmpty {
                            Section("该回访了") {
                                ForEach(dueFollowUps, id: \.0.id) { client, days, threshold in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(client.company).font(.headline)
                                            Text("\(days) 天没有新单（\(threshold == 30 ? "企业客户" : "个人客户")·\(threshold)天惯例）")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if !client.phone.isEmpty {
                                            Button {
                                                if let url = URL(string: "tel://\(client.phone.filter { !$0.isWhitespace && $0 != "-" })") {
                                                    UIApplication.shared.open(url)
                                                }
                                            } label: {
                                                Image(systemName: "phone.fill")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        ForEach(groupedByDay, id: \.0) { day, signings in
                            Section(day) {
                                ForEach(signings) { s in
                                    SigningRow(signing: s, data: $data)
                                }
                            }
                        }
                        if data.signings.isEmpty {
                            Text("还没有签署单——点右上角添加。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showAdd = true } label: { Label("新建签署单", systemImage: "plus") }
                        Button { showCommission = true } label: { Label("委托证设置", systemImage: "credentialing") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                SigningEditor(data: $data, preselectedClientId: nil)
            }
            .sheet(isPresented: $showCommission, onDismiss: { data = Store.load() }) {
                CommissionEditor(data: $data)
            }
        }
    }

    private var groupedByDay: [(String, [Signing])] {
        let df = DateFormatter()
        df.dateFormat = "M月d日 EEEE"
        df.locale = Locale(identifier: "zh_CN")
        let groups = Dictionary(grouping: data.signings.filter { $0.status == .scheduled }.sorted { $0.date < $1.date }) {
            df.string(from: $0.date)
        }
        return groups.sorted { $0.value.first!.date < $1.value.first!.date }
    }
}

// MARK: - 签署单行（完成/没来/收款 动作）

struct SigningRow: View {
    let signing: Signing
    @Binding var data: Store.Data
    @State private var copiedMsg = false

    var client: Client? { data.clients.first { $0.id == signing.clientId } }

    var tf: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(client?.company ?? "未知客户")
                    .font(.headline)
                Spacer()
                Text(tf.string(from: signing.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 10) {
                Label("$\(signing.fee, specifier: "%.0f")", systemImage: "dollarsign.circle")
                Label("\(signing.mileage, specifier: "%.0f") mi", systemImage: "car")
                if signing.paid {
                    Label("已收款", systemImage: "checkmark.seal")
                        .foregroundColor(.green)
                } else {
                    Label("未收", systemImage: "hourglass")
                        .foregroundColor(.orange)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    update(.done)
                } label: {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button {
                    update(.noshow)
                } label: {
                    Label("没来", systemImage: "xmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                if !signing.paid {
                    Button {
                        markPaid()
                    } label: {
                        Label("标记已收款", systemImage: "dollarsign.arrow.circlepath")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func update(_ st: Signing.Status) {
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
            data.signings[i].status = st
            if st == .noshow, let ci = data.clients.firstIndex(where: { $0.id == signing.clientId }) {
                data.clients[ci].noShowCount += 1
            }
            Store.save(data)
        }
    }

    private func markPaid() {
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
            data.signings[i].paid = true
            Store.save(data)
        }
    }
}

// MARK: - Tab2 签署单列表 + 月度小结（N1/N2/N3）

struct SigningListView: View {
    @Binding var data: Store.Data
    @State private var showAdd = false

    /// 本月小结 v2（A1账龄/A3净利/A4免税拆分/A7跑趟费/A8类型 全并入）
    var monthSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double,
                       tripFees: Double, miles: Double, acts: Int, netProfit: Double, unpaid: Int,
                       overdueAmount: Double, overdueCount: Int) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        // A1 全量账龄（不限本月——逾期款不管哪月签的）
        let overdue = data.signings.filter { $0.agingLevel > 0 }
        return (
            done.count,
            done.reduce(0) { $0 + $1.fee },
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion },
            done.reduce(0) { $0 + $1.tripFee },
            done.reduce(0) { $0 + $1.mileage },
            done.reduce(0) { $0 + $1.borrowDocs + $1.trustDocs + $1.otherDocs },
            done.reduce(0) { $0 + $1.netProfit },
            data.signings.filter { $0.status == .done && !$0.paid }.count,
            overdue.reduce(0) { $0 + $1.fee },
            overdue.count
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if data.signings.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 52))
                            .foregroundColor(.indigo)
                        Text("还没有签署单")
                            .font(.headline)
                        Text("录第一单：客户、费用、里程、公证行为数。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        // A1 拖款账龄警示条（最愤怒痛点置顶）
                        if monthSummary.overdueCount > 0 {
                            Section {
                                Label("\(monthSummary.overdueCount) 单逾期未收，合计 $\(monthSummary.overdueAmount, specifier: "%.0f")（超30天）",
                                      systemImage: "clock.badge.exclamationmark.fill")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                        }
                        Section("本月小结") {
                            HStack {
                                StatCell("单数", "\(monthSummary.count)")
                                StatCell("收入", "$" + String(format: "%.0f", monthSummary.income))
                                StatCell("净利", "$" + String(format: "%.0f", monthSummary.netProfit))
                                StatCell("里程", String(format: "%.0f", monthSummary.miles) + " mi")
                            }
                            // A4 SE 免税拆分两行
                            HStack(spacing: 16) {
                                Label("公证费(免税) $" + String(format: "%.0f", monthSummary.notaryPortion), systemImage: "checkmark.shield")
                                    .foregroundColor(.green)
                                Label("服务费 $" + String(format: "%.0f", monthSummary.taxablePortion), systemImage: "doc.text")
                            }
                            .font(.caption)
                            if monthSummary.tripFees > 0 {
                                Label("含跑趟费 $" + String(format: "%.0f", monthSummary.tripFees), systemImage: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if monthSummary.unpaid > 0 {
                                Label("\(monthSummary.unpaid) 单已签未收款", systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }
                        Section("全部签署单") {
                            ForEach(sortedDesc) { s in
                                NavigationLink(destination: SigningDetailView(signing: s, data: $data)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(data.clients.first { $0.id == s.clientId }?.company ?? "未知")
                                                .font(.headline)
                                            Text(s.serviceType.emoji).font(.caption)
                                            if s.status == .noshow {
                                                Text("没来").font(.caption2).foregroundColor(.red)
                                            }
                                            // A1 账龄色标
                                            if s.agingLevel > 0 {
                                                Text("逾期\(s.unpaidDays)天")
                                                    .font(.caption2)
                                                    .foregroundColor(s.agingLevel == 2 ? .red : .orange)
                                            }
                                            Spacer()
                                            Text(s.date, style: .date).font(.caption).foregroundColor(.secondary)
                                        }
                                        HStack(spacing: 8) {
                                            Text("$\(s.fee, specifier: "%.0f")")
                                            Text("· \(s.mileage, specifier: "%.0f") mi")
                                            Text("· \(s.paid ? "已收" : "未收")")
                                            // A5 时薪判决色点
                                            Circle()
                                                .fill(verdictColor(s))
                                                .frame(width: 8, height: 8)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("签署单")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                SigningEditor(data: $data, preselectedClientId: nil)
            }
        }
    }

    /// A5 时薪判决色（对照 settings.hourlyFloor）
    private func verdictColor(_ s: Signing) -> Color {
        let floor = data.settings.hourlyFloor
        if s.hourlyNet >= floor { return .green }
        if s.hourlyNet >= floor * 0.8 { return .yellow }
        return .red
    }

    var sortedDesc: [Signing] {
        data.signings.sorted { $0.date > $1.date }
    }
}

struct StatCell: View {
    let title: String
    let value: String
    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 签署单详情

struct SigningDetailView: View {
    let signing: Signing
    @Binding var data: Store.Data

    var current: Signing { data.signings.first { $0.id == signing.id } ?? signing }
    var client: Client? { data.clients.first { $0.id == current.clientId } }

    var body: some View {
        List {
            Section("客户") {
                if let client {
                    NavigationLink(destination: ClientDetailView(client: client, data: $data)) {
                        VStack(alignment: .leading) {
                            Text(client.company)
                            if !client.contactName.isEmpty {
                                Text(client.contactName).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            Section("本单") {
                LabeledRow("时间", current.date.formatted(date: .long, time: .shortened))
                if !current.address.isEmpty { LabeledRow("地点", current.address) }
                LabeledRow("类型", current.serviceType.emoji + " " + current.serviceType.rawValue)
                LabeledRow("总费用", "$" + String(format: "%.0f", current.fee))
                // A4 拆分显示
                LabeledRow("└ 公证费(免税)", "$" + String(format: "%.0f", current.notaryFeePortion))
                LabeledRow("└ 服务费(应税)", "$" + String(format: "%.0f", current.taxablePortion))
                if current.tripFee > 0 {
                    LabeledRow("└ 跑趟费", "$" + String(format: "%.0f", current.tripFee))
                }
                LabeledRow("里程", String(format: "%.1f", current.mileage) + " mi")
                LabeledRow("状态", ["已约", "完成", "没来"][statusIndex])
                LabeledRow("收款", current.paid ? "已收" : "未收")
                // A1 账龄
                if current.agingLevel > 0 {
                    LabeledRow("逾期", "\(current.unpaidDays) 天未收")
                }
            }
            // A5 时薪判决（A3 净利）
            Section("这单值不值") {
                HStack {
                    Text("净利/小时")
                    Spacer()
                    Text("$" + String(format: "%.0f", current.hourlyNet) + "/h")
                        .foregroundColor(verdictColor)
                }
                HStack {
                    Text("门到门")
                    Spacer()
                    Text("\(current.doorToDoorMinutes) 分钟")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("判决")
                    Spacer()
                    Text(verdictText)
                        .foregroundColor(verdictColor)
                }
            }
            Section("公证行为计数") {
                LabeledRow("借款合同", "\(current.borrowDocs) 份")
                LabeledRow("信托文件", "\(current.trustDocs) 份")
                LabeledRow("其他", "\(current.otherDocs) 份")
            }
            if !current.note.isEmpty {
                Section("备注") { Text(current.note) }
            }
        }
        .navigationTitle("签署单详情")
    }

    var statusIndex: Int {
        switch current.status { case .scheduled: return 0; case .done: return 1; case .noshow: return 2 }
    }

    // A5 时薪判决（对照 settings.hourlyFloor）
    private var verdictColor: Color {
        let floor = data.settings.hourlyFloor
        if current.hourlyNet >= floor { return .green }
        if current.hourlyNet >= floor * 0.8 { return .yellow }
        return .red
    }
    private var verdictText: String {
        let floor = data.settings.hourlyFloor
        if current.hourlyNet >= floor { return "✅ 值得接" }
        if current.hourlyNet >= floor * 0.8 { return "⚠️ 勉强" }
        return "🔴 低于地板"
    }
}

struct LabeledRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - Tab3 客户列表

struct ClientListView: View {
    @Binding var data: Store.Data
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if data.clients.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "person.2")
                            .font(.system(size: 52))
                            .foregroundColor(.indigo)
                        Text("还没有客户")
                            .font(.headline)
                        Text("客户=标题公司/签约服务。记录联系人和结算习惯。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(data.clients) { c in
                            NavigationLink(destination: ClientDetailView(client: c, data: $data)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(c.company).font(.headline)
                                        if c.noShowCount > 0 {
                                            Text("\(c.noShowCount) 次改期").font(.caption2).foregroundColor(.orange)
                                        }
                                    }
                                    let count = data.signings.filter { $0.clientId == c.id }.count
                                    Text("\(count) 单 · \(c.contactName.isEmpty ? "无联系人" : c.contactName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { data.clients.remove(atOffsets: $0); Store.save(data) }
                    }
                }
            }
            .navigationTitle("客户")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                ClientEditor(data: $data, existing: nil)
            }
        }
    }
}

// MARK: - 客户详情

struct ClientDetailView: View {
    let client: Client
    @Binding var data: Store.Data
    @State private var showEdit = false

    var current: Client { data.clients.first { $0.id == client.id } ?? client }
    var mySignings: [Signing] {
        data.signings.filter { $0.clientId == current.id }.sorted { $0.date > $1.date }
    }

    // A2 平均付款天数（done→paidDate）
    var avgPayDays: Double? {
        let pairs = mySignings.filter { $0.paid && $0.paidDate != nil }
        guard !pairs.isEmpty else { return nil }
        let total = pairs.reduce(0.0) { sum, s in
            let days = Calendar.current.dateComponents([.day],
                from: Calendar.current.startOfDay(for: s.completedDate ?? s.date),
                to: Calendar.current.startOfDay(for: s.paidDate!)).day ?? 0
            return sum + Double(max(0, days))
        }
        return total / Double(pairs.count)
    }

    // A6 评级三档（从平均付款天数自动推）
    var rating: (label: String, color: Color) {
        guard let d = avgPayDays else {
            return ("未评级（还没收过款）", .secondary)
        }
        if d <= 30 { return ("✅ 优选（平均 \(Int(d)) 天付款）", .green) }
        if d <= 45 { return ("⚠️ 注意（平均 \(Int(d)) 天付款）", .orange) }
        return ("🔴 拉黑观察（平均 \(Int(d)) 天付款）", .red)
    }

    var body: some View {
        List {
            // A2/A6 付款速度+评级
            Section("付款表现") {
                if let d = avgPayDays {
                    LabeledRow("平均付款天数", "\(Int(d)) 天")
                }
                Label(rating.label, systemImage: "star.fill")
                    .foregroundColor(rating.color)
            }
            Section("联系") {
                if !current.contactName.isEmpty { LabeledRow("联系人", current.contactName) }
                if !current.phone.isEmpty {
                    Link(destination: URL(string: "tel://\(current.phone.filter { !$0.isWhitespace })")!) {
                        Label(current.phone, systemImage: "phone")
                    }
                }
                if !current.email.isEmpty {
                    Link(destination: URL(string: "mailto:\(current.email)")!) {
                        Label(current.email, systemImage: "envelope")
                    }
                }
            }
            if !current.notes.isEmpty {
                Section("备注") { Text(current.notes) }
            }
            if current.noShowCount > 0 {
                Section {
                    Label("\(current.noShowCount) 次改期/放鸽子", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
            }
            Section("签署历史") {
                if mySignings.isEmpty {
                    Text("还没有单").font(.footnote).foregroundColor(.secondary)
                } else {
                    ForEach(mySignings.prefix(10)) { s in
                        HStack {
                            Image(systemName: s.status == .done ? "checkmark.circle" : s.status == .noshow ? "xmark.circle" : "clock")
                            Text(s.date, style: .date)
                            Spacer()
                            Text("$\(s.fee, specifier: "%.0f")").font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(current.company)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: { data = Store.load() }) {
            ClientEditor(data: $data, existing: current)
        }
    }
}
