import Foundation

extension Weekday {
    /// Version-one display names match the app's Norwegian interface copy.
    var happyHourDisplayName: String {
        switch self {
        case .monday: "Mandag"
        case .tuesday: "Tirsdag"
        case .wednesday: "Onsdag"
        case .thursday: "Torsdag"
        case .friday: "Fredag"
        case .saturday: "Lørdag"
        case .sunday: "Søndag"
        }
    }

    var happyHourShortDisplayName: String {
        switch self {
        case .monday: "Man"
        case .tuesday: "Tir"
        case .wednesday: "Ons"
        case .thursday: "Tor"
        case .friday: "Fre"
        case .saturday: "Lør"
        case .sunday: "Søn"
        }
    }
}
