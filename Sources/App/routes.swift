import Vapor

struct AODIsAwake : Content {
	var isAwake: Int
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "AutoOfficeDaemon now running"
    }
    
    // Basic "Hello, world!" example
    router.get("status") { req -> AODIsAwake in
        print( "(get) status" )
	    return AODIsAwake( isAwake: WakeSleepHandler.shared.isAwake ? 1 : 0 )
    }

    // /wake: Wake the display and return that it is awake as JSON
    router.get("wake") { req -> AODIsAwake in
        print( "(get) wake" )
        sleepDisplay( false )
        return AODIsAwake( isAwake: WakeSleepHandler.shared.isAwake ? 1 : 0 )
    }

    // /sleep: Sleep the display and return that it is asleep as JSON
    router.get("sleep") { req -> AODIsAwake in
        print( "(get) sleep" )
        sleepDisplay( true )
        return AODIsAwake( isAwake: WakeSleepHandler.shared.isAwake ? 1 : 0 )
    }

    // /do:  PUT request to wake/sleep the machine
    router.put( AODCommand.self, at: "do") { req, cmd -> AODIsAwake in
        if( cmd.command == "wake" ) {
            sleepDisplay( false )
            print( "(put) do/wake" )
        } else if ( cmd.command == "sleep" ) {
            sleepDisplay( true )
            print( "(put) do/sleep" )
        } else {
            print( "(put) do/(unknown))" )
            throw Abort(.badRequest)
        }

        return AODIsAwake( isAwake: WakeSleepHandler.shared.isAwake ? 1 : 0 )
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)

	// Sleep or wake the diaplsy
	func sleepDisplay( _ goToSleep:Bool) {
		// Only do something if we're not already in that state
		if( WakeSleepHandler.shared.isAwake == !goToSleep ) {
			return;
		}

		let reg   = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler")
		let entry = "IORequestIdle" as CFString

		IORegistryEntrySetCFProperty(reg, entry, goToSleep ? kCFBooleanTrue : kCFBooleanFalse );
		IOObjectRelease(reg);
	}
}
