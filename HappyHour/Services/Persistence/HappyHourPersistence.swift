import SwiftData

enum HappyHourPersistence {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HappyHourSchemaV1.self)
        let configuration = ModelConfiguration(
            "HappyHour",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: HappyHourMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
