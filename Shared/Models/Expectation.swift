import NutritionLabelClassifier

struct Expectation {
    let attribute: Attribute
    let value1: Value?
    let value2: Value?
    let double: Double?
    let string: String?
    let unit: NutritionUnit?
    let headerType: HeaderType?

    init(attribute: Attribute, value1: Value? = nil, value2: Value? = nil, double: Double? = nil, string: String? = nil, unit: NutritionUnit? = nil, headerType: HeaderType? = nil) {
        self.attribute = attribute
        self.value1 = value1
        self.value2 = value2
        self.double = double
        self.string = string
        self.unit = unit
        self.headerType = headerType
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
        /// Column Header when we have both Double and String
        else if let type = headerType {
            if type == .per100g {
                description = type.description
            } else {
                if let string = string, !string.isEmpty {
                    description = "\(type.description) (\(string))"
                } else {
                    description = "\(type.description)"
                }
            }
        }
        else if let double = double {
            description = "\(double.clean)"
        }
        else if let string = string {
            description = string
        }
        else if let unit = unit {
            description = unit.description
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
