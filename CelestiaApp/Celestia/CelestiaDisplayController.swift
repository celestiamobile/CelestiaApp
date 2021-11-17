//
// CelestiaDisplayController.swift
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

protocol CelestiaDisplayControllerDelegate: AnyObject {
    func celestiaDisplayControllerLoadingFailed(_ celestiaDisplayController: CelestiaDisplayController)
    func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController)
    func celestiaDisplayControllerWillDraw(_ celestiaDisplayController: CelestiaDisplayController)
}

class CelestiaDisplayController: AsyncGLViewController {
    weak var delegate: CelestiaDisplayControllerDelegate?

    private lazy var dataDirectoryURL = currentDataDirectory()
    private lazy var configFileURL = currentConfigFile()

    private lazy var core: AppCore = AppCore.shared

    private var currentSize: CGSize = .zero

    var scaleFactor: CGFloat = (UserDefaults.app[.fullDPI] ?? true) ? (NSScreen.main?.backingScaleFactor ?? 1) : 1

    override func drawGL(_ size: CGSize) {
        delegate?.celestiaDisplayControllerWillDraw(self)

        if size != currentSize {
            currentSize = size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }

    override func prepareGL(_ size: CGSize) {
        _ = AppCore.initGL()

        DispatchQueue.main.sync {
            self.glView?.contentScaleFactor = scaleFactor
        }

        FileManager.default.changeCurrentDirectoryPath(dataDirectoryURL.url.path)
        DispatchQueue.main.sync {
            AppCore.setLocaleDirectory(self.dataDirectoryURL.url.path + "/locale")
        }

        let result = core.startSimulation(configFileName: configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (status) in
            // Broadcast the status
            NotificationCenter.default.post(name: celestiaLoadingStatusNotificationName, object: nil, userInfo: [celestiaLoadingStatusNotificationKey : status])
        }) && core.startRenderer()

        if result {
            start()
            AppCore.renderViewController = self
            delegate?.celestiaDisplayControllerLoadingSucceeded(self)
        } else {
            delegate?.celestiaDisplayControllerLoadingFailed(self)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.startObservingLiveResizeNotifications()
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        startObservingLiveResizeNotifications()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        stopObservingLiveResizeNotifications()
    }

    private func startObservingLiveResizeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillStartLiveResize(_:)), name: NSWindow.willStartLiveResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidEndLiveResize(_:)), name: NSWindow.didEndLiveResizeNotification, object: nil)
    }

    private func stopObservingLiveResizeNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSWindow.willStartLiveResizeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didEndLiveResizeNotification, object: nil)
    }

    @objc private func windowWillStartLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == view.window else { return }
        isPaused = true
    }

    @objc private func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == view.window else { return }
        isPaused = false
    }
}

extension CelestiaDisplayController {
    private func start() {
        core.loadUserDefaultsWithAppDefaults(atPath: Bundle.app.path(forResource: "defaults", ofType: "plist"))

        core.setDPI(Int(scaleFactor * 96))
        core.setPickTolerance(scaleFactor * 4)

        let locale = LocalizedString("LANGUAGE", "celestia")
        let (font, boldFont) = getInstalledFontFor(locale: locale)
        core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
        core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
        core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
        core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)

        core.tick()
        core.start()
    }
}

typealias FallbackFont = (filePath: String, collectionIndex: Int)

private func getInstalledFontFor(locale: String) -> (font: FallbackFont, boldFont: FallbackFont) {
    let fontDir = Bundle.app.path(forResource: "Fonts", ofType: nil)!
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


extension AppCore {
    fileprivate static var renderQueue: DispatchQueue? {
        return renderViewController?.glView?.renderQueue
    }

    fileprivate static weak var renderViewController: AsyncGLViewController?

    func run(_ task: @escaping (AppCore) -> Void) {
        guard let queue = Self.renderQueue else { return }
        queue.async { [weak self] in
            guard let self = self else { return }
            task(self)
        }
    }

    static func makeRenderContextCurrent() {
        Self.renderViewController?.makeRenderContextCurrent()
    }

    func get<T>(_ task: (AppCore) -> T) -> T {
        guard let queue = Self.renderQueue else { fatalError() }
        var item: T?
        queue.sync { [weak self] in
            guard let self = self else { return }
            item = task(self)
        }
        guard let returnItem = item else { fatalError() }
        return returnItem
    }

    func charEnterAsync(_ char: Int8) {
        run {
            $0.charEnter(char)
        }
    }

    func selectAsync(_ selection: Selection) {
        run {
            $0.simulation.selection = selection
        }
    }

    func selectAndCharEnterAsync(_ selection: Selection, char: Int8) {
        run {
            $0.simulation.selection = selection
            $0.charEnter(char)
        }
    }

    func getSelectionAsync(_ completion: @escaping (Selection, AppCore) -> Void) {
        run { core in
            let selection = core.simulation.selection
            DispatchQueue.main.async {
                completion(selection, core)
            }
        }
    }

    func markAsync(_ selection: Selection, markerType: MarkerRepresentation) {
        run { core in
            core.simulation.universe.mark(selection, with: markerType)
            core.showMarkers = true
        }
    }

    func setValueAsync(_ value: Any?, forKey key: String, completionOnMainQueue: (() -> Void)? = nil) {
        run { core in
            core.setValue(value, forKey: key)
            DispatchQueue.main.async {
                completionOnMainQueue?()
            }
        }
    }
}
