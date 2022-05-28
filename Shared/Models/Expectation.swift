import NutritionLabelClassifier

struct Expectation {
    let attribute: Attribute
    let value1: Value?
    let value2: Value?
    let double: Double?
    let string: String?
    let unit: NutritionUnit?
    
    init(attribute: Attribute, value1: Value? = nil, value2: Value? = nil, double: Double? = nil, string: String? = nil, unit: NutritionUnit? = nil) {
        self.attribute = attribute
        self.value1 = value1
        self.value2 = value2
        self.double = double
        self.string = string
        self.unit = unit
    }
}

extension Expectation {
    var valueDescription: String {
        var description: String = ""
        if value1 != nil || value2 != nil {
            if value2 != nil {
                description = "\(value1?.description ?? "(nil)") • \(value2?.description ?? "")"
            } else {
                description = "\(value1?.description ?? "")"
            }
        }
        if let double = double {
            description = "\(double.clean)"
        }
        if let string = string {
            description = string
        }
        if let unit = unit {
            description = unit.rawValue
        }
        return description
    }
}

extension Expectation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(value1)
        hasher.combine(value2)
        hasher.combine(double)
        hasher.combine(string)
        hasher.combine(unit)
    }
}
