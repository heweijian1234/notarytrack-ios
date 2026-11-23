import Foundation

// MARK: - 双语切换（健哥11-24令：跟随系统语言——中文系统=健哥实测中文，其他=英文上架版）
// 机制与 UricNote/G/H 同源：全部 UI 字符串经 L() 取值；上架只上一份包，不维护两个版本。
// 🔴SOP规则（11-24立）：新App一律做此机制，全英文健哥没法实测。

enum AppLang {
    case en
    case zh

    static let current: AppLang = {
        // 系统首选语言含 zh（简/繁/中国区）即中文
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .zh : .en
    }()
}

func L(_ en: String, _ zh: String) -> String {
    AppLang.current == .en ? en : zh
}
