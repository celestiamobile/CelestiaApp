//
// SetTimeViewController.swift
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

class SetTimeViewController: NSViewController {
    private let core: AppCore = AppCore.shared

    @IBOutlet private weak var dateTimePicker: NSDatePicker!
    @IBOutlet private weak var julianTimeField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        dateTimePicker.dateValue = Date()
        julianTimeField.doubleValue = NSDate().julianDay
    }

    private func currentTime() -> Date {
        return dateTimePicker.dateValue
    }
    
    @IBAction func setTime(_ sender: Any) {
        let current = currentTime()
        core.run { $0.simulation.time = current }
    }

    @IBAction func dateChange(_ sender: Any) {
        julianTimeField.doubleValue = (dateTimePicker.dateValue as NSDate).julianDay
    }

}

extension SetTimeViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        if julianTimeField == textField {
            if julianTimeField.stringValue.isEmpty { return }
            let jd = julianTimeField.doubleValue

            dateTimePicker.dateValue = NSDate(julian: jd) as Date
        }
    }
}
