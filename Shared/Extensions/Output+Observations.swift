import Foundation
import NutritionLabelClassifier

extension Output {
    
    var observations: [Observation] {
        
        var observations: [Observation] = []

        for attribute in Attribute.nonNutrientObservations {
            if let observation = observation(for: attribute) {
                observations.append(observation)
            }
        }
                
        for nutrient in nutrients.rows {
            let observation = Observation(
                attributeText: nutrient.attributeText,
                value1Text: nutrient.valueText1,
                value2Text: nutrient.valueText2
            )
            observations.append(observation)
        }

        return observations
    }
    
    func observation(for attribute: Attribute) -> Observation? {
        switch attribute {
        case .servingAmount:
            if let doubleText = serving?.amountText {
                return Observation(attributeText:
                                    
                )
            }
        case .servingUnit:
            <#code#>
        case .servingUnitSize:
            <#code#>
        case .servingEquivalentAmount:
            <#code#>
        case .servingEquivalentUnit:
            <#code#>
        case .servingEquivalentUnitSize:
            <#code#>
        case .servingsPerContainerAmount:
            <#code#>
        case .servingsPerContainerName:
            <#code#>
        case .headerType1:
            <#code#>
        case .headerType2:
            <#code#>
        case .headerServingAmount:
            <#code#>
        case .headerServingUnit:
            <#code#>
        case .headerServingUnitSize:
            <#code#>
        case .headerServingEquivalentAmount:
            <#code#>
        case .headerServingEquivalentUnit:
            <#code#>
        case .headerServingEquivalentUnitSize:
            <#code#>
        default:
            return nil
        }
    }
}


extension Attribute {
    static var nonNutrientObservations: [Attribute] {
        allCases.filter { $0.isServingAttribute || $0.isHeaderAttribute }
//        [.servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerAmount, .servingsPerContainerName, .headerType1, .headerType2, .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize]
    }
    

}
