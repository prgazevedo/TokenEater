import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double((rgbValue & 0x0000FF)) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(c.redComponent * 255),
                      Int(c.greenComponent * 255),
                      Int(c.blueComponent * 255))
    }

    static var customUserColor: Color {
        let hex = UserDefaults.standard.string(forKey: "customColor") ?? "#000000"
        return Color(hex: hex)
    }
}

#if canImport(AppKit)
extension NSColor {
    static var customUserColor: NSColor {
        let hex = UserDefaults.standard.string(forKey: "customColor") ?? "#000000"
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: trimmed)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        return NSColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((rgbValue & 0x0000FF)) / 255.0,
            alpha: 1.0
        )
    }
}
#endif

// MARK: - Date Relative Format

extension Date {
    var relativeFormatted: String {
        let interval = Date().timeIntervalSince(self)
        guard interval > 0 else { return "a l'instant" }
        if interval < 60 {
            return "il y a moins d'une minute"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "il y a \(minutes) min"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "il y a \(hours) h"
        } else {
            let days = Int(interval / 86400)
            return "il y a \(days) j"
        }
    }
}
