//
//  FVWindowController.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/1/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

final class FVWindowController: NSWindowController, FVTableViewDelegate, NSTableViewDelegate {
    @IBOutlet weak var resourcesArrayController: NSArrayController!
    @IBOutlet weak var tableView: FVTableView!
    @IBOutlet weak var typeView: NSView!
    @IBOutlet weak var noSelectionView: NSView!
    @IBOutlet weak var noSelectionLabel: NSTextField!
    private var watchers: [NSObjectProtocol] = []

    var windowControllers = [NSWindowController]()
    let typeControllers: [FVTypeController] = [
        FVImageTypeController(),
        FVSNDTypeController(),
        FVTextTypeController(),
		StringListView()
    ]
    var viewController: NSViewController?

    class func windowController() -> Self {
        return self.init(windowNibName: NSNib.Name("FVWindow"))
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.customDelegate = self

        let noteObj = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: self.window, queue: nil) { _ in
            for windowController in self.windowControllers {
                windowController.close()
            }
        }
        watchers.append(noteObj)

        viewSelectedResource()
    }

    func tableViewMenuForSelection() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: "Export\u{2026}", action: #selector(export), keyEquivalent: "")
        return menu
    }

    var selectedResource: FVResource? {
        return resourcesArrayController.selectedObjects.last as? FVResource
    }

    @objc func export() {
        let savePanel = NSSavePanel()
        savePanel.beginSheetModal(for: self.window!) { result in
            if result == .OK {
                try? self.selectedResource?.data?.write(to: savePanel.url!, options: [.atomic])
            }
        }
    }

    func openSelectedResource() {
        if let resource = self.selectedResource {
            openResource(resource)
        }
    }

    func controllerForResource(resource: FVResource, errmsg: inout String) -> NSViewController? {
        if let rsrcData = resource.data, rsrcData.count > 0 {
            if let type = resource.type?.typeString {
                for controller in typeControllers {
                    if controller.supportedTypes.contains(type) {
                        return controller.viewController(fromResourceData: rsrcData, type: type, errmsg: &errmsg)
                    }
                }
            }
        } else {
            errmsg = "No data"
        }
        return nil
    }

    func openResource(_ resource: FVResource) {
        var errmsg = String()
        let controller = controllerForResource(resource: resource, errmsg: &errmsg)
        if controller == nil {
            return
        }

        let view = controller?.view
        let minSize = NSSize(width: 150, height: 150)
        var winFrame = view!.frame

        if winFrame.width < minSize.width {
            winFrame.size.width = minSize.width
        }
        if winFrame.height < minSize.height {
            winFrame.size.height = minSize.height
        }

        let parentWin = self.window
        var parentWinFrame = parentWin!.frameRect(forContentRect: parentWin!.contentView!.frame)
        parentWinFrame.origin = parentWin!.frame.origin

        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(contentRect: winFrame, styleMask: styleMask, backing: .buffered, defer: true)
        window.isReleasedWhenClosed = true
        window.contentView = controller!.view
        window.minSize = minSize

        let newPoint = window.cascadeTopLeft(from: NSPoint(x: parentWinFrame.minX, y: parentWinFrame.maxY))
        window.cascadeTopLeft(from: newPoint)

        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        windowControllers.append(windowController)
        let filename = (self.document as? NSDocument)?.fileURL?.lastPathComponent
        window.title = String(format: "%@ ID = %u from %@", resource.type!.typeString, resource.ident, filename!)

        let newNot = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { _ in
            if let index = self.windowControllers.firstIndex(of: windowController) {
                self.windowControllers.remove(at: index)
            }
        }
        watchers.append(newNot)
    }

    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        let doc = self.document as? FVDocument
        return String(format: "%@ [%@]", displayName, !doc!.resourceFile!.isResourceFork ? "Data Fork" : "Resource Fork")
    }

    func viewSelectedResource() {
        for subview in self.typeView.subviews {
            subview.removeFromSuperview()
        }
        self.viewController = nil
        var view: NSView?
        if let resource = self.selectedResource {
            var errmsg = String()
            if let controller = controllerForResource(resource: resource, errmsg: &errmsg) {
                self.viewController = controller
                view = controller.view
            } else {
                self.noSelectionLabel.stringValue = !errmsg.isEmpty ? errmsg : "Unsupported Type"
            }
        } else {
            self.noSelectionLabel.stringValue = "No Selection"
        }
        if view == nil {
            view = self.noSelectionView
        }
        view!.frame = self.typeView.bounds
        typeView.addSubview(view!)
    }

    func tableViewSelectionDidChange(_ note: Notification) {
        viewSelectedResource()
    }
}
