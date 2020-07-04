//
// main.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppKit
import CelestiaCore

CelestiaAppCore.setLocaleDirectory(defaultDataDirectory.path + "/locale")
SetupLocalizationSwizzling()

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
