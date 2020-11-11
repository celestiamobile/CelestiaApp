//
// CelestiaViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

import CelestiaCore

var urlToRun: URL?

class CelestiaViewController: NSViewController {
    private lazy var dataDirectoryURL = currentDataDirectory()
    private lazy var configFileURL = currentConfigFile()

    private lazy var pixelFmt: NSOpenGLPixelFormat? = {
        let attributes: [UInt32]
        if self.msaa {
            attributes = [UInt32(NSOpenGLPFADoubleBuffer),
                          UInt32(NSOpenGLPFADepthSize), 32,
                          UInt32(NSOpenGLPFASampleBuffers), 1,
                          UInt32(NSOpenGLPFASamples), 4,
                          0]
            msaa = true
        } else {
            attributes = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFADepthSize), 32, 0]
            msaa = false
        }
        return NSOpenGLPixelFormat(attributes: attributes)
    }()

    private lazy var celestiaView: CelestiaView! = CelestiaView(frame: .zero, pixelFormat: self.pixelFmt, msaaEnabled: self.msaa)
    @IBOutlet var selectionMenu: NSMenu!
    @IBOutlet var refMarkMenu: NSMenu!
    @IBOutlet var unmarkMenuItem: NSMenuItem!

    private let core: CelestiaAppCore = CelestiaAppCore.shared
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    private var ready: Bool = false

    private var pendingScript: String?

    private var pressingKey: (key: Int, time: Int)?

    private lazy var fullDPI = UserDefaults.app[.fullDPI] ?? false
    private lazy var msaa = UserDefaults.app[.msaa] ?? false
    private lazy var scaleFactor: CGFloat = self.fullDPI ? (NSScreen.main?.backingScaleFactor ?? 1) : 1

    override func loadView() {
        super.loadView()

        celestiaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(celestiaView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: celestiaView!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: celestiaView!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: celestiaView!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: celestiaView!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        core.delegate = self

        celestiaView.viewDelegate = self
        celestiaView.mouseProcessor = self
        celestiaView.keyboardProcessor = self
        celestiaView.dndProcessor = self

        celestiaView.wantsBestResolutionOpenGLSurface = fullDPI
        celestiaView.scaleFactor = scaleFactor
        celestiaView.setupCelestia()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        ready = false
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        ready = true

        if let script = pendingScript {
            pendingScript = nil
            core.runScript(at: script)
        }
    }

    deinit {
        AppDelegate.clear(identifier: "Settings")
        AppDelegate.clear(identifier: "Browser")
        AppDelegate.clear(identifier: "Goto")
        AppDelegate.clear(identifier: "SetTime")
        AppDelegate.clear(identifier: "EclipseFinder")
        AppDelegate.clear(identifier: "Info")
    }

    func runScript(at path: String) {
        if ready {
            pendingScript = nil
            core.runScript(at: path)
        } else {
            pendingScript = path
        }
    }

    private func keyTick() {
        if let (key, time) = pressingKey {
            if time <= 0 {
                core.keyUp(key)
                pressingKey = nil
            } else {
                pressingKey = (key, time - 1)
            }
        }
    }

    private func pressAndHold(key: Int, time: Int) {
        pressingKey = (key, time)
        core.keyDown(key)
    }

    func handleMenuItem(_ sender: NSMenuItem) {
        let tag = sender.tag
        guard tag != 0 else { return }

        if tag < 0 {
            pressAndHold(key: -tag, time: 1)
        } else {
            core.charEnter(Int8(tag))
        }
    }

    func forward() {
        core.forward()
    }

    func back() {
        core.back()
    }

    func showSetting() {
        AppDelegate.present(identifier: "Settings") { () -> SettingViewController in
            return NSStoryboard(name: "Setting", bundle: nil).instantiateController(withIdentifier: "Setting") as! SettingViewController
        }
    }

    func showBrowser() {
        AppDelegate.present(identifier: "Browser") { () -> BrowserViewController in
            return NSStoryboard(name: "StarBrowser", bundle: nil).instantiateController(withIdentifier: "Browser") as! BrowserViewController
        }
    }

    func showGoto() {
        AppDelegate.present(identifier: "Goto") { () -> GotoViewController in
            return NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Goto") as! GotoViewController
        }
    }

    func showSetTime() {
        AppDelegate.present(identifier: "SetTime") { () -> SetTimeViewController in
            return NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "SetTime") as! SetTimeViewController
        }
    }

    func showEclipseFinder() {
        AppDelegate.present(identifier: "EclipseFinder") { () -> EclipseFinderViewController in
            return NSStoryboard(name: "EclipseFinder", bundle: nil).instantiateController(withIdentifier: "EclipseFinder") as! EclipseFinderViewController
        }
    }

    @objc func copy(_ sender: Any) {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: self)
        pb.setString(core.currentURL, forType: .string)
    }

    @objc func paste(_ sender: Any) {
        let pb = NSPasteboard.general
        // TODO: support other type
        guard pb.availableType(from: [.string]) != nil else { return }

        if let value = pb.string(forType: .string) {
            if value.starts(with: "cel:") {
                core.go(to: value)
            } else {
                AppDelegate.shared.scriptController.runScript(at: value)
            }
        }
    }

    @IBAction private func glViewMenuClicked(_ sender: NSMenuItem) {
        handleMenuItem(sender)
    }

    @IBAction private func showInfo(_ sender: NSMenuItem) {
        let selection = core.simulation.selection
        AppDelegate.present(identifier: "Info", tryToReuse: false, customization: { window in
            window.styleMask = [window.styleMask, .utilityWindow]
        }) { () -> InfoViewController in
            let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Info") as! InfoViewController
            vc.selection = selection
            return vc
        }
    }

    @IBAction private func handleRefMark(_ sender: NSMenuItem) {
        core.setBoolValue(sender.state == .on, forTag: sender.tag)
    }

    @IBAction func handleUnmark(_ sender: Any) {
        core.simulation.universe.unmark(core.simulation.selection)
    }

    @IBAction func handleMark(_ sender: NSMenuItem) {
        if let index = sender.menu?.items.firstIndex(of: sender) {
            core.simulation.universe.mark(core.simulation.selection, with: CelestiaMarkerRepresentation(rawValue: UInt(index))!)
            core.showMarkers = true
        }
    }

    @IBAction private func selectObject(_ sender: BrowserMenuItem) {
        if let item = sender.browserItem, let cat = item.entry {
            if let sel = CelestiaSelection(object: cat) {
                core.simulation.selection = sel
            }
        }
    }

    @IBAction private func changeAltSurface(_ sender: NSMenuItem) {
        if let altSurfaces = core.simulation.selection.body?.alternateSurfaceNames, altSurfaces.count > 0 {
            if sender.tag == 0 {
                core.simulation.activeObserver.displayedSurface = ""
            } else {
                let actualIndex = sender.tag - 1
                if actualIndex < altSurfaces.count {
                    core.simulation.activeObserver.displayedSurface = altSurfaces[actualIndex]
                }
            }
        }
    }
}

extension CelestiaViewController: CelestiaViewDelegate {
    func draw(in glView: CelestiaView) {
        NSEvent.stopPeriodicEvents()

        keyTick()

        if ready {
            core.draw()
            core.tick()
        }
    }

    func update(in glView: CelestiaView) {
        core.resize(to: glView.bounds.size.scale(by: scaleFactor))
    }

    func initialize(with context: NSOpenGLContext, supportsMultiThread: Bool, callback: @escaping (Bool) -> Void) {
        context.makeCurrentContext()

        _ = CelestiaAppCore.initGL()

        FileManager.default.changeCurrentDirectoryPath(dataDirectoryURL.url.path)
        CelestiaAppCore.setLocaleDirectory(dataDirectoryURL.url.path + "/locale")


        guard supportsMultiThread else {
            let result = core.startSimulation(configFileName: configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { _ in }) && core.startRenderer()

            guard result else {
                showLoadingFailed()
                callback(false)
                return
            }

            start()
            callback(true)
            return
        }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            context.makeCurrentContext()

            let result = self.core.startSimulation(configFileName: self.configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (status) in
                // Broadcast the status
                NotificationCenter.default.post(name: celestiaLoadingStatusNotificationName, object: nil, userInfo: [celestiaLoadingStatusNotificationKey : status])
            }) && self.core.startRenderer()

            DispatchQueue.main.async {
                guard result else {
                    self.showLoadingFailed()
                    callback(false)
                    return
                }
                self.start()
                callback(true)
            }
        }
    }

    func showLoadingFailed() {
        self.view.window?.close()
        let alert = NSAlert()
        alert.messageText = CelestiaString("Loading Celestia failed…", comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: CelestiaString("Choose Config File", comment: ""))
        alert.addButton(withTitle: CelestiaString("Quit", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn {
            AppDelegate.shared.showChangeConfigFile(launchFailure: true)
            return
        }
        NSApp.terminate(nil)
    }

    func start() {
        core.loadUserDefaultsWithAppDefaults(atPath: Bundle.main.path(forResource: "defaults", ofType: "plist"))

        core.setDPI(Int(scaleFactor * 96))
        core.setPickTolerance(scaleFactor * 4)

        let locale = LocalizedString("LANGUAGE", "celestia")
        if let (font, boldFont) = getInstalledFontFor(locale: locale) {
            core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
            core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
            core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
            core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
        } else if let font = GetFontForLocale(locale, .system),
            let boldFont = GetFontForLocale(locale, .emphasizedSystem) {
            core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
            core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
            core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
            core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
        }

        core.tick()
        core.start()

        AppDelegate.shared.scriptController.buildScriptMenu()
        AppDelegate.shared.bookmarkController.readBookmarksFromDisk()
        AppDelegate.shared.bookmarkController.buildBookmarkMenu()

        // we delay opening url/running script
        DispatchQueue.main.asyncAfter(deadline: .now() + 1)  {
            self.checkNeedOpeningURL()
        }

        NotificationCenter.default.post(name: celestiaLoadingFinishedNotificationName, object: nil, userInfo: nil)
    }
}

extension CelestiaViewMouseButton {
    var celestiaButtons: MouseButton { return MouseButton(rawValue: rawValue) }
}

extension CelestiaViewController: CelestiaViewMouseProcessor {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        core.mouseButtonUp(at: point.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        core.mouseButtonDown(at: point.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDragged(to point: CGPoint) {
        core.mouseDragged(to: point.scale(by: scaleFactor))
    }

    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        core.mouseMove(by: offset.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags) {
        core.mouseWheel(by: motion * scaleFactor, modifiers: modifiers.rawValue)
    }

    func requestMenu(for selection: CelestiaSelection) -> NSMenu? {
        if selection.isEmpty { return nil }

        // configure fixed items
        selectionMenu.items[0].title = core.simulation.universe.name(for: selection)
        unmarkMenuItem.isEnabled = core.simulation.universe.isMarked(core.simulation.selection)

        // clear original menu items
        selectionMenu.items.forEach({ (item) in
            if item.tag >= 10000 {
                selectionMenu.removeItem(item)
            }
        })

        let browserItem: CelestiaBrowserItem?
        if let body = selection.body {
            // add ref mark
            let refMarkMenuItem = NSMenuItem(title: CelestiaString("Reference Vectors", comment: ""), action: nil, keyEquivalent: "")
            refMarkMenuItem.tag = 10000
            refMarkMenuItem.submenu = refMarkMenu
            refMarkMenu.items.forEach { $0.state = core.boolValue(forTag: $0.tag) ? .on : .off }
            selectionMenu.insertItem(refMarkMenuItem, at: selectionMenu.items.count - 2)

            let sep = NSMenuItem.separator()
            sep.tag = 10001
            selectionMenu.insertItem(sep, at: selectionMenu.items.count - 2)

            browserItem = CelestiaBrowserItem(name: body.name, catEntry: body, provider: universe)
        } else if let star = selection.star {
            browserItem = CelestiaBrowserItem(name: universe.starCatalog.starName(star), catEntry: star, provider: universe)
        } else {
            browserItem = nil
        }

        func createMenuItems(for item: CelestiaBrowserItem) -> [NSMenuItem]? {
            var mItems = [BrowserMenuItem]()
            for i in 0..<item.children.count {
                let subItemName = item.childName(at: Int(i))!
                let child = item.child(with: subItemName)!
                let childItem = BrowserMenuItem(title: subItemName, action: #selector(selectObject(_:)), keyEquivalent: "")
                childItem.target = self
                childItem.browserItem = child
                if child.children.count == 0 {
                    mItems.append(childItem)
                } else if let menuItems = createMenuItems(for: child) {
                    let subMenu = NSMenu(title: "")
                    for item in menuItems {
                        subMenu.addItem(item)
                    }
                    childItem.submenu = subMenu
                    mItems.append(childItem)
                }
            }
            return mItems.count == 0 ? nil : mItems
        }

        // add planet system
        if let bItem = browserItem, let planetItems = createMenuItems(for: bItem) {
            planetItems.forEach {$0.tag = 10002; selectionMenu.insertItem($0, at: selectionMenu.items.count - 2)}

            let sep = NSMenuItem.separator()
            sep.tag = 10003
            selectionMenu.insertItem(sep, at: selectionMenu.items.count - 2)
        }

        if let altSurfaces = selection.body?.alternateSurfaceNames {

            let altSurfaceItem = NSMenuItem(title: CelestiaString("Alternate Surfaces", comment: ""), action: nil, keyEquivalent: "")
            altSurfaceItem.tag = 10004
            selectionMenu.insertItem(altSurfaceItem, at: selectionMenu.items.count - 2)

            let submenu = NSMenu(title: "")
            for (index, surface) in ([CelestiaString("Default", comment: "")] + altSurfaces).enumerated() {
                let item = NSMenuItem(title: surface, action: #selector(changeAltSurface(_:)), keyEquivalent: "")
                let current = core.simulation.activeObserver.displayedSurface
                item.state = (index == 0 ? current == "" : current == surface) ? .on : .off
                item.tag = index
                submenu.addItem(item)
            }
            altSurfaceItem.submenu = submenu

            let sep = NSMenuItem.separator()
            sep.tag = 10005
            selectionMenu.insertItem(sep, at: selectionMenu.items.count - 2)
        }

        return selectionMenu
    }
}

extension CelestiaViewController: CelestiaViewDNDProcessor {
    func draggingType(for url: URL) -> NSDragOperation {
        if url.isFileURL && ScriptController.supportedFileExtensions.contains(url.pathExtension.lowercased()) {
            return .copy
        }
        return NSDragOperation()
    }

    func performDrop(for url: URL) {
        AppDelegate.shared.scriptController.runScript(at: url.path)
    }
}

extension CelestiaViewController: CelestiaViewKeyboardProcessor {
    func keyUp(modifiers: NSEvent.ModifierFlags, with input: String?) {
        core.keyUp(with: input, modifiers: modifiers.rawValue)
    }

    func keyDown(modifiers: NSEvent.ModifierFlags, with input: String?) {
        core.keyDown(with: input, modifiers: modifiers.rawValue)
    }
}

extension CelestiaViewController: CelestiaAppCoreDelegate {
    func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: CelestiaSelection) {
        requestMenu(for: selection)?.popUp(positioning: nil, at: location.scale(by: 1 / scaleFactor), in: celestiaView)
    }

    func celestiaAppCoreFatalErrorHappened(_ error: String) {
        DispatchQueue.main.async {
            NSAlert.warning(message: error, text: "")
        }
    }

    func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {
        switch shape {
        case .sizeVer:
            NSCursor.resizeUpDown.set()
        case .sizeHor:
            NSCursor.resizeLeftRight.set()
        default:
            NSCursor.arrow.set()
        }
    }

    func celestiaAppCoreWatchedFlagDidChange(_ changedFlag: CelestiaWatcherFlag) {}
}

extension CelestiaViewController {
    func checkNeedOpeningURL() {
        guard let url = urlToRun else { return }
        urlToRun = nil
        let title = url.isFileURL ? CelestiaString("Run script?", comment: "") : CelestiaString("Open URL?", comment: "")
        NSAlert.confirm(message: title, window: view.window!) { [weak self] in
            guard let self = self else { return }
            self.openURL(url)
        }
    }

    private func openURL(_ url: URL) {
        if url.isFileURL {
            AppDelegate.shared.scriptController.runScript(at: url.path)
        } else {
            core.go(to: url.absoluteString)
        }
    }
}

class BrowserMenuItem: NSMenuItem {
    var browserItem: CelestiaBrowserItem? = nil
}

private extension CGPoint {
    func scale(by factor: CGFloat) -> CGPoint {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}

private extension CGSize {
    func scale(by factor: CGFloat) -> CGSize {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}

private func getInstalledFontFor(locale: String) -> (font: FallbackFont, boldFont: FallbackFont)? {
    guard let fontDir = Bundle.main.path(forResource: "Fonts", ofType: nil) else { return nil }
    let fontFallback = [
        "ja": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 0),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 0)
        ),
        "ko": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 1),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 1)
        ),
        "zh_CN": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 2),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 2)
        ),
        "zh_TW": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 3),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 3)
        ),
        "ar": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansArabic-Regular.ttf", collectionIndex: 0),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansArabic-Bold.ttf", collectionIndex: 0)
        )
    ]
    let def = (
        font: FallbackFont(filePath: "\(fontDir)/NotoSans-Regular.ttf", collectionIndex: 0),
        boldFont: FallbackFont(filePath: "\(fontDir)/NotoSans-Bold.ttf", collectionIndex: 0)
    )
    return fontFallback[locale] ?? def
}
