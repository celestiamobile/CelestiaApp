//
//  GotoViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class GotoViewController: NSViewController {
    private let core: CelestiaAppCore = AppDelegate.shared.core

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
            objectNameComboBox.stringValue = current.selection.name
            longitudeTextField.doubleValue = current.longitude
            latitudeTextField.doubleValue = current.latitude
            distanceTextField.doubleValue = current.distance
        }
    }

    @IBAction func go(_ sender: Any) {
        let name = objectNameComboBox.stringValue
        guard name.count > 0 else {
            NSAlert.warning(message: NSLocalizedString("No Object Name Entered", comment: ""),
                            text: NSLocalizedString("Please enter an object name.", comment: ""))
            return
        }

        let sel = core.simulation.findObject(from: name)
        if sel.isEmpty {
            NSAlert.warning(message: NSLocalizedString("Object Not Found", comment: ""),
                            text: NSLocalizedString("Please check that the object name is correct.", comment: ""))
            return
        }

        let location: CelestiaGoToLocation
        if distanceTextField.stringValue.count > 0 {

            let selectedItem = unitPopupButton.indexOfSelectedItem
            let unit = SimulationDistanceUnit(rawValue: UInt(selectedItem))!

            if longitudeTextField.stringValue.count > 0 && latitudeTextField.stringValue.count > 0 {
                location = CelestiaGoToLocation(selection: sel,
                                                longitude: longitudeTextField.doubleValue,
                                                latitude: latitudeTextField.doubleValue,
                                                distance: distanceTextField.doubleValue,
                                                unit: unit)
            } else {
                location = CelestiaGoToLocation(selection: sel,
                                                distance: distanceTextField.doubleValue,
                                                unit: unit)
            }
        } else {
            if longitudeTextField.stringValue.count > 0 && latitudeTextField.stringValue.count > 0 {
                location = CelestiaGoToLocation(selection: sel,
                                                longitude: longitudeTextField.doubleValue,
                                                latitude: latitudeTextField.doubleValue)
            } else {
                location = CelestiaGoToLocation(selection: sel)
            }
        }
        core.simulation.go(to: location)
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
                let suggestions = self.core.simulation.universe.starCatalog.completion(for: text) + self.core.simulation.universe.dsoCatalog.completion(for: text)
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
