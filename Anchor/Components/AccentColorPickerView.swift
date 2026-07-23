import SwiftUI

struct AccentColorPickerView: View {
    @Binding var selection: AccentColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(AccentColor.allCases) { option in
                Button {
                    Haptics.light()
                    selection = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 44, height: 44)
                        .overlay {
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue.capitalized)
                .accessibilityAddTraits(selection == option ? [.isSelected] : [])
            }
        }
    }
}

#Preview {
    AccentColorPickerView(selection: .constant(.indigo))
        .padding()
}
