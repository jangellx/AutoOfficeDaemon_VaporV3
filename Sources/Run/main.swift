// Main file.  We just set up everything, spawn Vapor in a background thread,
//  and run the main input loop.

import App
import AppKit
import Vapor

// The app delegate installs notifiers for display sleep and wake events, then calls
//  a method on the WakeSleepHandler to send the appropraite events to SmartThings.
// We need to separately define the app delegate in this file, as for some reason
//  applicationDidFinishLaunching() wasnm't getting called when it was in another
//  the App module.  This actually resulted in a bit of code cleanup, since we
//  it conslidates the logic that manages sending wake/sleep events in App, and
//  keeps system logic here in main.
class WakeSleepAppDelegate : NSObject, NSApplicationDelegate {
    // Once the application finishes launching, we register for display sleep and wake events
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Listen for wake/sleep notifications
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector( sleepListener(_:) ), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector( sleepListener(_:) ), name: NSWorkspace.screensDidWakeNotification,  object: nil)
    }

    // This commun function is used to handle if the display is currently asleep or awake,
    //  storing the state in isAwake.
    @objc func sleepListener(_ aNotification:NSNotification) {
        if aNotification.name == NSWorkspace.screensDidSleepNotification {
            print("Display slept; arming timer to send message to SmartThings")
            WakeSleepHandler.shared.sleepStateChanged( isNowAwake: false )

        } else if aNotification.name == NSWorkspace.screensDidWakeNotification {
            print("Display woke; stopping timer and sending message to SmartThings")
            WakeSleepHandler.shared.sleepStateChanged( isNowAwake: true )

        } else {
            print("Unknown sleep/wake event")
        }
    }
}

// Initialize the application and set the app delegate
let nsApp       = NSApplication.shared
let appDelegate = WakeSleepAppDelegate()
nsApp.delegate  = appDelegate

// Run Vapor in a backgorund thread.  We need to do this so that we can listen for system
//  sleep/wak events in the main thread and not block the AppDelegate.
DispatchQueue.global(qos: .background).async {
    do {
        let vaporApp = try app( .detect() )

        WakeSleepHandler.shared.setVaporApp( vaporApp );

        try vaporApp.run()

    } catch {
        print( "Failed to start the Vapor application server" )
    }
}

// Run the main loop so we can get sleep/wake notifications
nsApp.run()
