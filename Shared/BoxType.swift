import Foundation

enum BoxType: Int, CaseIterable {
    case unrecognized
    case attribute
    case value1
    case value2
    case value1value2
    case attributeValue1
    case attributeValue2
    case attributeValue1Value2
    
    var description: String {
        switch self {
        case .unrecognized:
            return "Unrecognized"
        case .attribute:
            return "Attribute"
        case .value1:
            return "Value 1"
        case .value2:
            return "Value 2"
        case .value1value2:
            return "Value 1 & 2"
        case .attributeValue1:
            return "Attribute & Value 1"
        case .attributeValue2:
            return "Attribute & Value 2"
        case .attributeValue1Value2:
            return "Attribute & Value 1 & 2"
        }
    }
}
