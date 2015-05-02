//
//  FVTableView.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/1/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

public protocol FVTableViewDelegate {
    func tableViewMenuForSelection() -> NSMenu?
}

class FVTableView: NSTableView {
    
    var customDelegate: FVTableViewDelegate?
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        let row = rowAtPoint(convertPoint(event.locationInWindow, fromView:nil))
        if row == -1 {
            return nil
        }
        
        selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        self.window?.makeFirstResponder(self)
        
        return customDelegate?.tableViewMenuForSelection()
    }
}
