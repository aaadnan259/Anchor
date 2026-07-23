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

    @Binding var selection: String
    let tint: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5)

    var body: some View {
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

#Preview {
    IconPickerView(selection: .constant("dumbbell.fill"), tint: AccentColor.coral.color)
        .padding()
}
