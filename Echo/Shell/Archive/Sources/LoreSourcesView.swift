import SwiftUI

/// Sources stay inside an already recovered entry, never an interrupting modal.
struct LoreSourcesView: View {
    let act: Act

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text(Copy.text("lore.sources.note"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(LoreReference.references(for: act)) { reference in
                    Link(destination: reference.url) {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(Copy.text("lore.source.\(reference.kind.rawValue)"))
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(EchoTheme.gold)
                                Text(reference.title)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "arrow.up.right")
                        }
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label(Copy.text("lore.sources"), systemImage: "text.book.closed")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .tint(EchoTheme.cyan)
    }
}
