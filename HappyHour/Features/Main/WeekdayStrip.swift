import SwiftUI

struct WeekdayStrip: View {
    @Binding var selection: Weekday
    @Environment(\.colorSchemeContrast) private var accessibilityContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleStrip
            } else {
                regularStrip
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Velg ukedag")
    }

    private var regularStrip: some View {
        HStack(spacing: 4) {
            ForEach(Weekday.allCases, id: \.self) { weekday in
                dayButton(weekday, expandsToFill: true)
            }
        }
    }

    private var accessibleStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        dayButton(weekday, expandsToFill: false)
                            .id(weekday)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, newSelection in
                if reduceMotion {
                    proxy.scrollTo(newSelection, anchor: .center)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newSelection, anchor: .center)
                    }
                }
            }
        }
    }

    private func dayButton(
        _ weekday: Weekday,
        expandsToFill: Bool
    ) -> some View {
        Button {
            selection = weekday
        } label: {
            dayLabel(weekday, expandsToFill: expandsToFill)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(weekday.happyHourDisplayName)
        .accessibilityValue(selection == weekday ? "Valgt" : "")
        .accessibilityIdentifier("weekday-\(weekday.isoWeekday)")
    }

    @ViewBuilder
    private func dayLabel(
        _ weekday: Weekday,
        expandsToFill: Bool
    ) -> some View {
        let label = Text(shortName(for: weekday))
            .font(.caption.weight(selection == weekday ? .semibold : .regular))
            .foregroundStyle(
                selection == weekday
                    ? HappyHourTheme.selectedDay
                    : HappyHourTheme.primaryText.opacity(
                        accessibilityContrast == .increased ? 0.72 : 0.48
                    )
            )
            .lineLimit(1)
            .fixedSize()

        if expandsToFill {
            label
                .frame(maxWidth: .infinity, minHeight: 44)
                .background { selectedBackground(for: weekday) }
                .contentShape(Rectangle())
        } else {
            label
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
                .background { selectedBackground(for: weekday) }
                .contentShape(Capsule())
        }
    }

    @ViewBuilder
    private func selectedBackground(for weekday: Weekday) -> some View {
        if selection == weekday {
            if dynamicTypeSize.isAccessibilitySize {
                selectedCapsule
            } else {
                selectedCapsule
                    .frame(width: 58, height: 36)
            }
        }
    }

    private var selectedCapsule: some View {
        Capsule()
            .fill(HappyHourTheme.selectedDay.opacity(0.10))
            .overlay {
                Capsule()
                    .stroke(
                        HappyHourTheme.selectedDay.opacity(
                            accessibilityContrast == .increased ? 1 : 0.72
                        ),
                        lineWidth: accessibilityContrast == .increased ? 2 : 1
                    )
            }
            .shadow(
                color: HappyHourTheme.selectedDay.opacity(0.22),
                radius: 7
            )
    }

    private func shortName(for weekday: Weekday) -> String {
        weekday.happyHourShortDisplayName
    }
}
