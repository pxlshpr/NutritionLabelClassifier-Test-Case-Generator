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
            attributeText?.textId,
            value1Text?.textId,
            value2Text?.textId,
            doubleText?.textId,
            stringText?.textId,
            unitText?.textId,
            headerText?.textId,
            doubleText?.attributeTextId,
            stringText?.attributeTextId,
            unitText?.attributeTextId,
            headerText?.attributeTextId
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
        boxes.first { $0.id == id }
    }
    
    func rectForBox(withId id: UUID) -> CGRect? {
        box(withId: id)?.rect
    }
}
