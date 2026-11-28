import SwiftUI

// MARK: - 公证所需文件设置页（健哥 2026-11-28）
// 长期配置：按业务类型自编文件清单（增删改名），新签署单选类型时带出。
// 与新签署单解耦——签署单是临时的，这里是长期的。

struct DocTemplateSettingsView: View {
    @Binding var data: Store.Data
    @State private var type: ServiceType = .loan
    @State private var newDocName = ""

    /// 当前类型的清单（没配置过给行业常见预设，第一次进来就能看到样子）
    private var docs: [String] {
        if let saved = data.settings.docTemplates[type.rawValue] { return saved }
        return DocTemplateSettingsView.defaultTemplate(for: type)
    }

    /// 行业常见默认（仅首次展示，改过就以用户自己的为准）
    static func defaultTemplate(for t: ServiceType) -> [String] {
        switch t {
        case .loan: return [L("Loan docs", "借款文件"), L("Trust docs", "信托文件"), L("Other acts", "其他行为")]
        case .estate: return [L("Trust docs", "信托文件"), L("POA", "授权委托书"), L("Will", "遗嘱")]
        default: return []
        }
    }

    var body: some View {
        Form {
            Section {
                Picker(L("Business type", "业务类型"), selection: $type) {
                    ForEach(ServiceType.allCases, id: \.self) { t in
                        Text("\(t.emoji) \(t.display)").tag(t)
                    }
                }
            } header: {
                Text(L("Pick a type, then edit its document list", "选类型，编它对应的文件清单"))
            } footer: {
                Text(L("When you pick this type on a new signing, this list appears for counting. Always verify what the case actually needs.", "新签署单选这个类型时，会带出这份清单让你填份数。请核查该案实际所需。"))
            }

            Section(L("Required documents", "公证所需文件")) {
                if docs.isEmpty {
                    Text(L("Empty — add the documents this type usually needs.", "空——把这类业务常带的文件加进来。"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                ForEach(Array(docs.enumerated()), id: \.offset) { i, name in
                    HStack {
                        TextField(L("Document name", "文件名"), text: bindingFor(i))
                        Button(role: .destructive) {
                            remove(at: i)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }
                HStack {
                    TextField(L("Add document…", "新增文件…"), text: $newDocName)
                    Button {
                        add()
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(.indigo)
                    }
                    .disabled(newDocName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle(L("Notary Documents", "公证所需文件"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 按下标改名单（TextField 双向绑定），改完即写回存储
    private func bindingFor(_ i: Int) -> Binding<String> {
        Binding(
            get: { i < docs.count ? docs[i] : "" },
            set: { newName in
                var arr = data.settings.docTemplates[type.rawValue] ?? DocTemplateSettingsView.defaultTemplate(for: type)
                guard i < arr.count else { return }
                arr[i] = newName
                data.settings.docTemplates[type.rawValue] = arr
                Store.save(data)
            }
        )
    }

    private func add() {
        let name = newDocName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var arr = data.settings.docTemplates[type.rawValue] ?? DocTemplateSettingsView.defaultTemplate(for: type)
        arr.append(name)
        data.settings.docTemplates[type.rawValue] = arr
        Store.save(data)
        newDocName = ""
    }

    private func remove(at i: Int) {
        var arr = data.settings.docTemplates[type.rawValue] ?? DocTemplateSettingsView.defaultTemplate(for: type)
        guard i < arr.count else { return }
        arr.remove(at: i)
        data.settings.docTemplates[type.rawValue] = arr
        Store.save(data)
    }
}
