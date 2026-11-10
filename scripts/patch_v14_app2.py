# -*- coding: utf-8 -*-
"""v1.4 补丁 part2-B：月结 UI（删净利/里程格+加年度累计+税预估）+ 空态文案 + 详情页删时薪区"""
import io, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

f = 'NotaryTrack/NotaryTrackApp.swift'
src = io.open(f, encoding='utf-8').read()

# ===== 1. 月结 Section UI 重构 =====
old_ui = """                        Section("本月小结") {
                            HStack {
                                StatCell("单数", "\\(monthSummary.count)")
                                StatCell("收入", "$" + String(format: "%.0f", monthSummary.income))
                                StatCell("净利", "$" + String(format: "%.0f", monthSummary.netProfit))
                                StatCell("里程", String(format: "%.0f", monthSummary.miles) + " mi")
                            }
                            // A4 SE 免税拆分两行
                            HStack(spacing: 16) {
                                Label("公证费(免税) $" + String(format: "%.0f", monthSummary.notaryPortion), systemImage: "checkmark.shield")
                                    .foregroundColor(.green)
                                Label("服务费 $" + String(format: "%.0f", monthSummary.taxablePortion), systemImage: "doc.text")
                            }
                            .font(.caption)
                            if monthSummary.tripFees > 0 {
                                Label("含跑趟费 $" + String(format: "%.0f", monthSummary.tripFees), systemImage: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if monthSummary.unpaid > 0 {
                                Label("\\(monthSummary.unpaid) 单已签未收款", systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }"""
new_ui = """                        Section("本月小结") {
                            HStack {
                                StatCell("单数", "\\(monthSummary.count)")
                                StatCell("收入", "$" + String(format: "%.0f", monthSummary.income))
                                StatCell("跑趟费", "$" + String(format: "%.0f", monthSummary.tripFees))
                                StatCell("公证行为", "\\(monthSummary.acts)")
                            }
                            // A4 SE 免税拆分 + 税预估
                            HStack(spacing: 16) {
                                Label("公证费(免税) $" + String(format: "%.0f", monthSummary.notaryPortion), systemImage: "checkmark.shield")
                                    .foregroundColor(.green)
                                Label("服务费 $" + String(format: "%.0f", monthSummary.taxablePortion), systemImage: "doc.text")
                            }
                            .font(.caption)
                            Label("预估自雇税 $\\(String(format: \\"%.0f\\", monthSummary.taxablePortion * 0.153))（应税部分×15.3%）", systemImage: "percent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if monthSummary.unpaid > 0 {
                                Label("\\(monthSummary.unpaid) 单已签未收款", systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }
                        // 健哥令②：年度累计
                        Section("年度累计（今年至今）") {
                            HStack {
                                StatCell("单数", "\\(yearSummary.count)")
                                StatCell("公证费(免税)", "$" + String(format: "%.0f", yearSummary.notaryPortion))
                                StatCell("服务费(应税)", "$" + String(format: "%.0f", yearSummary.taxablePortion))
                            }
                        }"""
assert old_ui in src, 'month UI miss'
src = src.replace(old_ui, new_ui)
print('1. month UI OK')

# ===== 2. 签署单详情页：删"这单值不值" Section + verdict 系列 + 里程行 =====
old_detail_verdict = """            // A5 时薪判决（A3 净利）
            Section("这单值不值") {
                HStack {
                    Text("净利/小时")
                    Spacer()
                    Text("$" + String(format: "%.0f", current.hourlyNet) + "/h")
                        .foregroundColor(verdictColor)
                }
                HStack {
                    Text("门到门")
                    Spacer()
                    Text("\\(current.doorToDoorMinutes) 分钟")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("判决")
                    Spacer()
                    Text(verdictText)
                        .foregroundColor(verdictColor)
                }
                Text(verdictReason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
"""
assert old_detail_verdict in src, 'detail verdict miss'
src = src.replace(old_detail_verdict, '')
print('2. detail verdict Section 删 OK')

# 详情页里程行
src = src.replace(
    'LabeledRow("里程", String(format: "%.1f", current.mileage) + " mi")\n', '')

# verdictColor/verdictText/verdictReason 方法删（SigningDetailView 内）
import re
pat_vc = re.compile(r'    // A5 时薪判决色（对照 settings\.hourlyFloor）\n    private var verdictColor: Color \{.*?\n    \}\n', re.S)
src, n1 = pat_vc.subn('', src)
pat_vt = re.compile(r'    private var verdictText: String \{.*?\n    \}\n', re.S)
src, n2 = pat_vt.subn('', src)
pat_vr = re.compile(r'    \n    /// 健哥令③：判决理由（为什么值/不值）\n    private var verdictReason: String \{.*?\n    \}', re.S)
src, n3 = pat_vr.subn('', src)
print(f'3. verdict 方法删: color={n1} text={n2} reason={n3}')

# ===== 3. SigningRow 里 mileage Label 已在 part2-A 换成跑趟费；核对 SigningRow 剩余 mileage 引用 =====
import re as re2
residual = [ln for ln in src.split('\n') if 'mileage' in ln and ('Text(' in ln or 'Label(' in ln or 'LabeledRow(' in ln)]
print(f'residual mileage UI refs: {len(residual)}')
for ln in residual:
    print('  ', ln.strip()[:90])

io.open(f, 'w', encoding='utf-8').write(src)
print('PART2-B DONE')
