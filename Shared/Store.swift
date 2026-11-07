import Foundation

// MARK: - 数据模型（施工单：N1记账替代Sheet/N2里程报税/N3费用/N5委托证到期/N6行为计数）

struct Client: Codable, Identifiable, Equatable {
    let id: UUID
    var company: String         // 标题公司/签约服务公司名
    var contactName: String     // 贷款官/协调员
    var phone: String
    var email: String
    var notes: String           // 偏好/结算周期/禁忌
    var noShowCount: Int        // 该客户放鸽子（改单/取消没提前说）

    init(id: UUID = UUID(), company: String, contactName: String = "", phone: String = "", email: String = "", notes: String = "", noShowCount: Int = 0) {
        self.id = id
        self.company = company
        self.contactName = contactName
        self.phone = phone
        self.email = email
        self.notes = notes
        self.noShowCount = noShowCount
    }
}

struct Signing: Codable, Identifiable, Equatable {
    let id: UUID
    var clientId: UUID
    var date: Date
    var address: String         // 房产/签署地点
    var fee: Double             // 本单费用（$）
    var mileage: Double         // 实际往返里程（mi，报税扣税依据 N2）
    var minutes: Int            // 预计耗时（分钟）
    var borrowDocs: Int         // 借款合同份数（N6）
    var trustDocs: Int          // 信托文件份数（N6）
    var otherDocs: Int          // 其他公证行为份数（N6）
    var status: Status          // scheduled / done / noshow
    var paid: Bool              // 付款状态（平台拖款痛）
    var note: String

    enum Status: String, Codable { case scheduled, done, noshow }

    init(id: UUID = UUID(), clientId: UUID, date: Date, address: String = "", fee: Double = 0,
         mileage: Double = 0, minutes: Int = 60, borrowDocs: Int = 0, trustDocs: Int = 0, otherDocs: Int = 0,
         status: Status = .scheduled, paid: Bool = false, note: String = "") {
        self.id = id
        self.clientId = clientId
        self.date = date
        self.address = address
        self.fee = fee
        self.mileage = mileage
        self.minutes = minutes
        self.borrowDocs = borrowDocs
        self.trustDocs = trustDocs
        self.otherDocs = otherDocs
        self.status = status
        self.paid = paid
        self.note = note
    }
}

// MARK: - 委托证（N5：到期提醒，存全局设置）

struct Commission: Codable, Equatable {
    var holderName: String      // 持证人姓名
    var state: String           // 州（如 CA / TX）
    var expiry: Date            // 委托证到期日
    var commissionNumber: String

    init(holderName: String = "", state: String = "", expiry: Date = Date(), commissionNumber: String = "") {
        self.holderName = holderName
        self.state = state
        self.expiry = expiry
        self.commissionNumber = commissionNumber
    }

    /// 距到期天数（负数=已过期）
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expiry)).day ?? 0
    }
}

// MARK: - 存储（UserDefaults + Codable，全本地零账号）

enum Store {
    static let key = "notarytrack.data.v1"

    struct Data: Codable {
        var clients: [Client] = []
        var signings: [Signing] = []
        var commission: Commission? = nil
    }

    static func load() -> Data {
        guard let raw = UserDefaults.standard.data(forKey: key),
              let d = try? JSONDecoder().decode(Data.self, from: raw) else { return Data() }
        return d
    }

    static func save(_ d: Data) {
        if let raw = try? JSONEncoder().encode(d) {
            UserDefaults.standard.set(raw, forKey: key)
        }
    }
}
