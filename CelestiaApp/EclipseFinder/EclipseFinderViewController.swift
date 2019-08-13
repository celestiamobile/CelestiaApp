//
//  EclipseFinderViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class EclipseFinderViewController: NSViewController {

    private let core: CelestiaAppCore = AppDelegate.shared.core

    var currentFinder: CelestiaEclipseFinder?

    var results: [EclipseResult] = []

    @IBOutlet weak var eclipseList: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var eclipseReceiverTextField: NSTextField!
    @IBOutlet weak var eclipseStartDateTextField: NSTextField!
    @IBOutlet weak var eclipseEndDateTextField: NSTextField!
    @IBOutlet weak var findButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        eclipseList.target = self
        eclipseList.doubleAction = #selector(go(_:))
    }

    @IBAction func find(_ sender: Any) {
        guard let startDate = eclipseStartDateTextField.objectValue as? Date, let endDate = eclipseEndDateTextField.objectValue as? Date else {
            NSAlert.warning(message: NSLocalizedString("No Starting or Ending Date Entered", comment: ""),
                            text: NSLocalizedString("Please enter starting and ending dates.", comment: ""))
            return
        }

        let receiver = eclipseReceiverTextField.stringValue

        guard receiver.count > 0 else {
            NSAlert.warning(message: NSLocalizedString("Object Not Found", comment: ""),
                            text: NSLocalizedString("Please check that the object name is correct.", comment: ""))
            return
        }

        let selection = core.simulation.findObject(from: receiver)
        guard let system = selection.body?.system, !receiver.isEmpty else {
            NSAlert.warning(message: NSLocalizedString("Object Not Found", comment: ""),
                            text: NSLocalizedString("Please check that the object name is correct.", comment: ""))
            return
        }

        let parameter: (body: CelestiaBody, kind: EclipseKind)

        if let primary = system.primaryObject {
            // Eclipse receiver is a moon -> find lunar eclipses
            parameter = (primary, .lunar)
        } else {
            // Solar eclipse
            parameter = (selection.body!, .solar)
        }

        progressIndicator.startAnimation(self)
        findButton.isEnabled = false
        DispatchQueue.global().async { [weak self] in
            let finder = CelestiaEclipseFinder(body: parameter.body)
            self?.currentFinder = finder
            let results = finder.search(kind: parameter.kind, from: startDate, to: endDate)
            self?.currentFinder = nil
            DispatchQueue.main.async {
                self?.findButton.isEnabled = true
                self?.progressIndicator.stopAnimation(self)
                self?.results = results
                self?.eclipseList.reloadData()
            }
        }
    }

    @IBAction func stop(_ sender: Any) {
        currentFinder?.abort()
    }

    @objc private func go(_ sender: Any) {
        let selected = eclipseList.selectedRow
        guard selected >= 0 else { return }

        let eclipse = results[selected]
        core.simulation.time = eclipse.startTime
        let target = CelestiaSelection(body: eclipse.receiver)
        let ref = CelestiaSelection(star: eclipse.receiver.system!.star!)
        core.simulation.goToEclipse(occulter: ref, receiver: target)
    }
}

extension EclipseFinderViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let eclipse = results[row]
        switch tableColumn?.identifier.rawValue {
        case "occulter":
            return eclipse.occulter.name
        case "receiver":
            return eclipse.receiver.name
        case "date":
            fallthrough
        case "begin":
            return eclipse.startTime
        case "duration":
            fallthrough
        default:
            return eclipse.endTime.timeIntervalSince(eclipse.startTime)
        }
    }
}
