import SwiftUI

struct AccentColorPickerView: View {
    @Binding var selection: AccentColor
    @Binding var customColorHex: UInt?

    @State private var customColor: Color = .gray

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(AccentColor.allCases) { option in
                Button {
                    Haptics.light()
                    customColorHex = nil
                    selection = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 44, height: 44)
                        .overlay {
                            if customColorHex == nil && selection == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue.capitalized)
                .accessibilityAddTraits(customColorHex == nil && selection == option ? [.isSelected] : [])
            }

            ColorPicker("Custom color", selection: $customColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Surface.border, lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .overlay(
                    Image(systemName: customColorHex != nil ? "checkmark" : "plus")
                        .font(.system(size: customColorHex != nil ? 16 : 14, weight: .bold))
                        .foregroundStyle(.white)
                        .allowsHitTesting(false)
                )
                .onChange(of: customColor) { _, newValue in
                    guard let hex = newValue.toHexInt() else { return }
                    Haptics.light()
                    customColorHex = hex
                }
                .accessibilityLabel("Custom color")
                .accessibilityAddTraits(customColorHex != nil ? [.isSelected] : [])
        }
        .onAppear {
            if let customColorHex {
                customColor = Color(hex: customColorHex)
            }
        }
    }
}

#Preview {
    AccentColorPickerView(selection: .constant(.indigo), customColorHex: .constant(nil))
        .padding()
}
