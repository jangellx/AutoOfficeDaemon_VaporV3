import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    services.register(migrations)

    // IP and port ( https://stackoverflow.com/questions/48450239/changing-hostname-and-port-with-vapor-3 )
    let serverConfiure = NIOServerConfig.default(hostname: "0.0.0.0", port: 8182)
    services.register(serverConfiure)
}

// Our settings
let AODSettings = (
    // SmartThings API
    app_url:      "https://graph.api.smartthings.com:443/api/smartapps/installations/",
    app_id:       "Insert SmartThings App ID Here",
    access_token: "Insert SmartThings Access Token Here",

    // How long to wait after sleep before sending the sleep HTTP request to SmartThings
    sleep_delay:  60
)

