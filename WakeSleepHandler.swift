//
//  WakeSleepHandler.swift
//  AutoOfficeDaemon
//
//  Created by Joe Angell on 1/28/17.
//
// Sends wake/sleep "put" events to SmartThings via the Vapor API.  It can
//  do this immediately or based on a timer.  This also maintains the current
//  awake/asleep state, as passed to it from the main.swift notifier.
//

import Vapor
import AppKit
import IOKit
import HTTP

// Our simple command JSON object
struct AODCommand : Content {
	var command: String
}

// This class is defined as a singleton, since we only ever need one instance of it and need
//  to access it form other modules.
public class WakeSleepHandler {
    // Singleton definition/accessor
    public static let shared = WakeSleepHandler()

    // Private init is only accessible from this class, specifically for use by the the shared property
    private init() { }
    
    // Set the Vapor app instance so that we can call methods on it
    public func setVaporApp( _ app: Application ) {
        vaporApp = app;
    }

    // Mark as asleep, then arm the timer to actually send the sleep event
    public func sleepStateChanged( isNowAwake: Bool ) {
        isAwake = isNowAwake

        if isAwake {
            // Send awake event and clear the timer
            putToSmartApp( isAwake )
            timer?.invalidate()            // Stop the timer
            timer = nil;                   // Clear it to empty

        } else {
            // Arm the timer
            armTimer();
        }
    }

    public func armForSleep() {
        isAwake = false
        armTimer();
    }

	// Tell SmartThings to wake or sleep
	func putToSmartApp( _ asWake: Bool ) {
		do {
            guard let va = vaporApp else {
                print( "Vapor app not set; can't send sleep message" )
                return
            }

            // Generate the command struct and URL string
			let command = AODCommand( command: asWake ? "wake" : "sleep" )
			let url     = AODSettings.app_url + AODSettings.app_id + "/do" + (isAwake ? "/wake" : "/sleep")

			// Call the URL
			print("Sending message to SmartApp at \(url)")
            let client = try va.make( Client.self )

            _ = client.put( url, headers: ["Authorization": "Bearer " + AODSettings.access_token] ) { put in
                 try put.content.encode( command )
            }

		} catch {
			print( "Failed to issue command to SmartApp" )
		}
	}
	
	// Arm a timer, which we use to send a delayed sleep notification to SmartThings.
	func armTimer() {
		if( AODSettings.sleep_delay == 0 ) {
			// No delay defined; fire the action now
			putToSmartApp( isAwake )
			return;
		}
		
		// Delay defined; arm the timer
		print( "Arming timer for \(AODSettings.sleep_delay) seconds to notify SmartApp to sleep" )
		timer = Timer.scheduledTimer( timeInterval: Double(AODSettings.sleep_delay),
		                              target: self, selector: #selector( timerFire ),
                                      userInfo: nil, repeats: false)
	}

	// The timer has fired; send the sleep/wake message to SmartThings
	@objc func timerFire() {
		putToSmartApp( isAwake );
	}

	// Variables
    var vaporApp: Application? = nil        // Vapor application, used to send our "put" requests to SmartThings

	var isAwake                = true       // True if the display is currently awake; false if asleep
	var timer : Timer?         = nil        // Timer used to wait before sending a sleep "put" request
}
