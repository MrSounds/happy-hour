import SwiftUI

struct ActivityDetailSheet: View {
    let activity: ActivityModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HappyHourTheme.activityColor(for: activity.colorToken))
                            .frame(width: 8, height: 34)
                            .accessibilityHidden(true)

                        Text(activity.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(HappyHourTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(detailText)
                        .font(.body)
                        .foregroundStyle(
                            hasDetails
                                ? HappyHourTheme.primaryText
                                : HappyHourTheme.secondaryText
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(HappyHourTheme.background)
            .navigationTitle("Aktivitetsdetaljer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") {
                        dismiss()
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
    }

    private var hasDetails: Bool {
        !(activity.details ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private var detailText: String {
        hasDetails ? (activity.details ?? "") : "Ingen notater lagt til."
    }
}
