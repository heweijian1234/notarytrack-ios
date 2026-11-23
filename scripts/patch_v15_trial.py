# -*- coding: utf-8 -*-
"""v1.5 补丁④：试用制闸门（健哥11-24拍板"和G一样"，G同款移植）
RootView横幅+全局付费墙；10处写入口gate；Me页状态行+测试钩子。
"""
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
p = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\NotaryTrack\NotaryTrackApp.swift"
src = open(p, encoding="utf-8").read()

pairs = [
    # Combine导入
    ('import SwiftUI\n', 'import SwiftUI\nimport Combine   // 11-24试用制：全局付费墙通知\n'),
    # RootView整体替换（横幅+全局墙+试用登记+恢复购买）
    ('''struct RootView: View {
    @State private var data = Store.load()
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView(data: $data)
                .tabItem { Label(L("Today", "今日"), systemImage: "calendar") }
                .tag(0)
            SigningListView(data: $data)
                .tabItem { Label(L("Signings", "签署单"), systemImage: "doc.text") }
                .tag(1)
            ClientListView(data: $data)
                .tabItem { Label(L("Clients", "客户"), systemImage: "person.2") }
                .tag(2)
            FeedbackView()
                .tabItem { Label(L("Me", "我的"), systemImage: "person.crop.circle") }
                .tag(3)
        }
        .onAppear { data = Store.load() }
    }
}''',
     '''struct RootView: View {
    @State private var data = Store.load()
    @State private var tab = 0
    // 11-24试用制：全局付费墙（各写入口 TrialStore.gate() 拦截后发通知，这里统一弹）
    @State private var showProPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // 到期只读横幅（坏消息放事前）
            if !TrialStore.canWrite {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(L("Trial ended — records are read-only.", "试用已结束——记录只读。"))
                        .font(.caption)
                    Spacer()
                    Button(L("Unlock", "解锁")) {
                        NotificationCenter.default.post(name: TrialStore.showPaywallNotification, object: nil)
                    }
                    .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.indigo)
            }
            TabView(selection: $tab) {
                TodayView(data: $data)
                    .tabItem { Label(L("Today", "今日"), systemImage: "calendar") }
                    .tag(0)
                SigningListView(data: $data)
                    .tabItem { Label(L("Signings", "签署单"), systemImage: "doc.text") }
                    .tag(1)
                ClientListView(data: $data)
                    .tabItem { Label(L("Clients", "客户"), systemImage: "person.2") }
                    .tag(2)
                FeedbackView()
                    .tabItem { Label(L("Me", "我的"), systemImage: "person.crop.circle") }
                    .tag(3)
            }
        }
        .onAppear {
            data = Store.load()
            TrialStore.registerStartIfNeeded()
            Task { await ProStore.restore() }
        }
        .onReceive(NotificationCenter.default.publisher(for: TrialStore.showPaywallNotification)) { _ in
            showProPaywall = true
        }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
        }
    }
}'''),
    # 今日页菜单：新签署单+委托证
    ('''                        Button { showAdd = true } label: { Label(L("New Signing", "新签署单"), systemImage: "plus") }
                        Button { showCommission = true } label: { Label(L("Commission", "委托证"), systemImage: "credentialing") }''',
     '''                        Button { if TrialStore.gate() { showAdd = true } } label: { Label(L("New Signing", "新签署单"), systemImage: "plus") }
                        Button { if TrialStore.gate() { showCommission = true } } label: { Label(L("Commission", "委托证"), systemImage: "credentialing") }'''),
    # 签署单列表plus（带SigningEditor上下文唯一定位）
    ('''                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                SigningEditor(data: $data, preselectedClientId: nil)
            }''',
     '''                    Button { if TrialStore.gate() { showAdd = true } } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                SigningEditor(data: $data, preselectedClientId: nil)
            }'''),
    # 签署单左滑删除
    ('''                            .onDelete { offsets in
                                for i in offsets {
                                    let target = sortedDesc[i]
                                    data.signings.removeAll { $0.id == target.id }
                                }
                                Store.save(data)
                            }''',
     '''                            .onDelete { offsets in
                                guard TrialStore.gate() else { return }
                                for i in offsets {
                                    let target = sortedDesc[i]
                                    data.signings.removeAll { $0.id == target.id }
                                }
                                Store.save(data)
                            }'''),
    # SigningRow完成/没来
    ('''    private func update(_ st: Signing.Status) {
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {''',
     '''    private func update(_ st: Signing.Status) {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {'''),
    # SigningRow标记已收（无paidDate版=唯一）
    ('''    private func markPaid() {
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
            data.signings[i].paid = true
            Store.save(data)
        }
    }''',
     '''    private func markPaid() {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
            data.signings[i].paid = true
            Store.save(data)
        }
    }'''),
    # 客户左滑删除
    ('.onDelete { data.clients.remove(atOffsets: $0); Store.save(data) }',
     '''.onDelete { offsets in
                            guard TrialStore.gate() else { return }
                            data.clients.remove(atOffsets: offsets); Store.save(data)
                        }'''),
    # 客户列表plus（带ClientEditor上下文唯一定位）
    ('''                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                ClientEditor(data: $data, existing: nil)
            }''',
     '''                    Button { if TrialStore.gate() { showAdd = true } } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { data = Store.load() }) {
                ClientEditor(data: $data, existing: nil)
            }'''),
    # 客户详情编辑铅笔
    ('Button { showEdit = true } label: { Image(systemName: "pencil") }',
     'Button { if TrialStore.gate() { showEdit = true } } label: { Image(systemName: "pencil") }'),
    # 详情页标记已收（带paidDate版）
    ('''    private func markPaid() {
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = true
            data.signings[i].paidDate = Date()
            Store.save(data)
        }
    }''',
     '''    private func markPaid() {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {
            data.signings[i].paid = true
            data.signings[i].paidDate = Date()
            Store.save(data)
        }
    }'''),
    # 详情页改回未收
    ('''    private func markUnpaid() {
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {''',
     '''    private func markUnpaid() {
        guard TrialStore.gate() else { return }
        if let i = data.signings.firstIndex(where: { $0.id == current.id }) {'''),
    # 逾期行内联已收按钮
    ('''                Button {
                    if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
                        data.signings[i].paid = true
                        data.signings[i].paidDate = Date()
                        Store.save(data)
                    }
                } label: {''',
     '''                Button {
                    guard TrialStore.gate() else { return }
                    if let i = data.signings.firstIndex(where: { $0.id == signing.id }) {
                        data.signings[i].paid = true
                        data.signings[i].paidDate = Date()
                        Store.save(data)
                    }
                } label: {'''),
    # FeedbackView状态变量
    ('''struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var sent = false''',
     '''struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var sent = false
    // 11-24试用制测试钩子：版本行连点5下唤出调试区
    @State private var versionTaps = 0
    @State private var showTrialDebug = false
    @State private var debugTick = 0'''),
    # Me页：Pro状态行+版本行测试钩子（插在footer后Form闭包前）
    ('''                } footer: {
                    Text(L("Feedback goes straight to the developer by email. Nothing is stored in the app.", "反馈通过邮件直达开发者，App不留任何数据。"))
                }
            }
            .navigationTitle(L("Me", "我的"))''',
     '''                } footer: {
                    Text(L("Feedback goes straight to the developer by email. Nothing is stored in the app.", "反馈通过邮件直达开发者，App不留任何数据。"))
                }
                // 11-24试用制：状态行（试用期内可点=提前解锁；审核员必须能走到内购）
                Section {
                    Button {
                        if !ProStore.unlocked {
                            NotificationCenter.default.post(name: TrialStore.showPaywallNotification, object: nil)
                        }
                    } label: {
                        HStack {
                            Label("NotaryTrack Pro",
                                  systemImage: (ProStore.unlocked || TrialStore.debugOverride == "unlocked") ? "crown.fill" : (TrialStore.canWrite ? "hourglass" : "lock"))
                                .foregroundColor(.indigo)
                            Spacer()
                            Text(TrialStore.statusText)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Pro")
                } footer: {
                    Text(L("30-day full-feature trial. After it ends: records stay readable free forever; unlock once to keep adding.",
                           "30天全功能试用。到期后：记录永远可看（免费）；解锁一次即可继续新增。"))
                        .font(.caption2)
                }
                // 测试钩子：版本行连点5下唤出试用状态调试（健哥TestFlight实测用）
                Section {
                    Button {
                        versionTaps += 1
                        if versionTaps >= 5 { showTrialDebug.toggle(); versionTaps = 0 }
                    } label: {
                        HStack {
                            Text(L("Version", "版本")).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if showTrialDebug {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("调试：试用状态覆盖（仅测试用，切换后切个Tab刷新横幅）").font(.caption.bold())
                            Text("起点：\\(TrialStore.startDate.map { "\\($0)" } ?? "未登记")｜剩 \\(TrialStore.daysLeft) 天｜覆盖：\\(TrialStore.debugOverride ?? "无")")
                                .font(.caption2).foregroundColor(.secondary)
                            Button("重置为全新试用（30天）") { TrialStore.setDebugOverride("fresh"); debugTick += 1 }
                            Button("强制到期（只读）") { TrialStore.setDebugOverride("expired"); debugTick += 1 }
                            Button("强制已解锁") { TrialStore.setDebugOverride("unlocked"); debugTick += 1 }
                            Button("清除覆盖（恢复真实状态）") { TrialStore.setDebugOverride(nil); debugTick += 1 }
                        }
                        .font(.caption)
                        .id(debugTick)
                    }
                }
            }
            .navigationTitle(L("Me", "我的"))'''),
]

for i, (old, new) in enumerate(pairs):
    n = src.count(old)
    assert n >= 1, f"第{i+1}处未命中: {old[:70]!r}"
    src = src.replace(old, new)
    print(f"#{i+1} OK (x{n})")
open(p, "w", encoding="utf-8", newline="\n").write(src)
print("试用制闸门完成")
