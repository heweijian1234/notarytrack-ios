# -*- coding: utf-8 -*-
"""括号平衡+残留引用自检（去字符串/注释后计数）"""
import re, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
src = open(r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\NotaryTrack\NotaryTrackApp.swift", encoding="utf-8").read()
no_str = re.sub(r'"(?:[^"\\]|\\.)*"', '""', src)
no_com = re.sub(r'//[^\n]*', '', no_str)
print("花括号:", no_com.count("{"), no_com.count("}"), "圆括号:", no_com.count("("), no_com.count(")"))
print("showCommission残留:", src.count("showCommission"))
today = src.split("struct SigningRow")[0].split("struct TodayView")[1]
print("TodayView showAdd残留:", today.count("showAdd"))
