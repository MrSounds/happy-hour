import SwiftUI

struct WeekPagerView: View {
    let plans: [DayPlanModel]
    @Binding var selectedWeekday: Weekday
    let activeWeekdays: Set<Weekday>
    let onEdit: (Weekday) -> Void
    let onOpenSettings: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header

            WeekdayStrip(selection: $selectedWeekday)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)

            TabView(selection: $selectedWeekday) {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    DayPlanPage(
                        weekday: weekday,
                        plan: plan(for: weekday),
                        isActive: activeWeekdays.contains(weekday)
                    )
                    .tag(weekday)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: selectedWeekday)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .happyHourScreenBackground()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .light))
                    .accessibilityHidden(true)
            }
            .buttonStyle(HappyHourIconButtonStyle())
            .accessibilityLabel("Innstillinger")
            .accessibilityIdentifier("settings-button")

            Text("Happy Hour")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(HappyHourTheme.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("main-title")

            Button {
                onEdit(selectedWeekday)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 24, weight: .light))
                    .accessibilityHidden(true)
            }
            .buttonStyle(HappyHourIconButtonStyle())
            .accessibilityLabel(
                "Rediger \(selectedWeekday.happyHourDisplayName.lowercased())"
            )
            .accessibilityIdentifier("edit-day-button")
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func plan(for weekday: Weekday) -> DayPlanModel? {
        plans.first { $0.weekday == weekday }
    }
}

private struct DayPlanPage: View {
    let weekday: Weekday
    let plan: DayPlanModel?
    let isActive: Bool

    @State private var selectedActivity: ActivityModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                timeHeading

                ActivityBeerMugView(
                    activities: configuredPlan?.sortedActivities ?? [],
                    onShowDetails: { selectedActivity = $0 },
                    emptyMessage: configuredPlan == nil
                        ? "Ingen Happy Hour planlagt for "
                            + weekday.happyHourDisplayName.lowercased()
                        : nil
                )
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 2)
            .padding(.top, 4)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailSheet(activity: activity)
        }
        .accessibilityLabel(
            "\(weekday.happyHourDisplayName), side \(weekday.isoWeekday) av 7"
        )
    }

    private var configuredPlan: DayPlanModel? {
        guard let plan, plan.isConfigured else { return nil }
        return plan
    }

    private var timeHeading: some View {
        VStack(spacing: 6) {
            if let plan = configuredPlan {
                Text(HappyHourTimeText.range(for: plan))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(HappyHourTheme.primaryText)
                    .lineLimit(1)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 48)
                    .background(timeCapsule)
                    .accessibilityLabel(
                        "\(weekday.happyHourDisplayName), "
                            + HappyHourTimeText.range(for: plan)
                    )

                if plan.endDayOffset == 1 {
                    Text("Slutter neste dag")
                        .font(.caption)
                        .foregroundStyle(HappyHourTheme.tertiaryText)
                }
            } else {
                Text("Ingen tid valgt")
                    .font(.title3)
                    .foregroundStyle(HappyHourTheme.tertiaryText)
                    .lineLimit(1)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 48)
                    .background(timeCapsule)
                    .accessibilityLabel(
                        "\(weekday.happyHourDisplayName), ingen tid valgt"
                    )
            }

            if isActive {
                Text("Nå")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 24)
                    .background(
                        Capsule()
                            .fill(HappyHourTheme.dustySage.opacity(0.28))
                    )
                    .accessibilityLabel("Happy Hour pågår nå")
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }

    private var timeCapsule: some View {
        Capsule()
            .fill(HappyHourTheme.raisedSurface.opacity(0.72))
            .overlay {
                Capsule()
                    .stroke(HappyHourTheme.hairline, lineWidth: 1)
            }
            .shadow(
                color: HappyHourTheme.amberGlow.opacity(0.10),
                radius: 8,
                y: 2
            )
    }
}

enum HappyHourTimeText {
    static func range(for plan: DayPlanModel) -> String {
        let start = time(for: plan.startMinuteOfDay)
        let end = time(for: plan.endMinuteOfDay)
        return "\(start)–\(end)"
    }

    static func time(for minuteOfDay: Int) -> String {
        let clampedMinute = min(max(minuteOfDay, 0), 1_439)
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.timeZone = TimeZone.autoupdatingCurrent
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = clampedMinute / 60
        components.minute = clampedMinute % 60

        guard let date = components.date else {
            return String(format: "%02d:%02d", clampedMinute / 60, clampedMinute % 60)
        }

        return date.formatted(date: .omitted, time: .shortened)
    }
}
