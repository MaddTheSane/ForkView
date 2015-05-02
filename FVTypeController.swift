//
//  FVTemplateController.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa

protocol FVTypeController {
    func supportedTypes() -> [String]
    func viewControllerFromResource(resource: FVResource) -> NSViewController?
}
