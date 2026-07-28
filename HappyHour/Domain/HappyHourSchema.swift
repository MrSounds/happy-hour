import SwiftData

enum HappyHourSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            DayPlanModel.self,
            ActivityModel.self,
        ]
    }
}

enum HappyHourMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HappyHourSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
