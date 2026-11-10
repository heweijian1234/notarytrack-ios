import Foundation

// MARK: - 数据模型 v2（v1.1 九件增补：A4公证费拆分/A7跑趟费/A8服务类型 → Signing 加字段；
// A1账龄/A2付款速度/A3净利/A5时薪地板/A6评级/A9回访 = 计算属性+视图层）

enum ServiceType: String, Codable, CaseIterable {
    case loan = "贷款签署"
    case general = "普通公证"
    case apostille = "海牙认证"
    case hospital = "医院/机构"
    case estate = "遗产规划"
    case other = "其他"

    var emoji: String {
        switch self { case .loan: return "🏠"; case .general: return "📝"; case .apostille: return "🌐"; case .hospital: return "🏥"; case .other: return "🐾" }
    }

    var display: String {
        switch self {
        case .loan: return "Loan Signing"
        case .general: return "General Notary"
        case .apostille: return "Apostille"
        case .hospital: return "Hospital/Facility"
        case .other: return "Other"
        }
    }
}

struct Client: Codable, Identifiable, Equatable {
    let id: UUID
    var company: String         // 标题公司/签约服务公司名
    var contactName: String     // 贷款官/协调员
    var phone: String
    var email: String
    var notes: String           // 偏好/结算周期/禁忌
    var noShowCount: Int        // 该客户放鸽子（改单/取消没提前说）
    var isBusiness: Bool        // A9：企业客户（30天回访）vs 个人客户（90天）

    init(id: UUID = UUID(), company: String, contactName: String = "", phone: String = "", email: String = "",
         notes: String = "", noShowCount: Int = 0, isBusiness: Bool = true) {
        self.id = id
        self.company = company
        self.contactName = contactName
        self.phone = phone
        self.email = email
        self.notes = notes
        self.noShowCount = noShowCount
        self.isBusiness = isBusiness
    }
}

struct Signing: Codable, Identifiable, Equatable {
    let id: UUID
    var clientId: UUID
    var date: Date
    var address: String         // 房产/签署地点
    var fee: Double             // 本单总费用（$）
    var notaryFeePortion: Double // A4：其中公证行为费（SE 免税部分，州定价×签数）
    var tripFee: Double         // A7：跑趟费（no-show/redraw/等待超时场景单列）
    var minutes: Int            // 桌上耗时（分钟）
    var driveBufferMinutes: Int // A5 分母补全：车程缓冲（分钟）
    var serviceType: ServiceType // A8：服务类型
    var borrowDocs: Int         // 借款合同份数（N6）
    var trustDocs: Int          // 信托文件份数（N6）
    var otherDocs: Int          // 其他公证行为份数（N6）
    var status: Status          // scheduled / done / noshow
    var paid: Bool              // 付款状态（平台拖款痛）
    var paidDate: Date?         // A2/A6：收款日（算付款天数用）
    var completedDate: Date?    // A1：完成日（账龄计时起点；nil=用 date）
    var note: String

    enum Status: String, Codable { case scheduled, done, noshow
        var display: String {
            switch self { case .scheduled: return "Scheduled"; case .done: return "Done"; case .noshow: return "No-show" }
        }
    }

    init(id: UUID = UUID(), clientId: UUID, date: Date, address: String = "", fee: Double = 0,
         notaryFeePortion: Double = 0, tripFee: Double = 0, minutes: Int = 60,
         driveBufferMinutes: Int = 15, serviceType: ServiceType = .loan,
         borrowDocs: Int = 0, trustDocs: Int = 0, otherDocs: Int = 0,
         status: Status = .scheduled, paid: Bool = false, paidDate: Date? = nil,
         completedDate: Date? = nil, note: String = "") {
        self.id = id
        self.clientId = clientId
        self.date = date
        self.address = address
        self.fee = fee
        self.notaryFeePortion = notaryFeePortion
        self.tripFee = tripFee
        self.minutes = minutes
        self.driveBufferMinutes = driveBufferMinutes
        self.serviceType = serviceType
        self.borrowDocs = borrowDocs
        self.trustDocs = trustDocs
        self.otherDocs = otherDocs
        self.status = status
        self.paid = paid
        self.paidDate = paidDate
        self.completedDate = completedDate
        self.note = note
    }

    // MARK: 计算属性（A1/A3/A5 的数据基础）

    /// A1 账龄：完成日起未收天数（已收款=0）
    var unpaidDays: Int {
        guard status == .done, !paid else { return 0 }
        let start = completedDate ?? date
        return Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: start),
            to: Calendar.current.startOfDay(for: Date())).day ?? 0
    }

    /// A1 账龄等级：0=正常/已收 1=超30天(黄) 2=超45天(红)
    var agingLevel: Int {
        let d = unpaidDays
        if d > 45 { return 2 }
        if d > 30 { return 1 }
        return 0
    }

    /// A4 服务费（应税部分）= 总费 - 公证费免税部分
    var taxablePortion: Double { fee - notaryFeePortion }

    /// A3 净利 = 总费用 + 跑趟费 - 耗材（v1.4 健哥令：里程取消，耗材单价外部传入）
    func netProfit(supplyCost: Double) -> Double {
        fee + tripFee - supplyCost
    }


}

// MARK: - 设置（A5 时薪地板 + A3 耗材单价，全局）

struct AppSettings: Codable, Equatable {
    var supplyCostPerSigning: Double  // A3：单均耗材成本（默认 $2.50）

    init(supplyCostPerSigning: Double = 2.50) {
        self.supplyCostPerSigning = supplyCostPerSigning
    }
}

// MARK: - 委托证（N5：到期提醒，存全局设置）

struct Commission: Codable, Equatable {
    var holderName: String
    var state: String
    var expiry: Date
    var commissionNumber: String

    init(holderName: String = "", state: String = "", expiry: Date = Date(), commissionNumber: String = "") {
        self.holderName = holderName
        self.state = state
        self.expiry = expiry
        self.commissionNumber = commissionNumber
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expiry)).day ?? 0
    }
}

// MARK: - 存储 v2（v1 数据自动迁移：新字段给默认值）

enum Store {
    static let key = "notarytrack.data.v3"

    struct Data: Codable {
        var clients: [Client] = []
        var signings: [Signing] = []
        var commission: Commission? = nil
        var settings: AppSettings = AppSettings()
    }

    static func load() -> Data {
        guard let raw = UserDefaults.standard.data(forKey: key),
              let d = try? JSONDecoder().decode(Data.self, from: raw) else {
            return migrateV1() ?? Data()
        }
        return d
    }

    /// v1（无拆分/跑趟费/类型字段）→ v2
    private static func migrateV1() -> Data? {
        guard let raw = UserDefaults.standard.data(forKey: "notarytrack.data.v1"),
              let old = try? JSONDecoder().decode(OldV1.self, from: raw) else { return nil }
        var d = Data()
        d.clients = old.clients
        d.commission = old.commission
        // 旧单迁移：fee 全部归入应税服务费（公证费拆分让用户后续手动补）
        d.signings = old.signings.map { s in
            var ns = Signing(id: s.id, clientId: s.clientId, date: s.date, address: s.address,
                             fee: s.fee, minutes: s.minutes,
                             borrowDocs: s.borrowDocs, trustDocs: s.trustDocs, otherDocs: s.otherDocs,
                             status: s.status, paid: s.paid, note: s.note)
            ns.notaryFeePortion = 0
            ns.tripFee = 0
            ns.serviceType = .loan
            ns.driveBufferMinutes = 15
            if ns.status == .done { ns.completedDate = ns.date }
            if ns.paid { ns.paidDate = ns.date }
            return ns
        }
        if let raw2 = try? JSONEncoder().encode(d) {
            UserDefaults.standard.set(raw2, forKey: key)
        }
        return d
    }

    private struct OldV1: Codable {
        var clients: [Client]
        var signings: [OldSigning]
        var commission: Commission?
    }

    /// 🔴迁移必须用独立旧结构（新 Signing 有 let id + 自定义 init，JSONDecoder 解码缺键旧 JSON 会失败）
    private struct OldSigning: Codable {
        let id: UUID
        var clientId: UUID
        var date: Date
        var address: String
        var fee: Double
        var mileage: Double
        var minutes: Int
        var borrowDocs: Int
        var trustDocs: Int
        var otherDocs: Int
        var status: Signing.Status
        var paid: Bool
        var note: String
    }

    static func save(_ d: Data) {
        if let raw = try? JSONEncoder().encode(d) {
            UserDefaults.standard.set(raw, forKey: key)
        }
    }
}
