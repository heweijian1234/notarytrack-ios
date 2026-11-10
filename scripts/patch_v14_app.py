# -*- coding: utf-8 -*-
"""v1.4 补丁 part2：NotaryTrackApp.swift（13处 mileage/hourly/netProfit 引用清理+年度累计+税预估）"""
import io, re, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

f = 'NotaryTrack/NotaryTrackApp.swift'
src = io.open(f, encoding='utf-8').read()

# ===== 1. TodayView 空态文案（85行）=====
src = src.replace(
    'Text("先加客户（标题公司），再录签署单。费用、里程、公证行为数，一单不漏。")',
    'Text(L("Add clients (title companies) first, then log signings. Fees, trip fees, notarial acts — nothing missed.", "先加客户（标题公司），再录签署单。费用、跑趟费、公证行为数，一单不漏。"))')

# ===== 2. SigningRow 里程 Label（197行）=====
src = src.replace(
    'Label("\\(signing.mileage, specifier: \\"%.0f\\") mi", systemImage: "car")',
    'Label("跑趟费 $" + String(format: "%.0f", signing.tripFee), systemImage: "car")')

# ===== 3. SigningRowMetrics 里程段（268行区域）=====
old_metrics = """    var body: some View {
        HStack(spacing: 8) {
            Text("$" + String(format: "%.0f", s.fee))
            Text("· 净利 $" + String(format: "%.0f", s.netProfit))
            Text("· " + String(format: "%.0f", s.mileage) + " mi")
            Text("· " + (s.paid ? "已收" : "未收"))
            Circle()
                .fill(verdict)
                .frame(width: 8, height: 8)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }"""
new_metrics = """    var body: some View {
        HStack(spacing: 8) {
            Text("$" + String(format: "%.0f", s.fee))
            if s.tripFee > 0 {
                Text("· 跑趟费 $" + String(format: "%.0f", s.tripFee))
            }
            Text("· " + (s.paid ? "已收" : "未收"))
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }"""
assert old_metrics in src, 'metrics miss'
src = src.replace(old_metrics, new_metrics)
print('3. SigningRowMetrics OK')

# ===== 4. SigningListRow verdictColor 参数删（判决没了）=====
src = src.replace(
    'SigningListRow(s: s, data: $data, sortedDesc: sortedDesc, verdictColor: verdictColor)',
    'SigningListRow(s: s, data: $data, sortedDesc: sortedDesc)')
src = src.replace(
    '''struct SigningListRow: View {
    let s: Signing
    @Binding var data: Store.Data
    let sortedDesc: [Signing]
    let verdictColor: (Signing) -> Color''',
    '''struct SigningListRow: View {
    let s: Signing
    @Binding var data: Store.Data
    let sortedDesc: [Signing]''')
print('4. SigningListRow verdictColor 参数删 OK')

# ===== 5. SigningListView verdictColor 方法删 =====
old_vc = """    /// A5 时薪判决色（对照 settings.hourlyFloor）
    private func verdictColor(_ s: Signing) -> Color {
        let floor = data.settings.hourlyFloor
        if s.hourlyNet >= floor { return .green }
        if s.hourlyNet >= floor * 0.8 { return .yellow }
        return .red
    }
"""
if old_vc in src:
    src = src.replace(old_vc, '')
    print('5. verdictColor 方法删 OK')
else:
    print('5. verdictColor 变体未匹配——搜实际写法')

# ===== 6. monthSummary 简化+年度累计 =====
old_ms = """    /// 本月小结 v2（A1账龄/A3净利/A4免税拆分/A7跑趟费/A8类型 全并入）
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
    }"""
new_ms = """    /// 本月小结 v3（健哥令：删里程删净利；保留账龄/免税拆分/跑趟费）
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
    var yearSummary: (count: Int, notaryPortion: Double, taxablePortion: Double) {
        let cal = Calendar.current
        let done = data.signings.filter { $0.status == .done && cal.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        return (
            done.count,
            done.reduce(0) { $0 + $1.notaryFeePortion },
            done.reduce(0) { $0 + $1.taxablePortion }
        )
    }"""
assert old_ms in src, 'monthSummary miss'
src = src.replace(old_ms, new_ms)
print('6. monthSummary v3 + yearSummary OK')

io.open(f, 'w', encoding='utf-8').write(src)
print('PART2-A DONE')
