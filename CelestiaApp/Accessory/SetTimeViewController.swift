//
//  SetTimeViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

extension Date {
    var julianDay: Double {
        return (self as NSDate).julianDay
    }
}

class SetTimeViewController: SettingViewController {
    @IBOutlet private weak var dateTextField: NSTextField!
    @IBOutlet private weak var timeTextField: NSTextField!
    @IBOutlet private weak var julianTimeField: NSTextField!

    private lazy var dateTimeFormat = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        dateTimeFormat.formatterBehavior = .behavior10_4
        dateTimeFormat.dateFormat = "MM/dd/uuuu HH:mm:ss"
    }

    private func currentTime() -> Date? {
        let dateString = dateTextField.stringValue
        let timeString = timeTextField.stringValue

        let useUTC = core.timeZone != 0
        var str = timeString
        if str.isEmpty {
            str = "00:00:00"
        } else {
            let pieces = str.components(separatedBy: ":")
            if pieces[pieces.count - 1].isEmpty {
                str.append("00")
            }
            if pieces.count == 1 {
                str.append(":00:00")
            } else if pieces.count == 2 {
                str.append(":00")
            }
        }

        let input = "\(dateString) \(str)"
        dateTimeFormat.timeZone = useUTC ? TimeZone(abbreviation: "GMT") : .current

        return dateTimeFormat.date(from: input)
    }
    
    @IBAction func setTime(_ sender: Any) {
        let dateString = dateTextField.stringValue
        let timeString = timeTextField.stringValue

        if dateString.count == 0 && timeString.count == 0 {
            NSAlert.warning(message: NSLocalizedString("No Date or Time Entered", comment: ""),
                            text: NSLocalizedString("Please enter a date and/or time.", comment: ""))
            return
        }

        guard let date = currentTime() else {
            NSAlert.warning(message: NSLocalizedString("Improper Date or Time Format", comment: ""),
                            text: NSLocalizedString("Please enter the date as \"mm/dd/yyyy\" and the time as \"hh:mm:ss\".", comment: ""))

            return
        }

        core.simulation.time = date
    }

    @IBAction func cancel(_ sender: Any) {
        view.window?.performClose(self)
    }

}

extension SetTimeViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        if dateTextField == textField || timeTextField == textField {
            if dateTextField.stringValue.isEmpty { return }
            if let jd = currentTime()?.julianDay {
                julianTimeField.doubleValue = jd
            } else {
                NSAlert.warning(message: NSLocalizedString("Improper Date or Time Format", comment: ""),
                                text: NSLocalizedString("Please enter the date as \"mm/dd/yyyy\" and the time as \"hh:mm:ss\".", comment: ""))
            }
        } else if julianTimeField == textField {
            if julianTimeField.stringValue.isEmpty { return }
            let jd = julianTimeField.doubleValue

            let useUTC = core.timeZone != 0
            dateTimeFormat.timeZone = useUTC ? TimeZone(abbreviation: "GMT") : .current

            let dateString = dateTimeFormat.string(from: NSDate(julian: jd) as Date)
            let compos = dateString.components(separatedBy: " ")
            dateTextField.stringValue = compos[0]
            timeTextField.stringValue = compos[1]
        }
    }
}
