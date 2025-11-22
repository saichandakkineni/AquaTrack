import Foundation

/// Handles unit conversion for water intake
enum WaterUnit: String, CaseIterable, Codable {
    case milliliters = "ml"
    case liters = "L"
    case fluidOunces = "fl oz"
    case cups = "cups"
    
    var displayName: String {
        return rawValue
    }
    
    /// Converts a value from one unit to another
    static func convert(_ value: Double, from: WaterUnit, to: WaterUnit) -> Double {
        // Convert to milliliters first (base unit)
        let mlValue = from.toMilliliters(value)
        // Then convert to target unit
        return to.fromMilliliters(mlValue)
    }
    
    /// Converts to milliliters (base unit)
    func toMilliliters(_ value: Double) -> Double {
        switch self {
        case .milliliters:
            return value
        case .liters:
            return value * 1000
        case .fluidOunces:
            return value * 29.5735
        case .cups:
            return value * 236.588
        }
    }
    
    /// Converts from milliliters to this unit
    func fromMilliliters(_ value: Double) -> Double {
        switch self {
        case .milliliters:
            return value
        case .liters:
            return value / 1000
        case .fluidOunces:
            return value / 29.5735
        case .cups:
            return value / 236.588
        }
    }
    
    /// Formats the value with appropriate decimal places
    func format(_ value: Double) -> String {
        switch self {
        case .milliliters:
            return String(format: "%.0f", value)
        case .liters:
            return String(format: "%.2f", value)
        case .fluidOunces:
            return String(format: "%.1f", value)
        case .cups:
            return String(format: "%.1f", value)
        }
    }
}

/// Unit conversion manager
class UnitConverter {
    static let shared = UnitConverter()
    
    private init() {}
    
    /// Converts and formats a value
    func convertAndFormat(_ value: Double, from: WaterUnit, to: WaterUnit) -> String {
        let converted = WaterUnit.convert(value, from: from, to: to)
        return "\(to.format(converted)) \(to.displayName)"
    }
    
    /// Converts a value between units
    func convert(_ value: Double, from: WaterUnit, to: WaterUnit) -> Double {
        return WaterUnit.convert(value, from: from, to: to)
    }
}

