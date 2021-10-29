//
// GotoViewController.swift
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

class GotoViewController: NSViewController {
    private let core: AppCore = AppCore.shared

    private var searchOperationQueue = OperationQueue()

    private var suggestions: [String] = []

    @IBOutlet weak var objectNameComboBox: NSComboBox!
    @IBOutlet weak var latitudeTextField: NSTextField!
    @IBOutlet weak var longitudeTextField: NSTextField!
    @IBOutlet weak var distanceTextField: NSTextField!
    @IBOutlet weak var unitPopupButton: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        searchOperationQueue.maxConcurrentOperationCount = 1

        objectNameComboBox.usesDataSource = true
        objectNameComboBox.dataSource = self
        objectNameComboBox.delegate = self

        if let current = core.simulation.currentLocation {
            objectNameComboBox.stringValue = core.simulation.universe.name(for: current.selection)
            longitudeTextField.floatValue = current.longitude
            latitudeTextField.floatValue = current.latitude
            distanceTextField.doubleValue = current.distance
        }
    }

    @IBAction func go(_ sender: Any) {
        let name = objectNameComboBox.stringValue
        guard name.count > 0 else {
            NSAlert.warning(message: CelestiaString("No object name entered", comment: ""),
                            text: CelestiaString("Please enter an object name.", comment: ""))
            return
        }

        let sel = core.simulation.findObject(from: name)
        if sel.isEmpty {
            NSAlert.warning(message: CelestiaString("Object not found", comment: ""),
                            text: CelestiaString("Please check that the object name is correct.", comment: ""))
            return
        }

        let location: GoToLocation
        if distanceTextField.stringValue.count > 0 {

            let selectedItem = unitPopupButton.indexOfSelectedItem
            let unit = DistanceUnit(rawValue: UInt(selectedItem))!

            if longitudeTextField.stringValue.count > 0 && latitudeTextField.stringValue.count > 0 {
                location = GoToLocation(selection: sel,
                                                longitude: longitudeTextField.floatValue,
                                                latitude: latitudeTextField.floatValue,
                                                distance: distanceTextField.doubleValue,
                                                unit: unit)
            } else {
                location = GoToLocation(selection: sel,
                                                distance: distanceTextField.doubleValue,
                                                unit: unit)
            }
        } else {
            if longitudeTextField.stringValue.count > 0 && latitudeTextField.stringValue.count > 0 {
                location = GoToLocation(selection: sel,
                                                longitude: longitudeTextField.floatValue,
                                                latitude: latitudeTextField.floatValue)
            } else {
                location = GoToLocation(selection: sel)
            }
        }
        core.run { $0.simulation.go(to: location) }
    }
}

extension GotoViewController: NSComboBoxDataSource, NSComboBoxDelegate {

    func controlTextDidChange(_ obj: Notification) {
        if let object = obj.object as? NSComboBox, object == objectNameComboBox, let cell = object.cell, cell.isAccessibilityExpanded() {
            autoComplete(with: objectNameComboBox.stringValue)
        }
    }

    func comboBoxWillPopUp(_ notification: Notification) {
        if let obj = notification.object as? NSComboBox, obj == objectNameComboBox {
            let input = obj.stringValue
            autoComplete(with: input)
        }
    }

    func autoComplete(with text: String) {
        searchOperationQueue.cancelAllOperations()
        if text.isEmpty {
            suggestions = []
            objectNameComboBox.reloadData()
        } else {
            searchOperationQueue.addOperation { [weak self] in
                guard let self = self else { return }
                let suggestions = self.core.simulation.completion(for: text)
                DispatchQueue.main.async {
                    self.suggestions = suggestions
                    self.objectNameComboBox.reloadData()
                }
            }
        }
    }

    func comboBoxSelectionIsChanging(_ notification: Notification) {
        print("is changing")
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        print("did change")
    }

    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        return nil
    }

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return suggestions.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return suggestions[index]
    }

}
