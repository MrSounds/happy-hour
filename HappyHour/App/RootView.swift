import Combine
import SwiftUI
import UIKit

struct RootView: View {
    @Bindable var model: AppModel

    @Environment(\.scenePhase) private var scenePhase
    private let activeStateTimer = Timer.publish(
        every: 30,
        on: .main,
        in: .common
    )
    .autoconnect()

    var body: some View {
        decoratedContent
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if !model.isReady {
                ProgressView()
                    .tint(HappyHourTheme.primaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .happyHourScreenBackground()
            } else if !model.hasCompletedOnboarding {
                OnboardingView(
                    today: model.selectedWeekday,
                    onCreateFirstPlan: model.startFirstPlan,
                    onSkip: model.skipOnboarding
                )
            } else {
                WeekPagerView(
                    plans: model.plans,
                    selectedWeekday: $model.selectedWeekday,
                    activeWeekdays: model.activeWeekdays,
                    onEdit: model.edit,
                    onOpenSettings: { model.isShowingSettings = true }
                )
            }
        }
    }

    private var lifecycleContent: some View {
        rootContent
        .task {
            await model.bootstrap()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.significantTimeChangeNotification
            )
        ) { _ in
            handleSignificantTimeChange()
        }
        .onReceive(activeStateTimer) { _ in
            model.refreshActiveState()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name.NSSystemTimeZoneDidChange
            )
        ) { _ in
            handleSignificantTimeChange()
        }
    }

    private var presentationContent: some View {
        lifecycleContent
        .fullScreenCover(
            item: $model.editingWeekday,
            onDismiss: model.editorDidDismiss
        ) { weekday in
            DayEditorView(
                draft: model.draft(for: weekday),
                onSave: model.save,
                onRemove: model.removePlan,
                onAddToCalendar: model.queueCalendarAfterEditorDismiss
            )
        }
        .fullScreenCover(
            isPresented: $model.isShowingNotificationPrimer,
            onDismiss: model.notificationPrimerDidDismiss
        ) {
            NotificationPermissionPrimerView(
                onEnable: model.requestNotifications,
                onNotNow: model.skipNotificationPrimer
            )
        }
        .sheet(isPresented: $model.isShowingSettings) {
            SettingsView(
                notificationState: model.notificationPresentationState,
                canRequestNotifications: model.hasConfiguredPlan,
                onRequestNotifications: model.requestNotifications,
                onOpenSystemSettings: model.openSystemSettings,
                onDone: { model.isShowingSettings = false }
            )
        }
        .sheet(item: $model.calendarPresentation) { presentation in
            CalendarEventEditView(
                event: presentation.event,
                eventStore: presentation.store,
                onCompletion: model.finishCalendarEditing
            )
            .ignoresSafeArea()
        }
    }

    private var decoratedContent: some View {
        presentationContent
        .alert(
            "Noe gikk galt",
            isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 { model.clearAlert() } }
            )
        ) {
            Button("OK", role: .cancel, action: model.clearAlert)
        } message: {
            Text(model.alertMessage ?? "")
        }
        .overlay(alignment: .top) {
            if let message = model.transientMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HappyHourTheme.activityText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(HappyHourTheme.sand)
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        guard newPhase == .active else { return }
        Task {
            await model.sceneBecameActive()
        }
    }

    private func handleSignificantTimeChange() {
        Task {
            await model.significantTimeDidChange()
        }
    }
}
