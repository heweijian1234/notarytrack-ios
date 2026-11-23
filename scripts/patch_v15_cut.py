# -*- coding: utf-8 -*-
"""v1.5 补丁①：A3净利全线砍除（十资产报告④续做，健哥11-24令"继续弄"）
A5时薪判决v1.4已砍，本轮清残留孤儿注释；driveBufferMinutes保留（排程缓冲非时薪）。
每处替换带assert，缺配即停——防card-batch事故重演。
"""
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios"

def patch(path, pairs):
    p = ROOT + "\\" + path
    src = open(p, encoding="utf-8").read()
    for i, (old, new) in enumerate(pairs):
        n = src.count(old)
        assert n >= 1, f"{path} 第{i+1}处未命中: {old[:60]!r}"
        src = src.replace(old, new)
        print(f"  {path} #{i+1} OK (x{n})")
    open(p, "w", encoding="utf-8", newline="\n").write(src)

# ===== NotaryTrackApp.swift =====
patch("NotaryTrack\\NotaryTrackApp.swift", [
    # 列表行净利
    ('            Text("· Net $" + String(format: "%.0f", s.netProfit(supplyCost: 2.50)))\n', ''),
    # 月小结：签名去netProfit字段
    ('tripFees: Double, acts: Int, netProfit: Double, unpaid: Int,',
     'tripFees: Double, acts: Int, unpaid: Int,'),
    # 月小结：supply变量+netProfit计算行
    ('        let supply = data.settings.supplyCostPerSigning\n        return (\n            done.count,\n            done.reduce(0) { $0 + $1.fee },\n            done.reduce(0) { $0 + $1.notaryFeePortion },\n            done.reduce(0) { $0 + $1.taxablePortion },\n            done.reduce(0) { $0 + $1.tripFee },\n            done.reduce(0) { $0 + $1.borrowDocs + $1.trustDocs + $1.otherDocs },\n            done.reduce(0.0) { $0 + $1.netProfit(supplyCost: supply) },',
     '        return (\n            done.count,\n            done.reduce(0) { $0 + $1.fee },\n            done.reduce(0) { $0 + $1.notaryFeePortion },\n            done.reduce(0) { $0 + $1.taxablePortion },\n            done.reduce(0) { $0 + $1.tripFee },\n            done.reduce(0) { $0 + $1.borrowDocs + $1.trustDocs + $1.otherDocs },'),
    # 月Net格
    ('                                StatCell("Net", "$" + String(format: "%.0f", monthSummary.netProfit))\n', ''),
    # 年小结：签名去netProfit
    ('var yearSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double, netProfit: Double) {',
     'var yearSummary: (count: Int, income: Double, notaryPortion: Double, taxablePortion: Double) {'),
    # 年小结：supply变量+计算行
    ('        let supply = data.settings.supplyCostPerSigning\n        return (\n            done.count,\n            done.reduce(0) { $0 + $1.fee },\n            done.reduce(0) { $0 + $1.notaryFeePortion },\n            done.reduce(0) { $0 + $1.taxablePortion },\n            done.reduce(0.0) { $0 + $1.netProfit(supplyCost: supply) }\n        )',
     '        return (\n            done.count,\n            done.reduce(0) { $0 + $1.fee },\n            done.reduce(0) { $0 + $1.notaryFeePortion },\n            done.reduce(0) { $0 + $1.taxablePortion }\n        )'),
    # 年Net格→改Income格（砍净利后年度留收入更有用）
    ('                                StatCell("Net", "$" + String(format: "%.0f", yearSummary.netProfit))',
     '                                StatCell("Income", "$" + String(format: "%.0f", yearSummary.income))'),
    # 详情页净利行
    ('                LabeledRow("Net (after supplies)", "$" + String(format: "%.2f", current.netProfit(supplyCost: data.settings.supplyCostPerSigning)))\n', ''),
    # A5孤儿注释
    ('    // A5 时薪判决（对照 settings.hourlyFloor）\n\n', ''),
    # 导出单：耗材+净利行
    ('        l.append("耗材：$" + String(format: "%.2f", settings.supplyCostPerSigning))\n        l.append("净利：$" + String(format: "%.2f", s.netProfit(supplyCost: settings.supplyCostPerSigning)))\n', ''),
    # 导出月：net计算+总净利行
    ('        let net = done.reduce(0.0) { $0 + $1.netProfit(supplyCost: data.settings.supplyCostPerSigning) }\n', ''),
    ('        l.append("总净利：$" + String(format: "%.0f", net) )\n', ''),
])

# ===== Editors.swift =====
patch("NotaryTrack\\Editors.swift", [
    ('    @State private var supplyCost = 2.50\n', ''),
    ('''                    // 健哥令②：耗材成本自填
                    HStack {
                        Text("Supplies $ (print/paper/ink)")
                        TextField("2.5", value: $supplyCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
''', ''),
    ('Text("Notary portion is exempt from self-employment tax (IRC §1402). Net profit includes supply cost.")',
     'Text("Notary portion is exempt from self-employment tax (IRC §1402).")'),
    ('        data.settings.supplyCostPerSigning = supplyCost   // 记住耗材单价\n', ''),
])

# ===== Store.swift =====
patch("Shared\\Store.swift", [
    ('''    /// A3 净利 = 总费用 + 跑趟费 - 耗材（v1.4 健哥令：里程取消，耗材单价外部传入）
    func netProfit(supplyCost: Double) -> Double {
        fee + tripFee - supplyCost
    }
''', ''),
    ('''// MARK: - 设置（A5 时薪地板 + A3 耗材单价，全局）

struct AppSettings: Codable, Equatable {
    var supplyCostPerSigning: Double  // A3：单均耗材成本（默认 $2.50）

    init(supplyCostPerSigning: Double = 2.50) {
        self.supplyCostPerSigning = supplyCostPerSigning
    }
}''',
     '''// MARK: - 设置（预留：A3耗材/A5时薪已砍11-24；后续Pro设置用）

struct AppSettings: Codable, Equatable {
}'''),
    ('var driveBufferMinutes: Int // A5 分母补全：车程缓冲（分钟）',
     'var driveBufferMinutes: Int // 车程缓冲（分钟）'),
])

print("砍除完成。残留检查：")
import subprocess
r = subprocess.run(["grep", "-rn", "netProfit\\|supplyCost", ROOT + "\\NotaryTrack", ROOT + "\\Shared"],
                   capture_output=True, text=True)
print(r.stdout if r.stdout else "  ✅ 零残留")
