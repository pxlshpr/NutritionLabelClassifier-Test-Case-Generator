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
                attribute: nutrient.attribute,
                attributeText: nutrient.attributeText,
                value1Text: nutrient.valueText1,
                value2Text: nutrient.valueText2
            )
            observations.append(observation)
        }

        return observations
    }
        
    func observation(forHeaderServingAttribute attribute: Attribute) -> Observation? {
        guard let headerText = servingHeaderText, let headerServing = headerText.serving else { return nil }
        switch attribute {
        case .headerServingAmount:
            if let double = headerServing.amount {
                return Observation(
                    attribute: .headerServingAmount,
                    doubleText: DoubleText(double: double, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        case .headerServingUnit:
            if let unit = headerServing.unit {
                return Observation(
                    attribute: .headerServingUnit,
                    unitText: UnitText(unit: unit, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        case .headerServingUnitSize:
            if let string = headerServing.unitName {
                return Observation(
                    attribute: .headerServingUnitSize,
                    stringText: StringText(string: string, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        case .headerServingEquivalentAmount:
            if let double = headerServing.equivalentSize?.amount {
                return Observation(
                    attribute: .headerServingEquivalentAmount,
                    doubleText: DoubleText(double: double, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        case .headerServingEquivalentUnit:
            if let unit = headerServing.equivalentSize?.unit {
                return Observation(
                    attribute: .headerServingEquivalentUnit,
                    unitText: UnitText(unit: unit, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        case .headerServingEquivalentUnitSize:
            if let string = headerServing.equivalentSize?.unitName {
                return Observation(
                    attribute: .headerServingEquivalentUnitSize,
                    stringText: StringText(string: string, textId: headerText.textId, attributeTextId: headerText.attributeTextId)
                )
            }
        default:
            return nil
        }
        return nil
    }
    
    func observation(for attribute: Attribute) -> Observation? {
        switch attribute {
        case .servingAmount:
            if let doubleText = serving?.amountText {
                return Observation(attribute: .servingAmount, doubleText: doubleText)
            }
        case .servingUnit:
            if let unitText = serving?.unitText {
                return Observation(attribute: .servingUnit, unitText: unitText)
            }
        case .servingUnitSize:
            if let stringText = serving?.unitNameText {
                return Observation(attribute: .servingUnitSize, stringText: stringText)
            }
        case .servingEquivalentAmount:
            if let doubleText = serving?.equivalentSize?.amountText {
                return Observation(attribute: .servingEquivalentAmount, doubleText: doubleText)
            }
        case .servingEquivalentUnit:
            if let unitText = serving?.equivalentSize?.unitText {
                return Observation(attribute: .servingEquivalentUnit, unitText: unitText)
            }
        case .servingEquivalentUnitSize:
            if let stringText = serving?.equivalentSize?.unitNameText {
                return Observation(attribute: .servingEquivalentUnitSize, stringText: stringText)
            }
        case .servingsPerContainerAmount:
            if let doubleText = serving?.perContainer?.amountText {
                return Observation(attribute: .servingsPerContainerAmount, doubleText: doubleText)
            }
        case .servingsPerContainerName:
            if let stringText = serving?.perContainer?.nameText {
                return Observation(attribute: .servingsPerContainerName, stringText: stringText)
            }
        case .headerType1:
            if let headerText = nutrients.headerText1 {
                return Observation(attribute: .headerType1, headerText: headerText)
            }
        case .headerType2:
            if let headerText = nutrients.headerText2 {
                return Observation(attribute: .headerType2, headerText: headerText)
            }
        case .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize:
            return observation(forHeaderServingAttribute: attribute)
        default:
            return nil
        }
        return nil
    }
}

extension Attribute {
    static var nonNutrientObservations: [Attribute] {
        allCases.filter { $0.isServingAttribute || $0.isHeaderAttribute }
//        [.servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerAmount, .servingsPerContainerName, .headerType1, .headerType2, .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize]
    }
    

}
