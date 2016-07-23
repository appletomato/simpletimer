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
    
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    var mainViewController: MainViewController? = MainViewController()
    
    
    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .Semitransient
        popover.contentViewController = MainViewController(nibName: "MainViewController", bundle: nil)
        popover.delegate = self
        popover.appearance = NSAppearance(named: NSAppearanceNameAqua)!
        return popover
    }()
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendActionOn(Int(NSEventMask.RightMouseUpMask.rawValue | NSEventMask.LeftMouseDownMask.rawValue))
        }
        
    }
    
    
    func quit(send: AnyObject?) {
        NSLog("Exit")
        NSApplication.sharedApplication().terminate(nil)
    }
    
    
    
    func popoverShouldDetach(popover: NSPopover) -> Bool {
        return true
    }
    
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
    }
    
    
    func hidePopover(sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    
    func statusItemClicked(sender: NSStatusBarButton!) {
        
        let event:NSEvent! = NSApp.currentEvent!
        
        if (event.type == NSEventType.RightMouseUp) {
            
            let menu = NSMenu()
            
            //        menu.addItem(NSMenuItem.separatorItem())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))
            statusItem.menu = menu
            statusItem.popUpStatusItemMenu(menu)
            statusItem.menu = nil
            
        } else if (event.type == NSEventType.LeftMouseDown) {
            
            if popover.shown {
                hidePopover(sender)
            } else {
                showPopover(sender)
            }
            
        }
    }
    
    
    func menuDidClose(menu: NSMenu) {
        statusItem.menu = nil
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    
    func showNotification() -> Void {
        print("NOTIFICATION")
        let notification = NSUserNotification()
        notification.title = "Simple Timer"
        notification.informativeText = "It is about time!"
        //        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    
}



