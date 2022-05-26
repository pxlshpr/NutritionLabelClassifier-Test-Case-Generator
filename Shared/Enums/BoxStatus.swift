import SwiftUI

enum BoxStatus: Int, CaseIterable {
    case unmarked
    case valid
    case invalid
    case irrelevant
    
    var description: String {
        switch self {
        case .unmarked:
            return "Unmarked"
        case .valid:
            return "Valid"
        case .invalid:
            return "Invalid"
        case .irrelevant:
            return "Irrelevant"
        }
    }
    
    var systemImage: String {
        switch self {
        case .unmarked:
            return "questionmark"
        case .valid:
            return "checkmark"
        case .invalid:
            return "xmark"
        case .irrelevant:
            return "trash"
        }
    }
    
    var color: Color {
        switch self {
        case .unmarked:
            return .orange
        case .valid:
            return .green
        case .invalid:
            return .red
        case .irrelevant:
            return .red
        }
    }
}
