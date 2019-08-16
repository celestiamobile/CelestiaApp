//
//  CelestiaViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class CelestiaViewController: NSViewController {

    @IBOutlet weak var glView: CelestiaGLView!
    @IBOutlet var glViewMenu: NSMenu!
    @IBOutlet var refMarkMenu: NSMenu!
    @IBOutlet var unmarkMenuItem: NSMenuItem!

    private let core: CelestiaAppCore = AppDelegate.shared.core
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    private var ready: Bool = false

    private var pendingScript: String?

    private var pressingKey: (key: Int, time: Int)?

    override func viewDidLoad() {
        super.viewDidLoad()

        glView.openGLContext?.makeCurrentContext()

        // init glew
        guard CelestiaAppCore.glewInit() else {
            NSAlert.fatalError(text: NSLocalizedString("Failed to start GLEW.", comment: ""))
        }

        glView.setAASamples(GLint(core.aaSamples))

        guard core.startRenderer() else {
            NSAlert.fatalError(text: NSLocalizedString("Failed to start renderer.", comment: ""))
        }

        // find the dpi
        if let displayPixelSize = NSScreen.main?.deviceDescription[.size] as? CGSize, let displayID = NSScreen.main?.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID {
            let displayPhysicalSize = CGDisplayScreenSize(displayID)
            core.setDPI(Int(displayPixelSize.width / displayPhysicalSize.width * 25.4))
        }

        core.loadUserDefaults()

        core.tick()
        core.start(at: Date())

        glView.delegate = self
        glView.mouseProcessor = self
        glView.keyboardProcessor = self
        glView.dndProcessor = self

        Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(displayCallback), userInfo: nil, repeats: true)
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

    @objc private func displayCallback() {
        NSEvent.stopPeriodicEvents()

        keyTick()

        if !glView.needsDisplay {
            glView.needsDisplay = true
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
            core.charEnter(unichar(tag))
        }
    }

    func forward() {
        core.forward()
    }

    func back() {
        core.back()
    }

    func showSetting() {
        let setting = NSStoryboard(name: "Setting", bundle: nil).instantiateController(withIdentifier: "Setting") as! SettingViewController
        let panel = NSPanel(contentViewController: setting)
        panel.makeKeyAndOrderFront(self)
    }

    func showBrowser() {
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

        guard let selectedResolutionIndex = NSAlert.selection(message: NSLocalizedString("Resolution:", comment: ""), selections: availableResolutions.map { "\($0.width) x \($0.height)" }) else { return }

        guard let selectedFPSIndex = NSAlert.selection(message: NSLocalizedString("Frame rate:", comment: ""), selections: availableFPS.map { String(format: "%.2f", $0) }) else { return }

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["ogv"]
        panel.nameFieldStringValue = "CelestiaMovie"
        let result = panel.runModal()
        guard result == .OK, let path = panel.url?.path else { return }

        let width = CGFloat(availableResolutions[selectedResolutionIndex].width)
        let height = CGFloat(availableResolutions[selectedResolutionIndex].height)
        guard core.captureMovie(to: path, size: CGSize(width: width, height: height), fps: availableFPS[selectedFPSIndex]) else {
            NSAlert.warning(message: "Unable to Capture Movie", text: "")
            return
        }
    }

    func showGoto() {
        let goto = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "Goto") as! GotoViewController

        let panel = NSPanel(contentViewController: goto)
        panel.makeKeyAndOrderFront(self)
    }

    func showSetTime() {
        let time = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "SetTime") as! SetTimeViewController

        let panel = NSPanel(contentViewController: time)
        panel.makeKeyAndOrderFront(self)
    }

    func showEclipseFinder() {
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
            let selection: CelestiaSelection?
            if let body = cat as? CelestiaBody {
                selection = CelestiaSelection(body: body)
            } else if let star = cat as? CelestiaStar {
                selection = CelestiaSelection(star: star)
            } else if let dso = cat as? CelestiaDSO {
                selection = CelestiaSelection(dso: dso)
            } else if let location = cat as? CelestiaLocation {
                selection = CelestiaSelection(location: location)
            } else {
                selection = nil
            }
            if let sel = selection {
                core.simulation.selection = sel
            }
        }
    }

    
}

extension CelestiaViewController: CelestiaGLViewDelegate {
    func draw(in glView: CelestiaGLView) {
        if ready {
            core.draw()
            core.tick()
        }
    }

    func update(in glView: CelestiaGLView) {
        core.resize(to: glView.bounds.size)
    }
}

extension CelestiaGLViewMouseButton {
    var celestiaButtons: MouseButton { return MouseButton(rawValue: rawValue) }
}

extension CelestiaViewController: CelestiaGLViewMouseProcessor {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseButtonUp(at: point, modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseButtonDown(at: point, modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseDragged(to point: CGPoint) {
        core.mouseDragged(to: point)
    }

    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton) {
        core.mouseMove(by: offset, modifiers: modifiers.rawValue, with: buttons.celestiaButtons)
    }

    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags) {
        core.mouseWheel(by: motion, modifiers: modifiers.rawValue)
    }

    func requestMenu(at point: NSPoint) -> NSMenu? {
        let selection = core.requestSelection(at: point)
        if selection.isEmpty { return nil }

        // configure fixed items
        glViewMenu.items[0].title = selection.name
        unmarkMenuItem.isEnabled = core.simulation.universe.isMarked(core.simulation.selection)

        // clear original menu items
        glViewMenu.items.removeAll(where: { $0.tag >= 10000 })

        let browserItem: CelestiaBrowserItem?
        if let body = selection.body {
            // add ref mark
            let refMarkMenuItem = NSMenuItem(title: NSLocalizedString("Reference Vectors", comment: ""), action: nil, keyEquivalent: "")
            refMarkMenuItem.tag = 10000
            refMarkMenuItem.submenu = refMarkMenu
            refMarkMenu.items.forEach { $0.state = core.boolValue(forTag: $0.tag) ? .on : .off }
            glViewMenu.insertItem(refMarkMenuItem, at: glViewMenu.items.count - 2)

            let sep = NSMenuItem.separator()
            sep.tag = 10001
            glViewMenu.insertItem(sep, at: glViewMenu.items.count - 2)

            browserItem = CelestiaBrowserItem(catEntry: body, provider: universe)
        } else if let star = selection.star {
            browserItem = CelestiaBrowserItem(catEntry: star, provider: universe)
        } else {
            browserItem = nil
        }

        func createMenuItems(for item: CelestiaBrowserItem) -> [NSMenuItem]? {
            var mItems = [BrowserMenuItem]()
            for i in 0..<item.childCount {
                let subItemName = item.childName(at: Int(i))!
                let child = item.child(with: subItemName)!
                let childItem = BrowserMenuItem(title: subItemName, action: #selector(selectObject(_:)), keyEquivalent: "")
                childItem.target = self
                childItem.browserItem = child
                if child.childCount == 0 {
                    mItems.append(childItem)
                } else if let menuItems = createMenuItems(for: child) {
                    let subMenu = NSMenu(title: "")
                    subMenu.items = menuItems
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

class BrowserMenuItem: NSMenuItem {
    var browserItem: CelestiaBrowserItem? = nil
}
