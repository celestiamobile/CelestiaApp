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

    @IBOutlet weak var objectNameTextField: NSTextField!
    @IBOutlet weak var latitudeTextField: NSTextField!
    @IBOutlet weak var longitudeTextField: NSTextField!
    @IBOutlet weak var distanceTextField: NSTextField!
    @IBOutlet weak var unitPopupButton: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let current = core.simulation.currentLocation {
            objectNameTextField.stringValue = current.selection.name
            longitudeTextField.doubleValue = current.longitude
            latitudeTextField.doubleValue = current.latitude
            distanceTextField.doubleValue = current.distance
        }
    }

    @IBAction func go(_ sender: Any) {
        let name = objectNameTextField.stringValue
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
