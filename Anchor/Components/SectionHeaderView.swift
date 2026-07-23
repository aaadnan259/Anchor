import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.anchorCaption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.anchorCaption.weight(.semibold))
            }
        }
        .padding(.horizontal, Spacing.base)
    }
}

#Preview {
    SectionHeaderView(title: "Today", actionTitle: "Edit", action: {})
}
