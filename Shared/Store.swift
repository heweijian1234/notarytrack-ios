import Foundation

// MARK: - 数据模型 v2（v1.1 九件增补：A4公证费拆分/A7跑趟费/A8服务类型 → Signing 加字段；
// A1账龄/A2付款速度/A3净利/A5时薪地板/A6评级/A9回访 = 计算属性+视图层）

enum ServiceType: String, Codable, CaseIterable {
    // 健哥 2026-11-28：「其他」改名「自定义」并排列第一（rawValue 是持久化键，只改显示不动键，防旧数据解码炸）
    case other = "其他"
    case loan = "贷款签署"
    case general = "普通公证"
    case apostille = "海牙认证"
    case hospital = "医院/机构"
    case estate = "遗产规划"

    var emoji: String {
        switch self { case .other: return "🧩"; case .loan: return "🏠"; case .general: return "📝"; case .apostille: return "🌐"; case .hospital: return "🏥"; case .estate: return "📜" }
    }

    var display: String {
        switch self {
        case .other: return L("Custom", "自定义")
        case .loan: return L("Loan Signing", "贷款签署")
        case .general: return L("General Notary", "普通公证")
        case .apostille: return L("Apostille", "海牙认证")
        case .hospital: return L("Hospital/Facility", "医院/机构")
        case .estate: return L("Estate Planning", "遗产规划")
        }
    }
}

/// 健哥 2026-11-28：公证所需文件清单行（设置页自编名称，签署单上只填份数）
struct DocLine: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var count: Int

    init(id: UUID = UUID(), name: String, count: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
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
    var driveBufferMinutes: Int // 车程缓冲（分钟）
    var serviceType: ServiceType // A8：服务类型
    var borrowDocs: Int         // 借款合同份数（N6）
    var trustDocs: Int          // 信托文件份数（N6）
    var otherDocs: Int          // 其他公证行为份数（N6）
    var status: Status          // scheduled / done / noshow
    var paid: Bool              // 付款状态（平台拖款痛）
    var paidDate: Date?         // A2/A6：收款日（算付款天数用）
    var completedDate: Date?    // A1：完成日（账龄计时起点；nil=用 date）
    var note: String
    var docItems: [DocLine]?    // 11-28 公证所需文件清单（nil=旧数据→从 borrow/trust/other 三计数换算显示）

    enum Status: String, Codable { case scheduled, done, noshow
        var display: String {
            switch self { case .scheduled: return L("Scheduled", "已约"); case .done: return L("Done", "完成"); case .noshow: return L("No-show", "没来") }
        }
    }

    init(id: UUID = UUID(), clientId: UUID, date: Date, address: String = "", fee: Double = 0,
         notaryFeePortion: Double = 0, tripFee: Double = 0, minutes: Int = 60,
         driveBufferMinutes: Int = 15, serviceType: ServiceType = .loan,
         borrowDocs: Int = 0, trustDocs: Int = 0, otherDocs: Int = 0,
         status: Status = .scheduled, paid: Bool = false, paidDate: Date? = nil,
         completedDate: Date? = nil, note: String = "", docItems: [DocLine]? = nil) {
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
        self.docItems = docItems
    }

    /// 11-28 显示统一走这里：新单读 docItems；旧单 docItems 为 nil 时从三个计数换算成清单行
    var effectiveDocItems: [DocLine] {
        if let d = docItems, !d.isEmpty { return d }
        var lines: [DocLine] = []
        if borrowDocs > 0 { lines.append(DocLine(name: L("Loan docs", "借款文件"), count: borrowDocs)) }
        if trustDocs > 0 { lines.append(DocLine(name: L("Trust docs", "信托文件"), count: trustDocs)) }
        if otherDocs > 0 { lines.append(DocLine(name: L("Other acts", "其他行为"), count: otherDocs)) }
        return lines
    }

    /// 文件总份数（月报/年累计的"行为数"数据源，新旧单统一）
    var totalDocCount: Int { effectiveDocItems.reduce(0) { $0 + $1.count } }

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



}

// MARK: - 设置（11-28：公证所需文件清单模板按业务类型存放——健哥长期配置，签署单临时引用）

struct AppSettings: Codable, Equatable {
    /// 键 = ServiceType.rawValue；值 = 该类型的默认文件清单（纯名称，份数在单子上填）
    var docTemplates: [String: [String]] = [:]
    /// 健哥 2026-11-28 二轮②：自定义业务类型的名字（如"离婚公证"——相当于自己新增业务类型）
    var customTypeName: String = ""

    init(docTemplates: [String: [String]] = [:], customTypeName: String = "") {
        self.docTemplates = docTemplates
        self.customTypeName = customTypeName
    }

    // 🔴旧档 settings 是空对象{}，合成解码遇缺键会整体抛错→load()回落失败→数据清空；
    // 手写容错：缺键/类型不对都给默认值，绝不让设置字段炸掉整个存档。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        docTemplates = (try? c.decode([String: [String]].self, forKey: .docTemplates)) ?? [:]
        customTypeName = (try? c.decode(String.self, forKey: .customTypeName)) ?? ""
    }

    /// 类型显示名（自定义=用户起的名，没起名回落"自定义"）
    func typeName(_ t: ServiceType) -> String {
        if t == .other {
            let n = customTypeName.trimmingCharacters(in: .whitespaces)
            return n.isEmpty ? ServiceType.other.display : n
        }
        return t.display
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

    /// 某业务类型的文件清单模板（没配置过给空——设置页里现编）
    static func docTemplate(for type: ServiceType, in data: Data) -> [String] {
        data.settings.docTemplates[type.rawValue] ?? []
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
