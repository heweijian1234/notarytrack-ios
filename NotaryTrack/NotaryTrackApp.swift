import SwiftUI
import Combine   // 11-24试用制：全局付费墙通知

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
    // 11-24试用制：全局付费墙（各写入口 TrialStore.gate() 拦截后发通知，这里统一弹）
    @State private var showProPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // 到期只读横幅（坏消息放事前）
            if !TrialStore.canWrite {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(L("Trial ended — records are read-only.", "试用已结束——记录只读。"))
                        .font(.caption)
                    Spacer()
                    Button(L("Unlock", "解锁")) {
                        NotificationCenter.default.post(name: TrialStore.showPaywallNotification, object: nil)
                    }
                    .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.indigo)
            }
            TabView(selection: $tab) {
                TodayView(data: $data)
                    .tabItem { Label(L("Today", "今日"), systemImage: "calendar") }
                    .tag(0)
                SigningListView(data: $data)
                    .tabItem { Label(L("Signings", "签署单"), systemImage: "doc.text") }
                    .tag(1)
                ClientListView(data: $data)
                    .tabItem { Label(L("Clients", "客户"), systemImage: "person.2") }
                    .tag(2)
                FeedbackView()
                    .tabItem { Label(L("Me", "我的"), systemImage: "person.crop.circle") }
                    .tag(3)
            }
        }
        .onAppear {
            data = Store.load()
            TrialStore.registerStartIfNeeded()
            Task { await ProStore.restore() }
        }
        .onReceive(NotificationCenter.default.publisher(for: TrialStore.showPaywallNotification)) { _ in
            showProPaywall = true
        }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
        }
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
        if days < 0 { return L("Commission expired \(-days) days ago — no signings allowed. Renew now!", "委托证已过期 \(-days) 天——不能接单，快续！") }
        if days <= 90 { return L("Commission expires in \(days) days (\(c.state)) — start renewal", "委托证 \(days) 天后到期（\(c.state)）——开始续证流程") }
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
                        Text(L("Your signing agent book", "你的公证签署台账"))
                            .font(.headline)
                        Text(L("Add a client (title company) first, then log signings. Fees, trip fees, notarial acts — nothing missed.", "先加客户（标题公司），再记签署单。费用、跑趟费、公证行为——一样不漏。"))
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
                            Section(L("Due for follow-up", "该回访了")) {
                                ForEach(dueFollowUps, id: \.0.id) { client, days, threshold in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(client.company).font(.headline)
                                            Text(L("\(days) days since last signing (\(threshold == 30 ? "business" : "individual") · \(threshold)-day norm)", "\(days) 天没新单（\(threshold == 30 ? "企业" : "个人") · \(threshold)天标准）"))
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
                            Text(L("No signings yet — tap + to add.", "还没有签署单——点右上角 + 添加。"))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(L("Today", "今日"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { if TrialStore.gate() { showAdd = true } } label: { Label(L("New Signing", "新签署单"), systemImage: "plus") }
                        Button { if TrialStore.gate() { showCommission = true } } label: { Label(L("Commission", "委托证"), systemImage: "credentialing") }
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
        if AppLang.current == .en {
            df.dateFormat = "MMM d EEEE"
            df.locale = Locale(identifier: "en_US")
        } else {
            df.dateFormat = "M月d日 EEEE"
            df.locale = Locale(identifier: "zh_CN")
        }
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
        f.locale = Locale(identifier: AppLang.current == .en ? "en_US" : "zh_CN")
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(client?.company ?? L("Unknown client", "未知客户"))
                    .font(.headline)
                Spacer()
                Text(tf.string(from: signing.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 10) {
                Label("$\(signing.fee, specifier: "%.0f")", systemImage: "dollarsign.circle")
                Label(L("Trip fee $", "跑趟费 $") + String(format: "%.0f", signing.tripFee), systemImage: "car")
                if signing.paid {
                    Label(L("Paid", "已收"), systemImage: "checkmark.seal")
                        .foregroundColor(.green)
                } else {
                    Label(L("Unpaid", "未收"), systemImage: "hourglass")
                        .foregroundColor(.orange)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    update(.done)
                } label: {
                    Label(L("Done", "完成"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button {
                    update(.noshow)
                } label: {
                    Label(L("No-show", "没来"), systemImage: "xmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                if !signing.paid {
                    Button {
                        markPaid()
                    } label: {
                        Label(L("Mark Paid", "标记已收"), systemImage: "dollarsign.arrow.circlepath")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func update(_ st: Signing.Status) {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
            data.signings[i].status = st
            if st == .noshow, let ci = data.clients.firstIndex(where: { $0.id == signing.clientId }) {
                data.clients[ci].noShowCount += 1
            }
            Store.save(data)
        }
    }

    private func markPaid() {
        guard TrialStore.gate() else { return }
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
            if s.tripFee > 0 {
                Text(L("· Trip fee $", "· 跑趟费 $") + String(format: "%.0f", s.tripFee))
            }
            Text("· " + (s.paid ? L("Paid", "已收") : L("Unpaid", "未收")))
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
                Text(L("No-show", "没来")).font(.caption2).foregroundColor(.red)
            }
            if s.agingLevel > 0 {
                Text(L("Overdue \(s.unpaidDays)d", "逾期\(s.unpaidDays)天"))
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
        data.clients.first { $0.id == s.clientId }?.company ?? L("Unknown", "未知")
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
                       tripFees: Double, acts: Int, unpaid: Int,
                       overdueAmount: Double, overdueCount: Int) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let overdue = data.signings.filter { $0.agingLevel > 0 }
        return (
            done.count,
            done.reduce(0) { $0 + $1.fee },
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion },
            done.reduce(0) { $0 + $1.tripFee },
            done.reduce(0) { $0 + $1.borrowDocs + $1.trustDocs + $1.otherDocs },
            data.signings.filter { $0.status == .done && !$0.paid }.count,
            overdue.reduce(0) { $0 + $1.fee },
            overdue.count
        )
    }

    /// 健哥令②：年度累计（今年至今——报税直用）
    var yearSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        return (
            done.count,
            done.reduce(0) { $0 + $1.fee },
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion }
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
                    emptyState
                } else {
                    List {
                        // A1 拖款账龄警示条（最愤怒痛点置顶）
                        if monthSummary.overdueCount > 0 {
                            Section {
                                NavigationLink(destination: OverdueListView(overdue: overdueSignings, data: $data)) {
                                    Label(L("\(monthSummary.overdueCount) overdue, totaling $\(monthSummary.overdueAmount, specifier: "%.0f") (30+ days)", "\(monthSummary.overdueCount) 单逾期，合计 $\(monthSummary.overdueAmount, specifier: "%.0f")（超30天）"),
                                          systemImage: "clock.badge.exclamationmark.fill")
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        monthSection
                        // 健哥令②：年度累计
                        yearSection
                        Section(L("All Signings", "全部签署单")) {
                            ForEach(sortedDesc) { s in
                                SigningListRow(s: s, data: $data, sortedDesc: sortedDesc)
                            }
                            // 健哥令④：左滑删除（onDelete 必须挂在 ForEach 直接内容上）
                            .onDelete { offsets in
                                guard TrialStore.gate() else { return }
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
            .navigationTitle(L("Signings", "签署单"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { if TrialStore.gate() { showAdd = true } } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                SigningEditor(data: $data, preselectedClientId: nil)
            }
        }
    }


    // 11-24类型检查溢出根修：拆子视图（本文件353/374/397历史同款药方——L()化后body再超限）
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 52))
                .foregroundColor(.indigo)
            Text(L("No signings yet", "还没有签署单"))
                .font(.headline)
            Text(L("Log your first signing: client, fee, notarial acts.", "记第一单：客户、费用、公证行为。"))
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var monthSection: some View {
        Section(L("This Month", "本月")) {
            HStack {
                StatCell(L("Signings", "单数"), "\(monthSummary.count)")
                StatCell(L("Income", "收入"), "$" + String(format: "%.0f", monthSummary.income))
                StatCell(L("Trip fees", "跑趟费"), "$" + String(format: "%.0f", monthSummary.tripFees))
            }
            // A4 SE 免税拆分 + 税预估
            HStack(spacing: 16) {
                Label(L("Notary (SE-exempt) $", "公证费（免SE税）$") + String(format: "%.0f", monthSummary.notaryPortion), systemImage: "checkmark.shield")
                    .foregroundColor(.green)
                Label(L("Service $", "服务费 $") + String(format: "%.0f", monthSummary.taxablePortion), systemImage: "doc.text")
            }
            .font(.caption)
            Label(L("Est. SE tax $", "预估SE税 $") + String(format: "%.0f", monthSummary.taxablePortion * 0.153) + L(" (taxable × 15.3%)", "（应税部分×15.3%）"), systemImage: "percent")
                .font(.caption)
                .foregroundColor(.secondary)
            if monthSummary.unpaid > 0 {
                Label(L("\(monthSummary.unpaid) signings unpaid", "\(monthSummary.unpaid) 单未收款"), systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
        }
    }

    private var yearSection: some View {
        Section(L("Year to Date", "今年累计")) {
            HStack {
                StatCell(L("Signings", "单数"), "\(yearSummary.count)")
                StatCell(L("Income", "收入"), "$" + String(format: "%.0f", yearSummary.income))
            }
            HStack(spacing: 16) {
                Label(L("Notary (SE-exempt) $", "公证费（免SE税）$") + String(format: "%.0f", yearSummary.notaryPortion), systemImage: "checkmark.shield")
                    .foregroundColor(.green)
                Label(L("Service $", "服务费 $") + String(format: "%.0f", yearSummary.taxablePortion), systemImage: "doc.text")
            }
            .font(.caption)
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
            Section(L("Clients", "客户")) {
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
            Section(L("This Signing", "本单")) {
                LabeledRow(L("Date", "日期"), current.date.formatted(date: .long, time: .shortened))
                if !current.address.isEmpty { LabeledRow(L("Location", "地点"), current.address) }
                LabeledRow(L("Type", "类型"), current.serviceType.display)
                LabeledRow(L("Total fee", "总费用"), "$" + String(format: "%.0f", current.fee))
                // A4 拆分显示
                LabeledRow(L("├ Notary (exempt)", "├ 公证费（免税）"), "$" + String(format: "%.0f", current.notaryFeePortion))
                LabeledRow(L("├ Service (taxable)", "├ 服务费（应税）"), "$" + String(format: "%.0f", current.taxablePortion))
                if current.tripFee > 0 {
                    LabeledRow(L("├ Trip fee", "├ 跑趟费"), "$" + String(format: "%.0f", current.tripFee))
                }
                                LabeledRow(L("Status", "状态"), [L("Scheduled", "已约"), L("Done", "完成"), L("No-show", "没来")][statusIndex])
                LabeledRow(L("Payment", "收款"), current.paid ? L("Paid", "已收") : L("Unpaid", "未收"))
                // A1 账龄
                if current.agingLevel > 0 {
                    LabeledRow(L("Overdue", "逾期"), L("\(current.unpaidDays) days unpaid", "\(current.unpaidDays) 天未收"))
                }
            }
            Section(L("Notarial Acts", "公证行为")) {
                LabeledRow(L("Loan docs", "借款文件"), "\(current.borrowDocs)")
                LabeledRow(L("Trust docs", "信托文件"), "\(current.trustDocs)")
                LabeledRow(L("Other", "其他"), "\(current.otherDocs)")
            }
            // 健哥令③：后续处理——未收→标记已收（清账龄）；已收→改回未收
            if current.status == .done {
                Section(L("Payment", "收款")) {
                    if current.paid {
                        Button(role: .destructive) {
                            markUnpaid()
                        } label: {
                            Label(L("Mark Unpaid", "改回未收"), systemImage: "arrow.uturn.backward")
                        }
                    } else {
                        Button {
                            markPaid()
                        } label: {
                            Label(L("Mark Paid (clear overdue)", "标记已收（清逾期）"), systemImage: "checkmark.seal.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            if !current.note.isEmpty {
                Section(L("Notes", "备注")) { Text(current.note) }
            }
        }
        .navigationTitle(L("Signing Details", "签署单详情"))
    }

    var statusIndex: Int {
        switch current.status { case .scheduled: return 0; case .done: return 1; case .noshow: return 2 }
    }

    // 健哥令③：标记已收（记录 paidDate→A2 付款速度/A6 评级数据源）
    private func markPaid() {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = true
            data.signings[i].paidDate = Date()
            Store.save(data)
        }
    }
    private func markUnpaid() {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = false
            data.signings[i].paidDate = nil
            Store.save(data)
        }
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
                        Text(L("No clients yet", "还没有客户"))
                            .font(.headline)
                        Text(L("Clients are title companies / signing services. Track contacts and payment habits.", "客户=标题公司/签约服务公司。记联系人和付款习惯。"))
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
                                            Text(L("\(c.noShowCount) no-shows", "\(c.noShowCount) 次没来")).font(.caption2).foregroundColor(.orange)
                                        }
                                    }
                                    let count = data.signings.filter { $0.clientId == c.id }.count
                                    Text(L("\(count) signings · \(c.contactName.isEmpty ? "no contact" : c.contactName)", "\(count) 单 · \(c.contactName.isEmpty ? "无联系人" : c.contactName)"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            guard TrialStore.gate() else { return }
                            data.clients.remove(atOffsets: offsets); Store.save(data)
                        }
                    }
                }
            }
            .navigationTitle(L("Clients", "客户"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { if TrialStore.gate() { showAdd = true } } label: { Image(systemName: "plus") }
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
            return (L("Not rated (no payments yet)", "未评级（还没收过款）"), .secondary)
        }
        if d <= 30 { return (L("✅ Preferred (avg \(Int(d)) days to pay)", "✅ 优选（平均 \(Int(d)) 天付款）"), .green) }
        if d <= 45 { return (L("⚠️ Watch (avg \(Int(d)) days to pay)", "⚠️ 注意（平均 \(Int(d)) 天付款）"), .orange) }
        return (L("🔴 Blacklist-watch (avg \(Int(d)) days to pay)", "🔴 拉黑观察（平均 \(Int(d)) 天付款）"), .red)
    }

    var body: some View {
        List {
            // A2/A6 付款速度+评级
            Section(L("Payment Behavior", "付款行为")) {
                if let d = avgPayDays {
                    LabeledRow(L("Avg days to pay", "平均付款天数"), "\(Int(d))")
                }
                Label(rating.label, systemImage: "star.fill")
                    .foregroundColor(rating.color)
            }
            Section(L("Contact", "联系方式")) {
                if !current.contactName.isEmpty { LabeledRow(L("Contact", "联系人"), current.contactName) }
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
                Section(L("Notes", "备注")) { Text(current.notes) }
            }
            if current.noShowCount > 0 {
                Section {
                    Label(L("\(current.noShowCount) no-shows on record", "记录在案：\(current.noShowCount) 次没来"), systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
            }
            Section(L("Signing History", "签署历史")) {
                if mySignings.isEmpty {
                    Text(L("No signings yet", "还没有签署单")).font(.footnote).foregroundColor(.secondary)
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
                Button { if TrialStore.gate() { showEdit = true } } label: { Image(systemName: "pencil") }
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
    // 11-24试用制测试钩子：版本行连点5下唤出调试区
    @State private var versionTaps = 0
    @State private var showTrialDebug = false
    @State private var debugTick = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(L("Feedback", "反馈意见")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 120)
                        .overlay(
                            Group {
                                if feedbackText.isEmpty {
                                    Text(L("Any errors? Anything clunky? Missing features? Just write it.", "有错？用着不顺？缺功能？直接写。"))
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
                        let subject = "NotaryTrack - user feedback"
                        let body = feedbackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "mailto:zeronelabs.dev@gmail.com?subject=\(subject)&body=\(body)") {
                            UIApplication.shared.open(url)
                            sent = true
                        }
                    } label: {
                        Label(sent ? L("Mail opened — send to finish", "已打开邮件——发送即完成反馈") : L("Send feedback (via your mail)", "发送反馈（走你的邮件）"), systemImage: "paperplane.fill")
                    }
                    .disabled(feedbackText.isEmpty)
                } footer: {
                    Text(L("Feedback goes straight to the developer by email. Nothing is stored in the app.", "反馈通过邮件直达开发者，App不留任何数据。"))
                }
                // 11-24试用制：状态行（试用期内可点=提前解锁；审核员必须能走到内购）
                Section {
                    Button {
                        if !ProStore.unlocked {
                            NotificationCenter.default.post(name: TrialStore.showPaywallNotification, object: nil)
                        }
                    } label: {
                        HStack {
                            Label("NotaryTrack Pro",
                                  systemImage: (ProStore.unlocked || TrialStore.debugOverride == "unlocked") ? "crown.fill" : (TrialStore.canWrite ? "hourglass" : "lock"))
                                .foregroundColor(.indigo)
                            Spacer()
                            Text(TrialStore.statusText)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Pro")
                } footer: {
                    Text(L("30-day full-feature trial. After it ends: records stay readable free forever; unlock once to keep adding.",
                           "30天全功能试用。到期后：记录永远可看（免费）；解锁一次即可继续新增。"))
                        .font(.caption2)
                }
                // 测试钩子：版本行连点5下唤出试用状态调试（健哥TestFlight实测用）
                Section {
                    Button {
                        versionTaps += 1
                        if versionTaps >= 5 { showTrialDebug.toggle(); versionTaps = 0 }
                    } label: {
                        HStack {
                            Text(L("Version", "版本")).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if showTrialDebug {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("调试：试用状态覆盖（仅测试用，切换后切个Tab刷新横幅）").font(.caption.bold())
                            Text("起点：\(TrialStore.startDate.map { "\($0)" } ?? "未登记")｜剩 \(TrialStore.daysLeft) 天｜覆盖：\(TrialStore.debugOverride ?? "无")")
                                .font(.caption2).foregroundColor(.secondary)
                            Button("重置为全新试用（30天）") { TrialStore.setDebugOverride("fresh"); debugTick += 1 }
                            Button("强制到期（只读）") { TrialStore.setDebugOverride("expired"); debugTick += 1 }
                            Button("强制已解锁") { TrialStore.setDebugOverride("unlocked"); debugTick += 1 }
                            Button("清除覆盖（恢复真实状态）") { TrialStore.setDebugOverride(nil); debugTick += 1 }
                        }
                        .font(.caption)
                        .id(debugTick)
                    }
                }
            }
            .navigationTitle(L("Me", "我的"))
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
                LabeledRow(L("Overdue signings", "逾期单数"), "\(overdue.count)")
                LabeledRow(L("Total overdue", "逾期总额"), "$" + String(format: "%.0f", total))
            }
            Section(L("Process Each", "逐单处理")) {
                ForEach(overdue.sorted { $0.unpaidDays > $1.unpaidDays }) { s in
                    OverdueRow(signing: s, data: $data)
                }
            }
        }
        .navigationTitle(L("Overdue", "逾期"))
    }
}

struct OverdueRow: View {
    let signing: Signing
    @Binding var data: Store.Data

    var client: Client? { data.clients.first { $0.id == signing.clientId } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(client?.company ?? L("Unknown client", "未知客户")).font(.headline)
                Spacer()
                Text("$\(signing.fee, specifier: "%.0f")").font(.headline)
            }
            HStack {
                // 账龄色标
                Text(L("Overdue \(signing.unpaidDays) days", "逾期 \(signing.unpaidDays) 天"))
                    .font(.caption)
                    .foregroundColor(signing.agingLevel == 2 ? .red : .orange)
                Spacer()
                Button {
                    guard TrialStore.gate() else { return }
                    if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
                        data.signings[i].paid = true
                        data.signings[i].paidDate = Date()
                        Store.save(data)
                    }
                } label: {
                    Label(L("Mark Paid", "标记已收"), systemImage: "checkmark.seal.fill")
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
        l.append(L("【Signing】\(client?.company ?? L("Unknown client", "未知客户"))", "【签署单】\(client?.company ?? "未知客户")"))
        l.append(L("Time: \(df.string(from: s.date))", "时间：\(df.string(from: s.date))"))
        if !s.address.isEmpty { l.append(L("Location: \(s.address)", "地点：\(s.address)")) }
        l.append(L("Type: ", "类型：") + s.serviceType.display)
        l.append(L("Total: $", "总费用：$") + String(format: "%.0f", s.fee) + L(" (notary SE-exempt $", "（公证费免税 $") + String(format: "%.0f", s.notaryFeePortion) + L(" + service taxable $", " + 服务费应税 $") + String(format: "%.0f", s.taxablePortion) + L(")", "）"))
        if s.tripFee > 0 { l.append(L("Trip fee: $", "跑趟费：$") + String(format: "%.0f", s.tripFee)) }
        l.append(L("Status: \(s.status == .done ? "Done" : s.status == .noshow ? "No-show" : "Scheduled") · \(s.paid ? "Paid" : "Unpaid")", "状态：\(s.status == .done ? "完成" : s.status == .noshow ? "没成功" : "已约") · \(s.paid ? "已收" : "未收")"))
        l.append(L("Notarial acts: loan \(s.borrowDocs) / trust \(s.trustDocs) / other \(s.otherDocs)", "公证行为：借款 \(s.borrowDocs) / 信托 \(s.trustDocs) / 其他 \(s.otherDocs)"))
        if !s.note.isEmpty { l.append(L("Note: \(s.note)", "备注：\(s.note)")) }
        return l.joined(separator: "\n")
    }

    static func monthText(data: Store.Data) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        var l: [String] = []
        l.append(L("【Monthly Signing Summary】\(df.string(from: Date()))", "【本月签署单总结】\(df.string(from: Date()))"))
        l.append(String(repeating: "=", count: 30))
        let income = done.reduce(0) { $0 + $1.fee }
        let notary = done.reduce(0) { $0 + $1.notaryFeePortion }
        l.append(L("Signings: \(done.count)", "单数：\(done.count)"))
        l.append(L("Total income: $", "总收入：$") + String(format: "%.0f", income) )
        l.append(L("  Notary portion (SE-exempt): $", "  其中公证费（SE 免税）：$") + String(format: "%.0f", notary) )
        l.append(L("  Service portion (taxable): $", "  其中服务费（应税）：$") + String(format: "%.0f", income - notary) )
        let unpaid = data.signings.filter { $0.status == .done && !$0.paid }
        if !unpaid.isEmpty {
            l.append(L("⚠️ Unpaid \(unpaid.count) signings, totaling $", "⚠️ 未收款 \(unpaid.count) 单，合计 $") + String(format: "%.0f", unpaid.reduce(0) { $0 + $1.fee }) + L(":", "："))
            for u in unpaid {
                l.append("  - " + (data.clients.first { $0.id == u.clientId }?.company ?? "?") + " $" + String(format: "%.0f", u.fee) + L(" (\(u.unpaidDays) days)", "（\(u.unpaidDays) 天）"))
            }
        }
        l.append(L("—— Per signing ——", "——逐单明细——"))
        for s in done.sorted(by: { $0.date < $1.date }) {
            let cn = data.clients.first { $0.id == s.clientId }?.company ?? "?"
            l.append(df.string(from: s.date) + " " + cn + " $" + String(format: "%.0f", s.fee) + " " + (s.paid ? L("Paid", "已收") : L("Unpaid", "未收")))
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
        if AppLang.current == .en {
            df.dateFormat = "MMMM yyyy"
            df.locale = Locale(identifier: "en_US")
        } else {
            df.dateFormat = "yyyy年M月"
            df.locale = Locale(identifier: "zh_CN")
        }
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
            let weekdays = AppLang.current == .en ? ["S", "M", "T", "W", "T", "F", "S"] : ["日", "一", "二", "三", "四", "五", "六"]
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