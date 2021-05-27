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

import AsyncGL
import CelestiaCore

class CelestiaViewController: NSViewController {
    private lazy var displayController = CelestiaDisplayController(msaaEnabled: UserDefaults.app[.msaa] ?? false)
    private lazy var interactionView = CelestiaInteractionView()

    @IBOutlet private var selectionMenu: NSMenu!
    @IBOutlet private var refMarkMenu: NSMenu!
    @IBOutlet private var unmarkMenuItem: NSMenuItem!

    private lazy var core: CelestiaAppCore = CelestiaAppCore.shared
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    static var urlToRun: URL?

    private var pressingKey: (key: Int, time: Int)?

    override func loadView() {
        super.loadView()

        displayController.delegate = self
        addChild(displayController)
        displayController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayController.view)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: displayController.view, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: displayController.view, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: displayController.view, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: displayController.view, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        core.delegate = self
    }

    deinit {
        AppDelegate.clear(identifier: "Settings")
        AppDelegate.clear(identifier: "Browser")
        AppDelegate.clear(identifier: "Goto")
        AppDelegate.clear(identifier: "SetTime")
        AppDelegate.clear(identifier: "EclipseFinder")
        AppDelegate.clear(identifier: "Info")
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
        core.run { $0.keyDown(key) }
    }

    func handleMenuItem(_ sender: NSMenuItem) {
        let tag = sender.tag
        guard tag != 0 else { return }

        if tag < 0 {
            pressAndHold(key: -tag, time: 1)
        } else {
            core.charEnterAsync(Int8(tag))
        }
    }

    func forward() {
        core.run { $0.forward() }
    }

    func back() {
        core.run { $0.back() }
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
        let url = core.get { $0.currentURL }
        pb.setString(url, forType: .string)
    }

    @objc func paste(_ sender: Any) {
        let pb = NSPasteboard.general
        // TODO: support other type
        guard pb.availableType(from: [.string]) != nil else { return }

        if let value = pb.string(forType: .string) {
            if value.starts(with: "cel:") {
                core.run { $0.go(to: value) }
            } else {
                AppDelegate.shared.scriptController.runScript(at: value)
            }
        }
    }

    @IBAction private func glViewMenuClicked(_ sender: NSMenuItem) {
        handleMenuItem(sender)
    }

    @IBAction private func showInfo(_ sender: NSMenuItem) {
        core.getSelectionAsync { selection, core in
            AppDelegate.present(identifier: "Info", tryToReuse: false, customization: { window in
                window.styleMask = [window.styleMask, .utilityWindow]
            }) { () -> InfoViewController in
                let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Info") as! InfoViewController
                vc.selection = selection
                return vc
            }
        }
    }

    @IBAction private func handleRefMark(_ sender: NSMenuItem) {
        let on = sender.state == .on
        let tag = sender.tag
        core.run { $0.setBoolValue(on, forTag: tag) }
    }

    @IBAction func handleUnmark(_ sender: Any) {
        core.run { $0.simulation.universe.unmark($0.simulation.selection) }
    }

    @IBAction func handleMark(_ sender: NSMenuItem) {
        if let index = sender.menu?.items.firstIndex(of: sender) {
            core.run { core in
                core.simulation.universe.mark(core.simulation.selection, with: CelestiaMarkerRepresentation(rawValue: UInt(index))!)
                core.showMarkers = true
            }
        }
    }

    @IBAction private func selectObject(_ sender: BrowserMenuItem) {
        if let item = sender.browserItem, let cat = item.entry {
            if let sel = CelestiaSelection(object: cat) {
                core.run { $0.simulation.selection = sel }
            }
        }
    }

    @IBAction private func changeAltSurface(_ sender: NSMenuItem) {
        if let altSurfaces = core.simulation.selection.body?.alternateSurfaceNames, altSurfaces.count > 0 {
            if sender.tag == 0 {
                core.run { $0.simulation.activeObserver.displayedSurface = "" }
            } else {
                let actualIndex = sender.tag - 1
                if actualIndex < altSurfaces.count {
                    core.run { $0.simulation.activeObserver.displayedSurface = altSurfaces[actualIndex] }
                }
            }
        }
    }
}

extension CelestiaViewController: CelestiaDisplayControllerDelegate {
    func celestiaDisplayControllerWillDraw(_ celestiaDisplayController: CelestiaDisplayController) {
        keyTick()
    }

    func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController) {
        // we delay opening url/running script
        DispatchQueue.main.asyncAfter(deadline: .now() + 1)  {
            self.checkNeedOpeningURL()
        }

        DispatchQueue.main.async { [weak self] in
            AppDelegate.shared.isCelestiaLoaded = true
            AppDelegate.shared.scriptController.buildScriptMenu()
            AppDelegate.shared.bookmarkController.readBookmarksFromDisk()
            AppDelegate.shared.bookmarkController.buildBookmarkMenu()
            NotificationCenter.default.post(name: celestiaLoadingFinishedNotificationName, object: nil, userInfo: nil)

            self?.addInteractionView()
        }
    }

    func celestiaDisplayControllerLoadingFailed(_ celestiaDisplayController: CelestiaDisplayController) {
        showLoadingFailed()
    }

    func showLoadingFailed() {
        view.window?.close()
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

    private func addInteractionView() {
        interactionView.mouseProcessor = self
        interactionView.keyboardProcessor = self
        interactionView.dndProcessor = self
        interactionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(interactionView)

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: interactionView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: interactionView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: interactionView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: interactionView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        ])
    }
}

extension CelestiaViewMouseButton {
    var celestiaButtons: MouseButton { return MouseButton(rawValue: rawValue) }
}

extension CelestiaViewController: CelestiaViewMouseProcessor {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        let scale = displayController.scaleFactor
        core.run { $0.mouseButtonUp(at: point.scale(by: scale), modifiers: modifiers.rawValue, with: buttons.celestiaButtons) }
    }

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        let scale = displayController.scaleFactor
        core.run { $0.mouseButtonDown(at: point.scale(by: scale), modifiers: modifiers.rawValue, with: buttons.celestiaButtons) }
    }

    func mouseDragged(to point: CGPoint) {
        let scale = displayController.scaleFactor
        core.run { $0.mouseDragged(to: point.scale(by: scale)) }
    }

    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton) {
        let scale = displayController.scaleFactor
        core.run { $0.mouseMove(by: offset.scale(by: scale), modifiers: modifiers.rawValue, with: buttons.celestiaButtons) }
    }

    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags) {
        let scale = displayController.scaleFactor
        core.run { $0.mouseWheel(by: motion * scale, modifiers: modifiers.rawValue) }
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
        core.run { $0.keyUp(with: input, modifiers: modifiers.rawValue) }
    }

    func keyDown(modifiers: NSEvent.ModifierFlags, with input: String?) {
        core.run { $0.keyDown(with: input, modifiers: modifiers.rawValue) }
    }
}

extension CelestiaViewController: CelestiaAppCoreDelegate {
    func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: CelestiaSelection) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let scale = self.displayController.scaleFactor
            self.requestMenu(for: selection)?.popUp(positioning: nil, at: location.scale(by: 1 / scale), in: self.interactionView)
        }
    }

    func celestiaAppCoreFatalErrorHappened(_ error: String) {
        DispatchQueue.main.async {
            NSAlert.warning(message: error, text: "")
        }
    }

    func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {
        DispatchQueue.main.async {
            switch shape {
            case .sizeVer:
                NSCursor.resizeUpDown.set()
            case .sizeHor:
                NSCursor.resizeLeftRight.set()
            default:
                NSCursor.arrow.set()
            }
        }
    }

    func celestiaAppCoreWatchedFlagDidChange(_ changedFlag: CelestiaWatcherFlag) {}
}

extension CelestiaViewController {
    func checkNeedOpeningURL() {
        guard let url = CelestiaViewController.urlToRun else { return }
        CelestiaViewController.urlToRun = nil
        let title = url.isFileURL ? CelestiaString("Run script?", comment: "") : CelestiaString("Open URL?", comment: "")
        NSAlert.confirm(message: title, window: view.window!) { [weak self] in
            guard let self = self else { return }
            self.openURL(url)
        }
    }

    private func openURL(_ url: URL) {
        if url.isFileURL {
            core.run { $0.runScript(at: url.path) }
        } else {
            core.run { $0.go(to: url.absoluteString) }
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
