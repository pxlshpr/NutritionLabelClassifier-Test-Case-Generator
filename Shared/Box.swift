import SwiftUI
import VisionSugar
import NutritionLabelClassifier
import TabularData
import SwiftUISugar

extension DataFrame {
    func rowWhereValue1IsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let valueWithId = $0["value1"] as? ValueWithId else { return false }
            return valueWithId.observationId == id
        })
    }
    func rowWhereValue2IsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let valueWithId = $0["value2"] as? ValueWithId else { return false }
            return valueWithId.observationId == id
        })
    }
    func rowWhereAttributeIsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let attributeWithId = $0["attribute"] as? AttributeWithId else { return false }
            return attributeWithId.observationId == id
        })
    }
}
class Box: ObservableObject {
    var id: UUID
    var boundingBox: CGRect
    var rect: CGRect

    var recognizedTextWithLC: RecognizedText?
    var recognizedTextWithoutLC: RecognizedText?

    var attribute: Attribute?
    var value1: Value?
    var value2: Value?
    
    @Published var color: Color
    
    init(recognizedTextWithLC: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.id = UUID()
        self.recognizedTextWithLC = recognizedTextWithLC
        self.boundingBox = recognizedTextWithLC.boundingBox
        self.rect = recognizedTextWithLC.rect
        self.recognizedTextWithoutLC = nil

        self.value1 = nil
        self.value2 = nil
        self.attribute = nil
        self.color = .gray
        
        self.setup(dataFrame: nutrientsDataFrame, id: recognizedTextWithLC.id)
//        if let row = nutrientsDataFrame.rowWhereValue1IsFromRecognizedText(with: id), let valueWithId = row["value1"] as? ValueWithId
//        {
//            value1 = valueWithId.value
//            value2 = nil
//            color = .green
//        }
//        else if let row = nutrientsDataFrame.rowWhereValue2IsFromRecognizedText(with: id), let valueWithId = row["value2"] as? ValueWithId
//        {
//            value1 = nil
//            value2 = valueWithId.value
//            color = .green
//        }
//        else if let row = nutrientsDataFrame.rowWhereAttributeIsFromRecognizedText(with: id), let attributeWithId = row["attribute"] as? AttributeWithId
//        {
//            value1 = nil
//            value2 = nil
//            attribute = attributeWithId.attribute
//            color = .cyan
//        } else {
//            value1 = nil
//            value2 = nil
//            attribute = nil
//            color = .gray
//        }
    }
    
    func setup(dataFrame: DataFrame, id: UUID) {
        if let row = dataFrame.rowWhereValue1IsFromRecognizedText(with: id), let valueWithId = row["value1"] as? ValueWithId
        {
            value1 = valueWithId.value
            color = .blue
        }
        
        if let row = dataFrame.rowWhereValue2IsFromRecognizedText(with: id), let valueWithId = row["value2"] as? ValueWithId
        {
            value2 = valueWithId.value
            color = .blue
        }
        
        if let row = dataFrame.rowWhereAttributeIsFromRecognizedText(with: id), let attributeWithId = row["attribute"] as? AttributeWithId
        {
            attribute = attributeWithId.attribute
            if value1 != nil || value2 != nil {
                color = .blue
            } else {
                color = .cyan
            }
        }
    }

    init(recognizedTextWithoutLC: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.id = UUID()
        self.recognizedTextWithoutLC = recognizedTextWithoutLC
        self.boundingBox = recognizedTextWithoutLC.boundingBox
        self.rect = recognizedTextWithoutLC.rect
        self.recognizedTextWithLC = nil

        if let row = nutrientsDataFrame.rows.first(where: {
            guard let valueWithId = $0["value1"] as? ValueWithId else { return false }
            return valueWithId.observationId == recognizedTextWithoutLC.id
        }), let valueWithId = row["value1"] as? ValueWithId
        {
            value1 = valueWithId.value
            value2 = nil
            color = .indigo
        } else {
            value1 = nil
            value2 = nil
            color = .mint
        }
        attribute = nil
    }

    var hasClassifierResult: Bool {
        attribute != nil || value1 != nil || value2 != nil
    }
    
    func croppedImage(from image: UIImage, for contentSize: CGSize, completion: @escaping (UIImage) -> Void) {
        let cropRect = boundingBox.rectForSize(image.size)
        let image = image.fixOrientationIfNeeded()
        DispatchQueue.global(qos: .utility).async {
            let croppedImage = self.cropImage(imageToCrop: image, toRect: cropRect)
            DispatchQueue.main.async {
                completion(croppedImage)
            }
        }
    }
    
    func cropImage(imageToCrop:UIImage, toRect rect:CGRect) -> UIImage {
        let imageRef:CGImage = imageToCrop.cgImage!.cropping(to: rect)!
        let cropped:UIImage = UIImage(cgImage:imageRef)
        return cropped
    }
}

extension Box: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(recognizedTextWithLC)
        hasher.combine(recognizedTextWithoutLC)
        hasher.combine(attribute)
        hasher.combine(value1)
        hasher.combine(value2)
    }
    
    static func ==(lhs: Box, rhs: Box) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
