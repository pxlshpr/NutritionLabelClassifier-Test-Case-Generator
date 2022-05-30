import SwiftUI
import NutritionLabelClassifier

struct Observation {
    
    var attributeText: AttributeText
    var value1Text: ValueText?
    var value2Text: ValueText?
    var doubleText: DoubleText?
    var stringText: StringText?
    var unitText: UnitText?
    var headerTypeText: HeaderText?

    var status: ObservationStatus = .unmarked

    var attribute: Attribute { attributeText.attribute }
    var value1: Value? { value1Text?.value }
    var value2: Value? { value2Text?.value }
    var double: Double? { doubleText?.double }
    var string: String? { stringText?.string }
    var unit: NutritionUnit? { unitText?.unit }
    var headerType: HeaderType? { headerTypeText?.type }

    var combinedRect: CGRect {
        let ids = [attributeText.textId, value1Text?.textId, value2Text?.textId, doubleText?.textId, stringText?.textId, unitText?.textId, headerTypeText?.textId].compactMap { $0 }
        return ids
            .compactMap { ClassifierController.shared.rectForBox(withId: $0) }
            .reduce(.zero, { $0.union($1) })
    }

}

extension ClassifierController {
    func rectForBox(withId id: UUID) -> CGRect? {
        return nil
    }
}
