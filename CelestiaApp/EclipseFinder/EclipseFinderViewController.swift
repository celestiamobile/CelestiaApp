//
// EclipseFinderViewController.swift
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

class EclipseFinderViewController: NSViewController {

    private let core: CelestiaAppCore = CelestiaAppCore.shared

    var currentFinder: CelestiaEclipseFinder?

    var results: [CelestiaEclipse] = []

    @IBOutlet weak var eclipseList: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var objectNameComboBox: NSComboBox!
    @IBOutlet weak var eclipseStartDatePicker: NSDatePicker!
    @IBOutlet weak var eclipseEndDatePicker: NSDatePicker!
    @IBOutlet weak var findButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        eclipseList.target = self
        eclipseList.doubleAction = #selector(go(_:))

        objectNameComboBox.addItem(withObjectValue: CelestiaString("Earth", comment: "", domain: "celestia"))
        objectNameComboBox.addItem(withObjectValue: CelestiaString("Jupiter", comment: "", domain: "celestia"))

        eclipseStartDatePicker.dateValue = Date()
        eclipseEndDatePicker.dateValue = Date()
    }

    @IBAction func find(_ sender: Any) {
        let startDate = eclipseStartDatePicker.dateValue
        let endDate = eclipseEndDatePicker.dateValue

        let receiver = objectNameComboBox.stringValue

        guard !receiver.isEmpty  else {
            NSAlert.warning(message: CelestiaString("Object not found", comment: ""),
                            text: CelestiaString("Please check that the object name is correct.", comment: ""))
            return
        }

        let selection = core.simulation.findObject(from: receiver)
        guard let body = selection.body else {
            NSAlert.warning(message: CelestiaString("Object not found", comment: ""),
                            text: CelestiaString("Please check that the object name is correct.", comment: ""))
            return
        }

        progressIndicator.startAnimation(self)
        findButton.isEnabled = false
        DispatchQueue.global().async { [weak self] in
            let finder = CelestiaEclipseFinder(body: body)
            self?.currentFinder = finder
            let results = finder.search(kind: [.solar, .lunar], from: startDate, to: endDate)
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
        core.simulation.goToEclipse(eclipse)
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
