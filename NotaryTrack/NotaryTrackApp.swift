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
            FeedbackView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(3)
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
            // 健哥令②：拖账超90天=坏账关系，不回访（优先催款而非接新单）
            let overdue90 = data.signings.contains { s in
                s.clientId == c.id && s.agingLevel == 2 && !s.paid
            }
            if overdue90 { continue }
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
                        Text("先加客户（标题公司），再录签署单。费用、跑趟费、公证行为数，一单不漏。")
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
                Label("跑趟费 $" + String(format: "%.0f", signing.tripFee), systemImage: "car")
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

// MARK: - 签署单指标行（353 类型检查超时拆分子视图）

struct SigningRowMetrics: View {
    let s: Signing

    var body: some View {
        HStack(spacing: 8) {
            Text("$" + String(format: "%.0f", s.fee))
            Text("· 净利 $" + String(format: "%.0f", s.netProfit(supplyCost: 2.50)))
            if s.tripFee > 0 {
                Text("· 跑趟费 $" + String(format: "%.0f", s.tripFee))
            }
            Text("· " + (s.paid ? "已收" : "未收"))
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

// MARK: - 签署单头部行（374 类型检查超时拆分子视图）

struct SigningRowHeader: View {
    let s: Signing
    let clientName: String

    var body: some View {
        HStack {
            Text(clientName)
                .font(.headline)
            Text(s.serviceType.emoji).font(.caption)
            if s.status == .noshow {
                Text("没来").font(.caption2).foregroundColor(.red)
            }
            if s.agingLevel > 0 {
                Text("逾期\(s.unpaidDays)天")
                    .font(.caption2)
                    .foregroundColor(s.agingLevel == 2 ? .red : .orange)
            }
            Spacer()
            Text(s.date, style: .date).font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - 签署单列表整行（397 类型检查超时拆分子视图）

struct SigningListRow: View {
    let s: Signing
    @Binding var data: Store.Data
    let sortedDesc: [Signing]

    private var clientName: String {
        data.clients.first { $0.id == s.clientId }?.company ?? "未知"
    }

    var body: some View {
        NavigationLink(destination: SigningDetailView(signing: s, data: $data)) {
            VStack(alignment: .leading, spacing: 2) {
                SigningRowHeader(s: s, clientName: clientName)
                SigningRowMetrics(s: s)
            }
        }
    }
}

// MARK: - Tab2 签署单列表 + 月度小结（N1/N2/N3）

struct SigningListView: View {
    @Binding var data: Store.Data
    @State private var showAdd = false
    @State private var exportText: String?
    @State private var showExport = false

    /// 本月小结 v3（健哥令：删里程删净利；保留账龄/免税拆分/跑趟费）
    var monthSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double,
                       tripFees: Double, acts: Int, netProfit: Double, unpaid: Int,
                       overdueAmount: Double, overdueCount: Int) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let overdue = data.signings.filter { $0.agingLevel > 0 }
        let supply = data.settings.supplyCostPerSigning
        return (
            done.count,
            done.reduce(0) { $0 + $1.fee },
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion },
            done.reduce(0) { $0 + $1.tripFee },
            done.reduce(0) { $0 + $1.borrowDocs + $1.trustDocs + $1.otherDocs },
            done.reduce(0.0) { $0 + $1.netProfit(supplyCost: supply) },
            data.signings.filter { $0.status == .done && !$0.paid }.count,
            overdue.reduce(0) { $0 + $1.fee },
            overdue.count
        )
    }

    /// 健哥令②：年度累计（今年至今——报税直用）
    var yearSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double, netProfit: Double) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        let supply = data.settings.supplyCostPerSigning
        return (
            done.count,
            done.reduce(0) { $0 + $1.fee },
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion },
            done.reduce(0.0) { $0 + $1.netProfit(supplyCost: supply) }
        )
    }

    /// 健哥令③：全部逾期单（账龄>0，按逾期天数降序）
    var overdueSignings: [Signing] {
        data.signings.filter { $0.agingLevel > 0 }.sorted { $0.unpaidDays > $1.unpaidDays }
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
                                NavigationLink(destination: OverdueListView(overdue: overdueSignings, data: $data)) {
                                    Label("\(monthSummary.overdueCount) 单逾期未收，合计 $\(monthSummary.overdueAmount, specifier: "%.0f")（超30天）",
                                          systemImage: "clock.badge.exclamationmark.fill")
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        Section("本月小结") {
                            HStack {
                                StatCell("单数", "\(monthSummary.count)")
                                StatCell("收入", "$" + String(format: "%.0f", monthSummary.income))
                                StatCell("净利", "$" + String(format: "%.0f", monthSummary.netProfit))
                                StatCell("跑趟费", "$" + String(format: "%.0f", monthSummary.tripFees))
                            }
                            // A4 SE 免税拆分 + 税预估
                            HStack(spacing: 16) {
                                Label("公证费(免税) $" + String(format: "%.0f", monthSummary.notaryPortion), systemImage: "checkmark.shield")
                                    .foregroundColor(.green)
                                Label("服务费 $" + String(format: "%.0f", monthSummary.taxablePortion), systemImage: "doc.text")
                            }
                            .font(.caption)
                            Label("预估自雇税 $" + String(format: "%.0f", monthSummary.taxablePortion * 0.153) + "（应税部分×15.3%）", systemImage: "percent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if monthSummary.unpaid > 0 {
                                Label("\(monthSummary.unpaid) 单已签未收款", systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }
                        // 健哥令②：年度累计
                        Section("年度累计（今年至今）") {
                            HStack {
                                StatCell("单数", "\(yearSummary.count)")
                                StatCell("净利", "$" + String(format: "%.0f", yearSummary.netProfit))
                            }
                            HStack(spacing: 16) {
                                Label("公证费(免税) $" + String(format: "%.0f", yearSummary.notaryPortion), systemImage: "checkmark.shield")
                                    .foregroundColor(.green)
                                Label("服务费 $" + String(format: "%.0f", yearSummary.taxablePortion), systemImage: "doc.text")
                            }
                            .font(.caption)
                        }
                        Section("全部签署单") {
                            ForEach(sortedDesc) { s in
                                SigningListRow(s: s, data: $data, sortedDesc: sortedDesc)
                            }
                            // 健哥令④：左滑删除（onDelete 必须挂在 ForEach 直接内容上）
                            .onDelete { offsets in
                                for i in offsets {
                                    let target = sortedDesc[i]
                                    data.signings.removeAll { $0.id == target.id }
                                }
                                Store.save(data)
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
                LabeledRow("净利(扣耗材)", "$" + String(format: "%.2f", current.netProfit(supplyCost: data.settings.supplyCostPerSigning)))
                                LabeledRow("状态", ["已约", "完成", "没来"][statusIndex])
                LabeledRow("收款", current.paid ? "已收" : "未收")
                // A1 账龄
                if current.agingLevel > 0 {
                    LabeledRow("逾期", "\(current.unpaidDays) 天未收")
                }
            }
            Section("公证行为计数") {
                LabeledRow("借款合同", "\(current.borrowDocs) 份")
                LabeledRow("信托文件", "\(current.trustDocs) 份")
                LabeledRow("其他", "\(current.otherDocs) 份")
            }
            // 健哥令③：后续处理——未收→标记已收（清账龄）；已收→改回未收
            if current.status == .done {
                Section("收款处理") {
                    if current.paid {
                        Button(role: .destructive) {
                            markUnpaid()
                        } label: {
                            Label("改回未收款", systemImage: "arrow.uturn.backward")
                        }
                    } else {
                        Button {
                            markPaid()
                        } label: {
                            Label("标记已收款（清逾期）", systemImage: "checkmark.seal.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
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

    // 健哥令③：标记已收（记录 paidDate→A2 付款速度/A6 评级数据源）
    private func markPaid() {
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = true
            data.signings[i].paidDate = Date()
            Store.save(data)
        }
    }
    private func markUnpaid() {
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = false
            data.signings[i].paidDate = nil
            Store.save(data)
        }
    }

    // A5 时薪判决（对照 settings.hourlyFloor）

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


// MARK: - Tab4 我的/反馈（健哥令③）

struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Form {
                Section("反馈意见") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 120)
                        .overlay(
                            Group {
                                if feedbackText.isEmpty {
                                    Text("哪里出现了错误？用着哪里不顺？缺什么功能？直接写。")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                Section {
                    Button {
                        let subject = "公证签署台账-用户反馈"
                        let body = feedbackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "mailto:zeronelabs.dev@gmail.com?subject=\(subject)&body=\(body)") {
                            UIApplication.shared.open(url)
                            sent = true
                        }
                    } label: {
                        Label(sent ? "已打开邮件——发送即完成反馈" : "发送反馈（走你的邮件）", systemImage: "paperplane.fill")
                    }
                    .disabled(feedbackText.isEmpty)
                } footer: {
                    Text("反馈通过邮件直达开发者，不留任何数据在 App 里。")
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: - 逾期单列表（健哥令②③：点警示条进来，逐单处理收款）

struct OverdueListView: View {
    let overdue: [Signing]
    @Binding var data: Store.Data

    var total: Double { overdue.reduce(0) { $0 + $1.fee } }

    var body: some View {
        List {
            Section {
                LabeledRow("逾期单数", "\(overdue.count) 单")
                LabeledRow("逾期合计", "$" + String(format: "%.0f", total))
            }
            Section("逐单处理") {
                ForEach(overdue.sorted { $0.unpaidDays > $1.unpaidDays }) { s in
                    OverdueRow(signing: s, data: $data)
                }
            }
        }
        .navigationTitle("逾期未收")
    }
}

struct OverdueRow: View {
    let signing: Signing
    @Binding var data: Store.Data

    var client: Client? { data.clients.first { $0.id == signing.clientId } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(client?.company ?? "未知客户").font(.headline)
                Spacer()
                Text("$\(signing.fee, specifier: "%.0f")").font(.headline)
            }
            HStack {
                // 账龄色标
                Text("逾期 \(signing.unpaidDays) 天")
                    .font(.caption)
                    .foregroundColor(signing.agingLevel == 2 ? .red : .orange)
                Spacer()
                Button {
                    if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
                        data.signings[i].paid = true
                        data.signings[i].paidDate = Date()
                        Store.save(data)
                    }
                } label: {
                    Label("已收款", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 2)
    }
}


// MARK: - 导出（健哥令②：单签署单/本月总结 导出成文本）

enum NTExporter {
    static func signingText(_ s: Signing, client: Client?, settings: AppSettings) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        df.locale = Locale(identifier: "zh_CN")
        var l: [String] = []
        l.append("【签署单】\(client?.company ?? "未知客户")")
        l.append("时间：\(df.string(from: s.date))")
        if !s.address.isEmpty { l.append("地点：\(s.address)") }
        l.append("类型：\(s.serviceType.rawValue)")
        l.append("总费用：$" + String(format: "%.0f", s.fee) + "（公证费免税 $" + String(format: "%.0f", s.notaryFeePortion) + " + 服务费应税 $" + String(format: "%.0f", s.taxablePortion) + "）")
        if s.tripFee > 0 { l.append("跑趟费：$" + String(format: "%.0f", s.tripFee)) }
        l.append("耗材：$" + String(format: "%.2f", settings.supplyCostPerSigning))
        l.append("净利：$" + String(format: "%.2f", s.netProfit(supplyCost: settings.supplyCostPerSigning)))
        l.append("状态：\(s.status == .done ? "完成" : s.status == .noshow ? "没成功" : "已约") · \(s.paid ? "已收" : "未收")")
        l.append("公证行为：借款 \(s.borrowDocs) / 信托 \(s.trustDocs) / 其他 \(s.otherDocs)")
        if !s.note.isEmpty { l.append("备注：\(s.note)") }
        return l.joined(separator: "\n")
    }

    static func monthText(data: Store.Data) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        var l: [String] = []
        l.append("【本月签署单总结】\(df.string(from: Date()))")
        l.append(String(repeating: "=", count: 30))
        let income = done.reduce(0) { $0 + $1.fee }
        let notary = done.reduce(0) { $0 + $1.notaryFeePortion }
        let net = done.reduce(0.0) { $0 + $1.netProfit(supplyCost: data.settings.supplyCostPerSigning) }
        l.append("单数：\(done.count)")
        l.append("总收入：$" + String(format: "%.0f", income) )
        l.append("  其中公证费（SE 免税）：$" + String(format: "%.0f", notary) )
        l.append("  其中服务费（应税）：$" + String(format: "%.0f", income - notary) )
        l.append("总净利：$" + String(format: "%.0f", net) )
        let unpaid = data.signings.filter { $0.status == .done && !$0.paid }
        if !unpaid.isEmpty {
            l.append("⚠️ 未收款 \(unpaid.count) 单，合计 $" + String(format: "%.0f", unpaid.reduce(0) { $0 + $1.fee }) + "：")
            for u in unpaid {
                l.append("  - " + (data.clients.first { $0.id == u.clientId }?.company ?? "?") + " $" + String(format: "%.0f", u.fee) + "（\(u.unpaidDays) 天）")
            }
        }
        l.append("——逐单明细——")
        for s in done.sorted(by: { $0.date < $1.date }) {
            let cn = data.clients.first { $0.id == s.clientId }?.company ?? "?"
            l.append(df.string(from: s.date) + " " + cn + " $" + String(format: "%.0f", s.fee) + " " + (s.paid ? "已收" : "未收"))
        }
        return l.joined(separator: "\n")
    }
}


// MARK: - 系统分享面板（导出用）

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


// MARK: - 月历（健哥令③：有预约的日子变色）

struct MonthCalendarView: View {
    let bookedDays: Set<String>
    @Binding var selectedMonth: Date

    private var monthDays: [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: selectedMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)  // 1=日
        let daysInMonth = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for d in 1...daysInMonth {
            if let date = cal.date(byAdding: .day, value: d - 1, to: interval.start) {
                cells.append(date)
            }
        }
        return cells
    }

    private var monthTitle: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy年M月"
        df.locale = Locale(identifier: "zh_CN")
        return df.string(from: selectedMonth)
    }

    private var calendarRows: [[Date?]] {
        var rows: [[Date?]] = []
        var cur: [Date?] = []
        for cell in monthDays {
            cur.append(cell)
            if cur.count == 7 { rows.append(cur); cur = [] }
        }
        if !cur.isEmpty { rows.append(cur) }
        return rows
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { w in
                    Text(w).font(.caption2).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(calendarRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { ci, cellOpt in
                        if let date = cellOpt {
                            dayCell(date)
                        } else {
                            Text("").frame(maxWidth: .infinity, minHeight: 34)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func shiftMonth(_ n: Int) {
        if let m = Calendar.current.date(byAdding: .month, value: n, to: selectedMonth) {
            selectedMonth = m
        }
    }

    /// 单日格子（有预约=橙点；今天=靛蓝圆）
    private func dayCell(_ date: Date) -> some View {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let isBooked = bookedDays.contains(df.string(from: date))
        let isToday = Calendar.current.isDateInToday(date)
        return VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(isToday ? Color.indigo : Color.clear))
            Circle()
                .fill(isBooked ? Color.orange : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 34)
    }
}