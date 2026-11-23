import Foundation
import StoreKit
import UserNotifications

// MARK: - Pro 买断（健哥11-24拍板"和G一样"：30天试用→$29.99限时锁）
// G仓同款移植——三个坑已踩平：AsyncSequence遍历/VerificationResult解包/await finish。

enum ProStore {
    static let productID = "com.zeronelabs.notarytrack.pro.lifetime"

    /// 是否已解锁
    static var unlocked: Bool {
        UserDefaults.standard.bool(forKey: "notarytrack.pro.unlocked")
    }

    static func markUnlocked() {
        UserDefaults.standard.set(true, forKey: "notarytrack.pro.unlocked")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["notarytrack.trial.endsSoon"])
    }

    /// 购买（StoreKit 2）
    static func purchase() async -> Bool {
        guard let product = try? await Product.products(for: [productID]).first else {
            return false   // 商品没配好（ASC 内购商品未创建/未通过）
        }
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                markUnlocked()
                return true
            }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// 启动时恢复购买（换机/重装场景）
    /// 🔴currentEntitlements元素=VerificationResult<Transaction>，必须解包再取productID
    static func restore() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                markUnlocked()
                return
            }
        }
    }
}
