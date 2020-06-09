//
//  CelestiaViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

var urlToRun: URL?

class CelestiaViewController: NSViewController {

    @IBOutlet weak var glView: CelestiaGLView!
    @IBOutlet var glViewMenu: NSMenu!
    @IBOutlet var refMarkMenu: NSMenu!
    @IBOutlet var unmarkMenuItem: NSMenuItem!

    private let core: CelestiaAppCore = CelestiaAppCore.shared
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    private var ready: Bool = false

    private var pendingScript: String?

    private var pressingKey: (key: Int, time: Int)?

    private var scaleFactor: CGFloat = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        core.delegate = self

        glView.openGLContext?.makeCurrentContext()

        // init gl
        guard CelestiaAppCore.initGL() else {
            NSAlert.fatalError(text: CelestiaString("Failed to start OpenGL.", comment: ""))
        }

        glView.setAASamples(GLint(core.aaSamples))

        guard core.startRenderer() else {
            NSAlert.fatalError(text: CelestiaString("Failed to start renderer.", comment: ""))
        }

        if let contentScale = NSScreen.main?.backingScaleFactor {
            scaleFactor = contentScale
            core.setDPI(Int(contentScale * 96))
        }

        core.loadUserDefaultsWithAppDefaults(atPath: Bundle.main.path(forResource: "defaults", ofType: "plist"))

        let locale = LocalizedString("LANGUAGE", "celestia")
        if let font = GetFontForLocale(locale, .system),
            let boldFont = GetFontForLocale(locale, .emphasizedSystem) {
            core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
            core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
            core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
            core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
        }

        core.tick()
        core.start()

        glView.delegate = self
        glView.mouseProcessor = self
        glView.keyboardProcessor = self
        glView.dndProcessor = self

        // we delay opening url/running script
        DispatchQueue.main.asyncAfter(deadline: .now() + 1)  {
            self.checkNeedOpeningURL()
        }
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
        if let existing = NSApp.findWindow(type: SettingViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let setting = NSStoryboard(name: "Setting", bundle: nil).instantiateController(withIdentifier: "Setting") as! SettingViewController
        let panel = NSPanel(contentViewController: setting)
        panel.makeKeyAndOrderFront(self)
    }

    func showBrowser() {
        if let existing = NSApp.findWindow(type: BrowserViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let browser = NSStoryboard(name: "StarBrowser", bundle: nil).instantiateController(withIdentifier: "Browser") as! BrowserViewController
        let panel = NSPanel(contentViewController: browser)
        panel.makeKeyAndOrderFront(self)
    }

    func showVideoCapture() {
        let availableResolutions: [(width: Int, height: Int)] = [
            (160, 120),
            (320, 240),
            (640, 480),
            (720, 576),
            (1024, 768),
            (1280, 720),
            (1920, 1080),
        ]
        let availableFPS: [Float] = [
            15,
            24,
            25,
            29.97,
            30.0,
        ]

        NSAlert.selection(message: CelestiaString("Resolution:", comment: ""), selections: availableResolutions.map { "\($0.width) x \($0.height)" }, window: view.window!) { [weak self] (selectedResolutionIndex) in
            guard let self = self else { return }
            NSAlert.selection(message: CelestiaString("Frame rate:", comment: ""), selections: availableFPS.map { String(format: "%.2f", $0) }, window: self.view.window!) { [weak self] (selectedFPSIndex) in
                guard let self = self else { return }

                let panel = NSSavePanel()
                panel.allowedFileTypes = ["ogv"]
                panel.nameFieldStringValue = "CelestiaMovie"
                let result = panel.runModal()
                guard result == .OK, let path = panel.url?.path else { return }

                let width = CGFloat(availableResolutions[selectedResolutionIndex].width)
                let height = CGFloat(availableResolutions[selectedResolutionIndex].height)
                guard self.core.captureMovie(to: path, size: CGSize(width: width, height: height), fps: availableFPS[selectedFPSIndex]) else {
                    NSAlert.warning(message: CelestiaString("Unable to capture video", comment: ""), text: "")
                    return
                }
            }
        }
    }

    func showGoto() {
        if let existing = NSApp.findWindow(type: GotoViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let goto = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Goto") as! GotoViewController

        let panel = NSPanel(contentViewController: goto)
        panel.makeKeyAndOrderFront(self)
    }

    func showSetTime() {
        if let existing = NSApp.findWindow(type: SetTimeViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let time = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "SetTime") as! SetTimeViewController

        let panel = NSPanel(contentViewController: time)
        panel.makeKeyAndOrderFront(self)
    }

    func showEclipseFinder() {
        if let existing = NSApp.findWindow(type: EclipseFinderViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let finder = NSStoryboard(name: "EclipseFinder", bundle: nil).instantiateController(withIdentifier: "EclipseFinder") as! EclipseFinderViewController
        let panel = NSPanel(contentViewController: finder)
        panel.makeKeyAndOrderFront(self)
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
        if let existing = NSApp.findWindow(type: InfoViewController.self) {
            existing.performClose(nil)
        }
        let selection = core.simulation.selection
        if !selection.isEmpty {
            let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Info") as! InfoViewController
            vc.selection = selection
            let panel = NSPanel(contentViewController: vc)
            panel.styleMask = [panel.styleMask, .utilityWindow]
            panel.makeKeyAndOrderFront(self)
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

extension CelestiaViewController: CelestiaGLViewDelegate {
    func draw(in glView: CelestiaGLView) {
        NSEvent.stopPeriodicEvents()

        keyTick()

        if ready {
            core.draw()
            core.tick()
        }
    }

    func update(in glView: CelestiaGLView) {
        core.resize(to: glView.bounds.size.scale(by: scaleFactor))
    }
}

extension CelestiaGLViewMouseButton {
    var celestiaButtons: MouseButton { return MouseButton(rawValue: rawValue) }
}

extension CelestiaViewController: CelestiaGLViewMouseProcessor {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseButtonUp(at: point.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseButtonDown(at: point.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDragged(to point: CGPoint) {
        core.mouseDragged(to: point.scale(by: scaleFactor))
    }

    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseMove(by: offset.scale(by: scaleFactor), modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags) {
        core.mouseWheel(by: motion * scaleFactor, modifiers: modifiers.rawValue)
    }

    func requestMenu(for selection: CelestiaSelection) -> NSMenu? {
        if selection.isEmpty { return nil }

        // configure fixed items
        glViewMenu.items[0].title = core.simulation.universe.name(for: selection)
        unmarkMenuItem.isEnabled = core.simulation.universe.isMarked(core.simulation.selection)

        // clear original menu items
        glViewMenu.items.removeAll(where: { $0.tag >= 10000 })

        let browserItem: CelestiaBrowserItem?
        if let body = selection.body {
            // add ref mark
            let refMarkMenuItem = NSMenuItem(title: CelestiaString("Reference Vectors", comment: ""), action: nil, keyEquivalent: "")
            refMarkMenuItem.tag = 10000
            refMarkMenuItem.submenu = refMarkMenu
            refMarkMenu.items.forEach { $0.state = core.boolValue(forTag: $0.tag) ? .on : .off }
            glViewMenu.insertItem(refMarkMenuItem, at: glViewMenu.items.count - 2)

            let sep = NSMenuItem.separator()
            sep.tag = 10001
            glViewMenu.insertItem(sep, at: glViewMenu.items.count - 2)

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
            planetItems.forEach {$0.tag = 10002; glViewMenu.insertItem($0, at: glViewMenu.items.count - 2)}

            let sep = NSMenuItem.separator()
            sep.tag = 10003
            glViewMenu.insertItem(sep, at: glViewMenu.items.count - 2)
        }

        if let altSurfaces = selection.body?.alternateSurfaceNames {

            let altSurfaceItem = NSMenuItem(title: CelestiaString("Alternate Surfaces", comment: ""), action: nil, keyEquivalent: "")
            altSurfaceItem.tag = 10004
            glViewMenu.insertItem(altSurfaceItem, at: glViewMenu.items.count - 2)

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
            glViewMenu.insertItem(sep, at: glViewMenu.items.count - 2)
        }

        return glViewMenu
    }
}

extension CelestiaViewController: CelestiaGLViewDNDProcessor {
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

extension CelestiaViewController: CelestiaGLViewKeyboardProcessor {
    func keyUp(modifiers: NSEvent.ModifierFlags, with input: String?) {
        core.keyUp(with: input, modifiers: modifiers.rawValue)
    }

    func keyDown(modifiers: NSEvent.ModifierFlags, with input: String?) {
        core.keyDown(with: input, modifiers: modifiers.rawValue)
    }
}

extension CelestiaViewController: CelestiaAppCoreDelegate {
    func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: CelestiaSelection) {
        requestMenu(for: selection)?.popUp(positioning: nil, at: location, in: glView)
    }

    func celestiaAppCoreFatalErrorHappened(_ error: String) {
        NSAlert.warning(message: error, text: "")
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
