//
//  FVTemplateController.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

protocol FVTypeController {
    var supportedTypes: [String] { get }
    func viewController(fromResourceData data: Data, type: String, errmsg: inout String) -> NSViewController?
}
