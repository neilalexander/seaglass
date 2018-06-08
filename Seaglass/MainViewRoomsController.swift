//
//  MainViewRoomsController.swift
//  Matrix
//
//  Created by Neil Alexander on 06/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class ChannelListEntry: NSTableCellView {
    @IBOutlet var ChannelListEntryName: NSTextField!
    @IBOutlet var ChannelListEntryTopic: NSTextField!
    @IBOutlet var ChannelListEntryIcon: NSImageView!
    
    var roomId: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class MainViewRoomsController: NSViewController, MatrixRoomsDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var ChannelList: NSTableView!
    @IBOutlet weak var ConnectionStatus: NSButton!
    
    weak var mainController: MainViewController?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        switch MatrixServices.inst.state {
        case .started:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))!
            ConnectionStatus.title = "Connected"
        case .starting:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))!
            ConnectionStatus.title = "Connecting..."
        default:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusUnavailable"))!
            ConnectionStatus.title = "Not connected"
        }
    }
    
    func matrixDidJoinRoom(_ room: MXRoom) {
        print("MainViewRoomsController matrixDidJoinRoom \(room)")
        
        ChannelList.reloadData()
    }
    
    func matrixDidPartRoom() {
        print("MainViewRoomsController matrixDidPartRoom")
    }
    
    func matrixDidUpdateRoom() {
        print("MainViewRoomsController matrixDidUpdateRoom")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return MatrixServices.inst.session.rooms.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelListEntry"), owner: self) as? ChannelListEntry

        let state = MatrixServices.inst.session.rooms[row].state
        
        cell?.roomId = state?.roomId
        cell?.ChannelListEntryName.stringValue = state?.name ?? state?.canonicalAlias ?? "Unnamed room"
        cell?.ChannelListEntryTopic.stringValue = "\(state?.members.count ?? 0) members\n" + (state?.topic ?? "(\(state?.roomId.utf8))")
        
        MatrixServices.inst.subscribeToRoom(roomId: (state?.roomId)!)

        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = notification.object as! NSTableView
        
        let entry = row.view(atColumn: 0, row: row.selectedRow, makeIfNecessary: true) as! ChannelListEntry
        
        DispatchQueue.main.async {
            self.mainController?.channelDelegate?.uiDidSelectChannel(entry: entry)
        }
    }
}
