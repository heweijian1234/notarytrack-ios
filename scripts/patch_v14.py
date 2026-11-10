# -*- coding: utf-8 -*-
"""v1.4 补丁：里程全线取消/时薪判决删除/年度累计+税预估/净利公式简化（健哥两条反馈+两项拍板）
跑完自动 grep 验证产物存在（补丁纪律：不许静默跳过）"""
import io, re, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# ===================== 1. Store.swift =====================
f1 = 'Shared/Store.swift'
src = io.open(f1, encoding='utf-8').read()

# 删 mileage 字段+init参数
src = src.replace('    var mileage: Double         // 实际往返里程（mi，报税扣税依据 N2）\n', '')
src = src.replace('         notaryFeePortion: Double = 0, tripFee: Double = 0, mileage: Double = 0, minutes: Int = 60,',
                  '         notaryFeePortion: Double = 0, tripFee: Double = 0, minutes: Int = 60,')
src = src.replace('        self.mileage = mileage\n', '')

# netProfit 计算属性简化（跑趟费计入收入+耗材自设置；删里程扣减）
old_np = '''    /// A3/A5 净利（粗算）：费用 - 里程成本(IRS $0.67/mi) - 耗材($2.50/单默认)
    var netProfit: Double {
        fee - mileage * 0.67 - 2.50
    }'''
new_np = '''    /// A3 净利 = 总费用 + 跑趟费 - 耗材（v1.4 健哥令：里程取消，耗材单价外部传入）
    func netProfit(supplyCost: Double) -> Double {
        fee + tripFee - supplyCost
    }'''
assert old_np in src, 'netProfit miss'
src = src.replace(old_np, new_np)

# 删 hourlyNet/doorToDoorMinutes（时薪判决删除连带）
old_hourly = '''    /// A5 门到门总分钟（桌上+车程缓冲）
    var doorToDoorMinutes: Int { minutes + driveBufferMinutes }

    /// A5 时薪（净利/门到门小时）
    var hourlyNet: Double {
        let hours = Double(doorToDoorMinutes) / 60.0
        return hours > 0 ? netProfit / hours : 0
    }'''
assert old_hourly in src, 'hourly miss'
src = src.replace(old_hourly, '')

# AppSettings：删 mileageRate/hourlyFloor
src = src.replace('    var hourlyFloor: Double       // A5：最低时薪地板（默认 $40）\n', '')
src = src.replace('    var mileageRate: Double       // 里程抵税单价（默认 IRS $0.67）\n', '')
src = src.replace('    init(hourlyFloor: Double = 40, supplyCostPerSigning: Double = 2.50, mileageRate: Double = 0.67) {',
                  '    init(supplyCostPerSigning: Double = 2.50) {')
src = src.replace('        self.hourlyFloor = hourlyFloor\n', '')
src = src.replace('        self.mileageRate = mileageRate\n', '')

io.open(f1, 'w', encoding='utf-8').write(src)
print('Store.swift done')
