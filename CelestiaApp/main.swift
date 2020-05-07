//
//  main.swift
//  Celestia
//
//  Created by Levin Li on 2020/5/7.
//  Copyright © 2020 李林峰. All rights reserved.
//

import AppKit
import CelestiaCore

CelestiaAppCore.setLocaleDirectory(defaultDataDirectory.path + "/locale")
SetupLocalizationSwizzling()

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
