import SwiftUI

// MARK: - 付费墙（健哥11-24拍板"和G一样"：30天试用→$29.99买断限时锁）
// 文案原则（客户不满是落差问题卡）：先说"记录安全"，再说"解锁继续记"——坏消息放事前。
// 双态：试用中=提前解锁（审核员必须能走到内购）；到期=试用结束。
// 注意：NotaryTrack 当前无导出UI，文案不承诺导出（与G不同）。

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var failed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 🔴二轮④：iOS 26 导航栏偶尔不渲染=「暂不」按钮一起消失→退不出去。
                // 关闭按钮放内容区左上角，不依赖导航栏，必显。
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 4)
                    Spacer()
                }
                .frame(height: 36)
                Image(systemName: "lock.open.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.indigo)
                Text(TrialStore.canWrite ? L("Unlock early — skip the wait", "提前解锁——不用等到期") : L("Your 30-day trial has ended", "30天试用已结束"))
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: 10) {
                    if TrialStore.canWrite {
                        Label(L("Trial: \(TrialStore.daysLeft) days left. Unlock now — it's yours forever.", "试用还剩 \(TrialStore.daysLeft) 天。现在解锁，终身拥有。"), systemImage: "hourglass")
                        Label(L("No subscription, no renewal — pay once", "无订阅无续费——一次付清"), systemImage: "checkmark.seal")
                    } else {
                        Label(L("Your records are safe — view them anytime, free forever", "你的记录都在——随时查看，永远免费"), systemImage: "checkmark.shield")
                        Label(L("Unlock once to keep logging signings and adding clients", "解锁一次，继续记签署单、加客户"), systemImage: "doc.badge.plus")
                        Label(L("One-time purchase, yours forever", "一次购买，终身拥有"), systemImage: "checkmark.seal")
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, 24)
                Button {
                    purchasing = true
                    Task {
                        let ok = await ProStore.purchase()
                        purchasing = false
                        if ok { dismiss() } else { failed = true }
                    }
                } label: {
                    Label(purchasing ? L("Processing…", "处理中…") : L("Unlock — $29.99 once", "解锁 — $29.99 一次性"), systemImage: "crown")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(purchasing)
                .padding(.horizontal, 24)
                if failed {
                    Text(L("Purchase didn't complete. If you already bought it, tap Restore.", "购买未完成。如已买过，点恢复购买。"))
                        .font(.caption).foregroundColor(.red)
                }
                Button(L("Restore purchase", "恢复购买")) {
                    Task {
                        await ProStore.restore()
                        if ProStore.unlocked { dismiss() }
                    }
                }
                .font(.subheadline)
                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle(L("Pro", "Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Not now", "暂不")) { dismiss() }
                }
            }
        }
    }
}
