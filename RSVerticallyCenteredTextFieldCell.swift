//
//  Originally created by Daniel Jalkut on 6/17/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//
//  This source code is provided to you compliments of Red Sweater Software under the license as described below. NOTE: This is the MIT License.
//
//  Copyright (c) 2006 Red Sweater Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Ported to Swift by Kevin Wojniak on May 3, 2015
//

import Cocoa

class RSVerticallyCenteredTextFieldCell: NSTextFieldCell {
    private var mIsEditingOrSelecting = false
    
    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        // Get the parent's idea of where we should draw
        var newRect = super.drawingRect(forBounds: theRect)

        // When the text field is being 
        // edited or selected, we have to turn off the magic because it screws up 
        // the configuration of the field editor.  We sneak around this by 
        // intercepting selectWithFrame and editWithFrame and sneaking a 
        // reduced, centered rect in at the last minute.
        if !mIsEditingOrSelecting {
            // Get our ideal size for current text
            let textSize = cellSize(forBounds: theRect)

            // Center that in the proposed rect
            let heightDelta = newRect.size.height - textSize.height
            if heightDelta > 0 {
                newRect.size.height -= heightDelta
                newRect.origin.y += (heightDelta / 2)
            }
        }
	
        return newRect
    }

    override func select(withFrame aRect: NSRect, in controlView: NSView, editor textObj: NSText, delegate anObject: Any?, start selStart: Int, length selLength: Int) {
        let rect = drawingRect(forBounds: aRect)
        mIsEditingOrSelecting = true
        super.select(withFrame: rect, in: controlView, editor: textObj, delegate: anObject, start: selStart, length: selLength)
        mIsEditingOrSelecting = false
    }

    override func edit(withFrame aRect: NSRect, in controlView: NSView, editor textObj: NSText, delegate anObject: Any?, event theEvent: NSEvent?) {
        let rect = drawingRect(forBounds: aRect)
        mIsEditingOrSelecting = true
        super.edit(withFrame: rect, in: controlView, editor: textObj, delegate: anObject, event: theEvent)
        mIsEditingOrSelecting = false
    }
}
