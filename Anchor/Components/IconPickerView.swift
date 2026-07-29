import SwiftUI

struct IconPickerView: View {
    static let symbols = [
        "figure.walk", "figure.run", "dumbbell.fill", "briefcase.fill",
        "moon.stars.fill", "book.fill", "drop.fill", "leaf.fill",
        "bed.double.fill", "heart.fill", "cup.and.saucer.fill", "pills.fill",
        "pencil", "paintbrush.fill", "music.note", "guitars.fill",
        "flame.fill", "sparkles", "star.fill", "sun.max.fill",
        "moon.fill", "airplane", "bicycle", "figure.yoga",
        "brain.head.profile", "checklist", "target", "trophy.fill"
    ]

    private enum Mode: String, CaseIterable {
        case symbols = "Symbols"
        case emoji = "Emoji"
    }

    @Binding var selection: String
    let tint: Color

    @State private var mode: Mode = .symbols

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Icon Type", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch mode {
            case .symbols:
                symbolGrid
            case .emoji:
                EmojiIconField(selection: $selection)
            }
        }
        .onAppear {
            mode = selection.isSFSymbolCompatible ? .symbols : .emoji
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(Self.symbols, id: \.self) { symbol in
                Button {
                    Haptics.light()
                    selection = symbol
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(selection == symbol ? .white : tint)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle().fill(selection == symbol ? tint : tint.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(selection == symbol ? [.isSelected] : [])
            }
        }
    }
}

private struct EmojiIconField: View {
    @Binding var selection: String
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TextField("Tap to choose an emoji", text: $text)
                .font(.system(size: 40))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(Spacing.base)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(Surface.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .stroke(Surface.border, lineWidth: 1)
                )
                .onChange(of: text) { _, newValue in
                    guard let last = newValue.last,
                          !last.isASCII,
                          last.unicodeScalars.contains(where: \.properties.isEmoji)
                    else {
                        text = selection.isSFSymbolCompatible ? "" : selection
                        return
                    }
                    text = String(last)
                    selection = String(last)
                }
                .onAppear {
                    text = selection.isSFSymbolCompatible ? "" : selection
                }

            Text("Tap the field, then switch to the emoji keyboard (🌐) to pick one.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    IconPickerView(selection: .constant("dumbbell.fill"), tint: AccentColor.coral.color)
        .padding()
}
