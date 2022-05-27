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
            if row.attributeId == self.id
                || row.value1Id == self.id
                || row.value2Id == self.id {
                return row
            }
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
        guard let row = nutrientRow,
              row.attributeId != self.id
        else { return nil }
        return row.attribute
    }
    
    var relatedValue1: Value? {
        guard let row = nutrientRow,
              row.value1Id != self.id
        else { return nil }
        return row.value1
    }
    
    var relatedValue2: Value? {
        guard let row = nutrientRow,
              row.value2Id != self.id
        else { return nil }
        return row.value2
    }
}

extension ClassifierController {
    static func box(with id: UUID) -> Box? {
        shared.boxes.first(where: { $0.id == id })
    }
}
