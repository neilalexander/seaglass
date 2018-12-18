//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    @IBOutlet var MenuSeaglass: NSMenu!
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == MenuSeaglass {
            let loggedIn = MatrixServices.inst.state == .started
            for menuItem in menu.items {
                if menuItem.tag == 1 {
                    menuItem.isEnabled = loggedIn
                    menuItem.state = .off
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDefaults.init()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        MatrixServices.inst.close()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return false }
        
        let identifier = NSStoryboard.SceneIdentifier("MainWindowController")
        let controller = NSStoryboard.main?.instantiateController(withIdentifier: identifier) as! MainWindowController
        
        if let window = controller.window {
            window.makeKeyAndOrderFront(self)
            return true
        }
        
        return false
    }

    @IBAction func logoutMenuItemSelected(_ sender: Any) {
        MatrixServices.inst.logout()
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Matrix")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    @IBAction func saveAction(_ sender: AnyObject?) {
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Seaglass version: " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String))
        
        // if you checked the box that said "Do not show this message again" but want see the Move to Applications dialog box again, run:
        // defaults write eu.neilalexander.seaglass moveToApplicationsFolderAlertSuppress NO
        #if RELEASE
        PFMoveToApplicationsFolderIfNecessary();
        #endif
    }

}
