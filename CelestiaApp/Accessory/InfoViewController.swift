//
//  InfoViewController.swift
//  Celestia
//
//  Created by Li Linfeng on 14/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa
import CelestiaCore

class InfoViewController: NSViewController {
    private let core: CelestiaAppCore = AppDelegate.shared.core

    var selection: CelestiaSelection!

    @IBOutlet weak var webInfoButton: NSButton!
    @IBOutlet weak var contentTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let attr: NSAttributedString?

        if let body = selection.body {
            attr = attributedTextForBody(body)
        } else if let star = selection.star {
            attr = attributedTextForStar(star)
        } else if let dso = selection.dso {
            attr = attributedTextForDSO(dso)
        } else {
            attr = nil
        }

        contentTextView.textStorage?.setAttributedString(attr ?? NSAttributedString())

        if let urlStr = selection.webInfoURL, URL(string: urlStr) != nil {
            webInfoButton.isEnabled = true
        } else {
            webInfoButton.isEnabled = false
        }
    }
    
    @IBAction func openWebURL(_ sender: Any) {
        if let urlStr = selection.webInfoURL, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    func attributedTextForBody(_ body: CelestiaBody) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        attr.appendPrimaryText("\(body.name)")
        attr.appendEmptyLine()

        if body.isEllipsoid {
            attr.appendSecondaryText(String(format: NSLocalizedString("Equatorial radius: %@", comment: ""), body.radius.radiusString))
        } else {
            attr.appendSecondaryText(String(format: NSLocalizedString("Size: %@", comment: ""), body.radius.radiusString))
        }

        let orbit = body.orbit(at: core.simulation.time)
        let rotation = body.rotation(at: core.simulation.time)

        let orbitalPeriod: TimeInterval = orbit.isPeriodic ? orbit.period : 0

        if rotation.isPeriodic && body.type != .spacecraft {

            var rotPeriod = rotation.period

            var dayLength: TimeInterval = 0.0

            if orbit.isPeriodic {
                let siderealDaysPerYear = orbitalPeriod / rotPeriod
                let solarDaysPerYear = siderealDaysPerYear - 1.0
                if solarDaysPerYear > 0.0001 {
                    dayLength = orbitalPeriod / (siderealDaysPerYear - 1.0)
                }
            }

            let unit: String

            if rotPeriod < 2.0 {
                rotPeriod *= 24.0
                dayLength *= 24.0

                unit = NSLocalizedString("hours", comment: "")
            } else {
                unit = NSLocalizedString("days", comment: "")
            }
            attr.appendEmptyLine()
            attr.appendSecondaryText(String(format: NSLocalizedString("Sidereal rotation period: %.2f %@", comment: ""), rotPeriod, unit))
            if dayLength != 0 {
                attr.appendLineBreak()
                attr.appendSecondaryText(String(format: NSLocalizedString("Length of day: %.2f %@", comment: ""), dayLength, unit))
            }
        }

        if body.hasRings || body.hasAtmosphere {
            attr.appendEmptyLine()
            body.hasRings ? attr.appendSecondaryText(NSLocalizedString("Has rings", comment: "")) : ()
            body.hasAtmosphere ? attr.appendSecondaryText(NSLocalizedString("Has atmosphere", comment: "")) : ()
        }

        return NSAttributedString(attributedString: attr)
    }

    func attributedTextForStar(_ star: CelestiaStar) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        let name = core.simulation.universe.catalog.starName(star)

        let time = core.simulation.time

        attr.appendPrimaryText("\(name)")
        attr.appendEmptyLine()

        let celPos = star.position(at: time).offet(from: .zero)
        let eqPos = Astro.ecliptic(toEquatorial: Astro.cel(toJ2000Ecliptic: celPos))
        let sph = Astro.rect(toSpherical: eqPos)

        let hms = DMS(decimal: sph.dx)
        attr.appendSecondaryText(String(format: NSLocalizedString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds)))

        attr.appendLineBreak()
        let dms = DMS(decimal: sph.dy)
        attr.appendSecondaryText(String(format: NSLocalizedString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))


        return NSAttributedString(attributedString: attr)
    }

    func attributedTextForDSO(_ dso: CelestiaDSO) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        let name = core.simulation.universe.catalog.dsoName(dso)

        attr.appendPrimaryText("\(name)")
        attr.appendEmptyLine()

        let celPos = dso.position
        let eqPos = Astro.ecliptic(toEquatorial: Astro.cel(toJ2000Ecliptic: celPos))
        var sph = Astro.rect(toSpherical: eqPos)

        let hms = DMS(decimal: sph.dx)
        attr.appendSecondaryText(String(format: NSLocalizedString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds)))

        attr.appendLineBreak()
        var dms = DMS(decimal: sph.dy)
        attr.appendSecondaryText(String(format: NSLocalizedString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        let galPos = Astro.equatorial(toGalactic: eqPos)
        sph = Astro.rect(toSpherical: galPos)

        attr.appendLineBreak()
        dms = DMS(decimal: sph.dx)
        attr.appendSecondaryText(String(format: NSLocalizedString("L: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        attr.appendLineBreak()
        dms = DMS(decimal: sph.dy)
        attr.appendSecondaryText(String(format: NSLocalizedString("B: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        return NSAttributedString(attributedString: attr)
    }
}

fileprivate extension Float {
    var radiusString: String {
        if self < 1 {
            return String(format: NSLocalizedString("%d \(NSLocalizedString("m", comment: ""))", comment: ""), Int(self * 1000))
        }
        return String(format: NSLocalizedString("%d \(NSLocalizedString("km", comment: ""))", comment: ""), Int(self))
    }
}

extension NSMutableAttributedString {
    func appendPrimaryText(_ string: String) {
        append(NSAttributedString(string: string, attributes: [
            .foregroundColor : NSColor.labelColor,
            .font : NSFont.systemFont(ofSize: 17)
        ]))
    }

    func appendSecondaryText(_ string: String) {
        append(NSAttributedString(string: string, attributes: [
            .foregroundColor : NSColor.secondaryLabelColor,
            .font : NSFont.systemFont(ofSize: 13)
        ]))
    }

    func appendLineBreak(count: Int = 1) {
        appendSecondaryText(String(repeating: "\n", count: count))
    }

    func appendEmptyLine(count: Int = 1) {
        appendLineBreak(count: 2 * count)
    }
}
