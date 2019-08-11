//
//  CelestiaViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class CelestiaViewController: NSViewController {

    @IBOutlet weak var glView: CelestiaGLView!

    private let core: AppCore = AppDelegate.shared.core

    private var ready: Bool = false
    private var pendingScript: String?

    private var pressingKey: (key: Int, time: Int)?

    override func viewDidLoad() {
        super.viewDidLoad()

        glView.openGLContext?.makeCurrentContext()

        // init glew
        guard AppCore.glewInit() else {
            NSAlert.fatalError(text: NSLocalizedString("Failed to start GLEW.", comment: ""))
        }

        glView.setAASamples(GLint(core.aaSamples))

        guard core.startRenderer() else {
            NSAlert.fatalError(text: NSLocalizedString("Failed to start renderer.", comment: ""))
        }

        core.loadUserDefaults()

        core.tick()
        core.start(at: Date())

        glView.delegate = self
        glView.mouseProcessor = self
        glView.keyboardProcessor = self

        CelestiaSelection.actionGroup.forEach { $0.target = self; $0.action = #selector(glViewMenuClicked(_:)) }
        CelestiaSelection.locationGroup.forEach { $0.target = self; $0.action = #selector(glViewMenuClicked(_:)) }
        CelestiaSelection.markOrUnmark.target = self
        CelestiaSelection.markOrUnmark.action = #selector(glViewMenuClicked(_:))

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
}

extension CelestiaViewController {
    @objc private func glViewMenuClicked(_ sender: NSMenuItem) {
        handleMenuItem(sender)
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

extension CelestiaViewController: CelestiaGLViewMouseProcessor {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton) {
        core.mouseButtonUp(at: point, modifiers: modifiers.rawValue, with: buttons)
    }

    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton) {
        core.mouseButtonDown(at: point, modifiers: modifiers.rawValue, with: buttons)
    }

    func mouseDragged(to point: CGPoint) {
        core.mouseDragged(to: point)
    }

    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton) {
        core.mouseMove(by: offset, modifiers: modifiers.rawValue, with: buttons)
    }

    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags) {
        core.mouseWheel(by: motion, modifiers: modifiers.rawValue)
    }

    func requestMenu(at point: NSPoint) -> NSMenu? {
        let selection = core.requestSelection(at: point)
        return selection.menu
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
