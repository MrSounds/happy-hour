import SwiftUI

struct DayEditorView: View {
    typealias AddToCalendarHandler = @MainActor (Weekday) -> Void

    @State private var model: DayEditorModel
    private let addToCalendarHandler: AddToCalendarHandler?

    @Environment(\.dismiss) private var dismiss

    init(
        draft: DayPlanDraft,
        onSave: @escaping DayEditorModel.SaveHandler,
        onRemove: DayEditorModel.RemoveHandler? = nil,
        onAddToCalendar: AddToCalendarHandler? = nil
    ) {
        addToCalendarHandler = onAddToCalendar
        _model = State(
            initialValue: DayEditorModel(
                draft: draft,
                onSave: onSave,
                onRemove: onRemove
            )
        )
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                timeSection(model: model)
                activitiesSection(model: model)

                if addToCalendarHandler != nil {
                    calendarSection(model: model)
                }

                if model.canRemovePlan {
                    removalSection(model: model)
                }
            }
            .disabled(model.isSaving || model.isRemoving)
            .scrollContentBackground(.hidden)
            .background(HappyHourTheme.background)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(
                "Rediger \(model.draft.weekday.happyHourDisplayName.lowercased())"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        attemptDismiss()
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(model.isSaving || model.isRemoving)
                    .accessibilityIdentifier("editor-cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await model.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        if model.isSaving {
                            ProgressView()
                                .accessibilityLabel("Lagrer")
                        } else {
                            Text("Lagre")
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("editor-save")
                }
            }
        }
        .happyHourScreenBackground()
        .background {
            InteractiveDismissGuard(
                isDisabled: model.hasUnsavedChanges || model.isSaving || model.isRemoving,
                onAttempt: {
                    guard !model.isSaving, !model.isRemoving else { return }
                    model.showsDiscardConfirmation = true
                }
            )
        }
        .alert("Forkaste endringene?", isPresented: $model.showsDiscardConfirmation) {
            Button("Behold redigering", role: .cancel) {}
            Button("Forkast", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Endringene dine er ikke lagret.")
        }
        .alert("Fjern Happy Hour?", isPresented: $model.showsRemoveConfirmation) {
            Button("Avbryt", role: .cancel) {}
            Button("Fjern", role: .destructive) {
                Task {
                    if await model.removePlan() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(
                String(
                    "Planen for "
                        + model.draft.weekday.happyHourDisplayName.lowercased()
                        + " fjernes. "
                )
                    + "Dette påvirker ikke kalenderhendelser du allerede har lagt til."
            )
        }
        .alert(
            "Kunne ikke lagre",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .accessibilityIdentifier("day-editor")
    }

    @ViewBuilder
    private func calendarSection(model: DayEditorModel) -> some View {
        Section {
            Button {
                Task {
                    let weekday = model.draft.weekday
                    if await model.save() {
                        addToCalendarHandler?(weekday)
                        dismiss()
                    }
                }
            } label: {
                Label("Legg til i kalender", systemImage: "calendar.badge.plus")
                    .frame(minHeight: 44)
            }
            .disabled(!model.canSave)
            .accessibilityHint(
                "Lagrer planen og åpner Apples kalenderredigering."
            )
            .accessibilityIdentifier("editor-add-to-calendar-button")
        } header: {
            Text("Kalender")
        } footer: {
            Text(
                "Oppretter én hendelse. Senere endringer i planen synkroniseres ikke."
            )
        }
    }

    @ViewBuilder
    private func timeSection(model: DayEditorModel) -> some View {
        Section {
            DatePicker(
                "Starter",
                selection: startTimeBinding(model: model),
                displayedComponents: .hourAndMinute
            )
            .accessibilityIdentifier("start-time-picker")

            DatePicker(
                "Slutter",
                selection: endTimeBinding(model: model),
                displayedComponents: .hourAndMinute
            )
            .accessibilityIdentifier("end-time-picker")

            VStack(alignment: .leading, spacing: 4) {
                Text(model.durationText)
                    .font(.subheadline.weight(.medium))

                if model.draft.endsNextDay {
                    Text("Slutter neste dag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        } header: {
            Text("Tid")
        } footer: {
            Text("Når starttiden endres, beholdes den valgte varigheten.")
        }
    }

    @ViewBuilder
    private func activitiesSection(model: DayEditorModel) -> some View {
        @Bindable var model = model

        Section {
            ForEach($model.draft.activities) { $activity in
                ActivityDraftRow(activity: $activity)
                    .deleteDisabled(model.draft.activities.count <= 1)
            }
            .onDelete(perform: model.removeActivities)
            .onMove(perform: model.moveActivities)

            Button {
                model.addActivity()
            } label: {
                Label("Legg til aktivitet", systemImage: "plus")
                    .frame(minHeight: 44)
            }
            .disabled(!model.canAddActivity)
            .accessibilityIdentifier("add-activity-button")

            if !model.canAddActivity {
                Text("Du har lagt til maksimalt ti aktiviteter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Aktiviteter")
        } footer: {
            if let validationMessage = model.validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Kan ikke lagre. \(validationMessage)")
            } else {
                Text("Dra håndtaket for å endre rekkefølge.")
            }
        }
    }

    @ViewBuilder
    private func removalSection(model: DayEditorModel) -> some View {
        Section {
            Button(role: .destructive) {
                model.showsRemoveConfirmation = true
            } label: {
                if model.isRemoving {
                    ProgressView()
                } else {
                    Text(
                        "Fjern Happy Hour for "
                            + "\(model.draft.weekday.happyHourDisplayName.lowercased())"
                    )
                        .frame(minHeight: 44)
                }
            }
            .disabled(model.isSaving || model.isRemoving)
            .accessibilityIdentifier("remove-day-plan-button")
        }
    }

    private func attemptDismiss() {
        guard !model.isSaving, !model.isRemoving else { return }
        if model.hasUnsavedChanges {
            model.showsDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func startTimeBinding(model: DayEditorModel) -> Binding<Date> {
        Binding(
            get: { Self.date(for: model.draft.startMinuteOfDay) },
            set: { model.setStartMinute(Self.minuteOfDay(from: $0)) }
        )
    }

    private func endTimeBinding(model: DayEditorModel) -> Binding<Date> {
        Binding(
            get: { Self.date(for: model.draft.endMinuteOfDay) },
            set: { model.setEndMinute(Self.minuteOfDay(from: $0)) }
        )
    }

    private static func date(for minuteOfDay: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.timeZone = TimeZone.autoupdatingCurrent
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = minuteOfDay / 60
        components.minute = minuteOfDay % 60
        return components.date ?? .now
    }

    private static func minuteOfDay(from date: Date) -> Int {
        let components = Calendar.autoupdatingCurrent.dateComponents(
            [.hour, .minute],
            from: date
        )
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

private struct ActivityDraftRow: View {
    @Binding var activity: ActivityDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(HappyHourTheme.activityColor(for: activity.colorToken))
                    .frame(width: 7, height: 32)
                    .accessibilityHidden(true)

                TextField("Navn på aktivitet", text: $activity.name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onChange(of: activity.name) { _, newValue in
                        activity.name = String(
                            newValue.prefix(DayPlanValidator.maximumNameLength)
                        )
                    }
                    .accessibilityLabel("Aktivitetsnavn")
            }

            TextField(
                "Valgfrie notater eller tips",
                text: $activity.details,
                axis: .vertical
            )
            .lineLimit(2...6)
            .onChange(of: activity.details) { _, newValue in
                activity.details = String(
                    newValue.prefix(DayPlanValidator.maximumDetailsLength)
                )
            }
            .accessibilityLabel("Valgfrie notater eller tips for \(activity.name)")

            Text("\(activity.details.count)/\(DayPlanValidator.maximumDetailsLength)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .contain)
    }
}
