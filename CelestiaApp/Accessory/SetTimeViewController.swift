//
//  SetTimeViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa
import CelestiaCore

class SetTimeViewController: NSViewController {
    private let core: CelestiaAppCore = CelestiaAppCore.shared

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
        core.simulation.time = currentTime()
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
