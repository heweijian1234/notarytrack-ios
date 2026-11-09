# -*- coding: utf-8 -*-
"""NTExporter 里全部 specifier 插值改 String(format:)（l.append 非Text上下文不支持 specifier）"""
import io, re

f = 'NotaryTrack/NotaryTrackApp.swift'
src = io.open(f, encoding='utf-8').read()

# 通用正则：\(EXPR, specifier: "F") → 直接换 String(format: "F", EXPR) 形式的拼接会破坏引号嵌套。
# 换更稳的思路：这些行全部在 l.append("...") 的 String 内插值。Swift 字符串插值里 specifier 只在 Text 生效。
# 解法：把整行用正则抓出来，逐个插值替换为 String(format:) 拼接。
def convert_line(line):
    # 跳过不含 specifier 的行
    if 'specifier:' not in line:
        return line
    # 逐段处理：把 "前缀\(expr, specifier: "fmt")后缀" 拆成拼接
    # 先提取所有插值段
    pat = re.compile(r'\\\(([^,()]+(?:\([^)]*\))?[^,()]*), specifier: "(%[^"]+)"\)')
    parts = []
    last = 0
    # 找到 l.append( 的字符串起止引号位置
    m0 = re.search(r'l\.append\("', line)
    if not m0:
        return line
    start = m0.end()
    # 找行尾的 ") （字符串结束）
    end = line.rfind('")')
    if end == -1:
        return line
    template = line[start:end]
    # 把模板按插值拆
    segs = []
    pos = 0
    for m in pat.finditer(template):
        segs.append(('lit', template[pos:m.start()]))
        segs.append(('interp', m.group(1).strip(), m.group(2)))
        pos = m.end()
    segs.append(('lit', template[pos:]))
    # 生成拼接表达式
    out_parts = []
    for seg in segs:
        if seg[0] == 'lit':
            out_parts.append('"' + seg[1] + '"')
        else:
            expr, fmt = seg[1], seg[2]
            # expr 里的 \" 已无；fmt 转换
            out_parts.append(f'String(format: "{fmt}", {expr})')
    joined = ' + '.join(p if p.startswith('"') else p for p in out_parts)
    # 处理相邻字面量合并（可选，不合并也能编译）
    return line[:start] + joined + line[end:]

lines = src.split('\n')
changed = 0
for i, ln in enumerate(lines):
    if 'specifier:' in ln and ('l.append' in ln):
        newline = convert_line(ln)
        if newline != ln:
            lines[i] = newline
            changed += 1
src = '\n'.join(lines)
io.open(f, 'w', encoding='utf-8').write(src)
print(f'converted {changed} lines')
