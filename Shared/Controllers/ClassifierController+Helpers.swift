import SwiftUI
import NutritionLabelClassifier

extension ClassifierController {
    var servingExpectations: [Expectation] {
        expectations.filter { $0.attribute.isServingAttribute }
    }
    
    var nutrientExpectations: [Expectation] {
        expectations.filter { $0.attribute.isNutrientAttribute }
    }
    
    var headerExpectations: [Expectation] {
        expectations.filter { $0.attribute.isHeaderAttribute }
    }
    
    var unusedServingAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isServingAttribute && shouldAllowAdding($0) }
    }
    
    var unusedNutrientAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isNutrientAttribute && shouldAllowAdding($0) }
    }
    
    var unusedHeaderAttributes: [Attribute] {
        Attribute.allCases.filter {
            $0.isHeaderAttribute
            && shouldAllowAdding($0)
        }
    }
    
    var shouldShowServingExpectations: Bool {
        unusedServingAttributes.count > 0 || servingExpectations.count > 0
    }
    
    var shouldShowHeaderExpectations: Bool {
        unusedHeaderAttributes.count > 0 || headerExpectations.count > 0
    }
    
    var shouldShowNutrientExpectations: Bool {
        unusedNutrientAttributes.count > 0 || nutrientExpectations.count > 0
    }
    
    var availableHeaderTypes: [HeaderType] {
        HeaderType.allCases.filter { type in
            guard let output = classifierOutput else {
                return false
            }
            if let header1Type = output.nutrients.header1Type, observations.first(where: { $0.attribute == .headerType1 })?.status != .invalid, type == header1Type {
                return false
            }
            if let header2Type = output.nutrients.header2Type, observations.first(where: { $0.attribute == .headerType2 })?.status != .invalid, type == header2Type {
                return false
            }
            return !expectations.contains(where: {
                if let headerType = $0.headerType, type == headerType {
                    return true
                }
                return false
            })
        }
    }
}

extension ClassifierController {
    func deleteServingExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: servingExpectations[index])
    }

    func deleteNutrientExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: nutrientExpectations[index])
    }

    func deleteHeaderExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: headerExpectations[index])
    }

    func delete(expectation: Expectation) {
        guard let index = expectations.firstIndex(where: { $0.attribute == expectation.attribute }) else { return }
        withAnimation {
            let _ = expectations.remove(at: index)
        }
    }
}
