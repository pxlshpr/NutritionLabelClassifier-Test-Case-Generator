import NutritionLabelClassifier
import CoreGraphics
import Foundation
extension Box {
    
    var boundingBoxIncludingRelatedFields: CGRect {
        var union: CGRect = boundingBox
        for box in relatedBoxes {
            union = box.boundingBox.union(union)
        }
        return union
    }
    
    var relatedBoxes: [Box] {
        [relatedAttributeBox, relatedValue1Box, relatedValue2Box].compactMap { $0 }
    }
    
    var hasRelatedFields: Bool {
        relatedAttribute != nil
        || relatedValue1 != nil
        || relatedValue2 != nil
    }

    var nutrientRow: Output.Nutrients.Row? {
        guard let output = ClassifierController.shared.classifierOutput else {
            return nil
        }
        
        for row in output.nutrients.rows {
            if ids.contains(row.attributeId) { return row }
            if let id = row.value1Id, ids.contains(id) { return row }
            if let id = row.value2Id, ids.contains(id) { return row }
        }
        return nil
    }
    
    var relatedAttributeBox: Box? {
        guard let row = nutrientRow else { return nil }
        return ClassifierController.box(with: row.attributeId)
    }

    var relatedValue1Box: Box? {
        guard let row = nutrientRow, let id = row.value1Id else { return nil }
        return ClassifierController.box(with: id)
    }

    var relatedValue2Box: Box? {
        guard let row = nutrientRow, let id = row.value2Id else { return nil }
        return ClassifierController.box(with: id)
    }

    var relatedAttribute: Attribute? {
        guard let row = nutrientRow, !ids.contains(row.attributeId) else { return nil }
        return row.attribute
    }
    
    var relatedValue1: Value? {
        guard let row = nutrientRow else { return nil }
        if let id = row.value1Id {
            guard !ids.contains(id) else { return nil }
        }
        return row.value1
    }
    
    var relatedValue2: Value? {
        guard let row = nutrientRow else { return nil }
        if let id = row.value2Id {
            guard !ids.contains(id) else { return nil }
        }
        return row.value2
    }
}

extension ClassifierController {
    static func box(with id: UUID) -> Box? {
        shared.boxes.first(where: { $0.ids.contains(id) })
    }
}
