# -*- coding: utf-8 -*-
"""v1.3 补丁：①列表行显示净利 ②逾期警示条点进逾期列表 ③逾期单可改已收+同步评级 ④列表左滑删除"""
import io, re

f = 'NotaryTrack/NotaryTrackApp.swift'
src = io.open(f, encoding='utf-8').read()

# ===== 1. 逾期警示条改 NavigationLink =====
pat = re.compile(
    r'( *)Label\("\$\(monthSummary\.overdueCount\)[^)]*specifier: \\"%\.0f\\"\)\(超30天\)",\s*\n'
    r'.*?systemImage: "clock\.badge\.exclamationmark\.fill"\)\s*\n'
    r'.*?\.font\(\.footnote\)\s*\n'
    r'.*?\.foregroundColor\(\.red\)'
)
m = pat.search(src)
assert m, 'warn label regex miss'
indent = m.group(1)
new_warn = (
    indent + 'NavigationLink(destination: OverdueListView(overdue: overdueSignings, data: $data)) {\n' +
    indent + '    Label("\\(monthSummary.overdueCount) 单逾期未收，合计 $\\(monthSummary.overdueAmount, specifier: \\"%.0f\\")（超30天）",\n' +
    indent + '          systemImage: "clock.badge.exclamationmark.fill")\n' +
    indent + '        .font(.footnote)\n' +
    indent + '        .foregroundColor(.red)\n' +
    indent + '}'
)
src = src[:m.start()] + new_warn + src[m.end():]
print('1. warn -> NavigationLink OK')

# ===== 2. overdueSignings 属性 =====
if 'var overdueSignings' not in src:
    anchor = """            overdue.reduce(0) { $0 + $1.fee },
            overdue.count
        )
    }"""
    assert anchor in src, 'summary anchor miss'
    src = src.replace(anchor, anchor + """

    /// 健哥令③：全部逾期单（账龄>0，按逾期天数降序）
    var overdueSignings: [Signing] {
        data.signings.filter { $0.agingLevel > 0 }.sorted { $0.unpaidDays > $1.unpaidDays }
    }""")
    print('2. overdueSignings OK')

# ===== 3. 列表行加净利 =====
old_row = 'Text("$\\(s.fee, specifier: \\"%.0f\\")")\n                                            Text("· \\(s.mileage, specifier: \\"%.0f\\") mi")'
new_row = 'Text("$\\(s.fee, specifier: \\"%.0f\\")")\n                                            Text("· 净利 $\\(s.netProfit, specifier: \\"%.0f\\")")\n                                            Text("· \\(s.mileage, specifier: \\"%.0f\\") mi")'
assert old_row in src, 'row miss'
src = src.replace(old_row, new_row)
print('3. row net profit OK')

# ===== 4. ForEach 加 onDelete =====
# 锚：签署单列表 ForEach 的 NavigationLink 闭合后（唯一串：二级 caption+foregroundColor 结尾段）
old_tail = """                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("签署单")"""
new_tail = """                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                // 健哥令④：左滑删除
                                .onDelete { offsets in
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
            }
            .navigationTitle("签署单")"""
assert old_tail in src, 'tail miss'
src = src.replace(old_tail, new_tail)
print('4. onDelete OK')

io.open(f, 'w', encoding='utf-8').write(src)
print('part1 ALL DONE')
