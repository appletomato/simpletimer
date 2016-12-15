//
//  AppDelegate.swift
//  SimpleTimer
//
//  Created by appletomato on 23/07/16.
//  Copyright © 2016 SimpleTimer Foundation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSUserNotificationCenterDelegate {
    
    
    @IBOutlet weak var window: NSWindow!
    
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -2)
    var mainViewController: MainViewController? = MainViewController()
    
    
    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.contentViewController = MainViewController(nibName: "MainViewController", bundle: nil)
        popover.delegate = self
        popover.appearance = NSAppearance(named: NSAppearanceNameAqua)!
        return popover
    }()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSUserNotificationCenter.default.delegate = self
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: NSEventMask(rawValue: UInt64(Int(NSEventMask.rightMouseUp.rawValue | NSEventMask.leftMouseDown.rawValue))))
        }
        
    }
    
    
    func quit(_ send: AnyObject?) {
        NSLog("Exit")
        NSApplication.shared().terminate(nil)
    }
    
    
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    
    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    
    func statusItemClicked(_ sender: NSStatusBarButton!) {
        
        let event:NSEvent! = NSApp.currentEvent!
        
        if (event.type == NSEventType.rightMouseUp) {
            
            let menu = NSMenu()
            
            //        menu.addItem(NSMenuItem.separatorItem())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))
            statusItem.menu = menu
            statusItem.popUpMenu(menu)
            statusItem.menu = nil
            
        } else if (event.type == NSEventType.leftMouseDown) {
            
            if popover.isShown {
                hidePopover(sender)
            } else {
                showPopover(sender)
            }
            
        }
    }
    
    
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    
    func showNotification() -> Void {
        print("NOTIFICATION")
        let notification = NSUserNotification()
        notification.title = "SimpleTimer"
        notification.informativeText = "It is about time!"
        //        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    
}



