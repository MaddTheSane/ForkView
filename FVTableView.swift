//
//  FVTableView.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/1/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

protocol FVTableViewDelegate: NSObjectProtocol {
    func tableViewMenuForSelection() -> NSMenu?
}

final class FVTableView: NSTableView {
    weak var customDelegate: FVTableViewDelegate?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from:nil))
        if row == -1 {
            return nil
        }
        
        selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        self.window?.makeFirstResponder(self)
        
        return customDelegate?.tableViewMenuForSelection()
    }
}
