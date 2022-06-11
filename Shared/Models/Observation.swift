import SwiftUI
import NutritionLabelClassifier

struct Observation {
    
    var attribute: Attribute
    
    var attributeText: AttributeText?
    var value1Text: ValueText?
    var value2Text: ValueText?
    var doubleText: DoubleText?
    var stringText: StringText?
    var unitText: UnitText?
    var headerText: HeaderText?

    var status: ObservationStatus = .unmarked

    var value1: Value? { value1Text?.value }
    var value2: Value? { value2Text?.value }
    var double: Double? { doubleText?.double }
    var string: String? { stringText?.string }
    var unit: NutritionUnit? { unitText?.unit }
    var headerType: HeaderType? { headerText?.type }

    var boxes: [Box] {
        let ids = [
            attributeText?.text.id,
            value1Text?.text.id,
            value2Text?.text.id,
            doubleText?.text.id,
            stringText?.text.id,
            unitText?.text.id,
            headerText?.text.id,
            doubleText?.attributeText.id,
            stringText?.attributeText.id,
            unitText?.attributeText.id,
            headerText?.attributeText.id
        ].compactMap { $0 }
        return ids
            .compactMap { ClassifierController.shared.box(withId: $0) }
    }
    
    var combinedBoundingBox: CGRect {
        let boundingBoxes = boxes.map { $0.boundingBox }
        guard let firstBoundingBox = boundingBoxes.first else { return .zero }
        return boundingBoxes.dropFirst().reduce(firstBoundingBox, { $0.union($1) })
    }

}

extension ClassifierController {
    func box(withId id: UUID) -> Box? {
        boxes.first { $0.ids.contains(id) }
    }
    
    func rectForBox(withId id: UUID) -> CGRect? {
        box(withId: id)?.rect
    }
}
