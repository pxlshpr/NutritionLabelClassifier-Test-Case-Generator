import SwiftUI
import VisionSugar
import NutritionLabelClassifier
import TabularData
import SwiftUISugar

class Box: ObservableObject, Identifiable {
    
    var ids: [UUID]
    
    var boundingBox: CGRect
    var rect: CGRect

    var recognizedTextWithLC: RecognizedText?
    var recognizedTextWithoutLC: RecognizedText?
    var recognizedTextWithFastRecognition: RecognizedText?

    var attribute: Attribute?
    var value1: Value?
    var value2: Value?
    
    @Published var isFocused: Bool = false
    @Published var isSupplementaryToFocused: Bool = false
    @Published var color: Color
    @Published var status: ObservationStatus = .unmarked
    
    var expectedAttribute: Attribute? = nil
    var expectedValue1: String? = nil
    var expectedValue1Unit: NutritionUnit? = nil
    var expectedValue2: String? = nil
    var expectedValue2Unit: NutritionUnit? = nil

    var type: BoxType {
        if attribute != nil {
            if value1 != nil {
                if value2 != nil {
                    return .attributeValue1Value2
                } else {
                    return .attributeValue1
                }
            } else if value2 != nil {
                return .attributeValue2
            } else {
                return .attribute
            }
        } else if value1 != nil {
            if value2 != nil {
                return .value1value2
            } else {
                return .value1
            }
        } else if value2 != nil {
            return .value2
        } else {
            return .unrecognized
        }
    }
    
    var cellTitle: String {
        recognizedTextWithLC?.string
        ?? recognizedTextWithoutLC?.string
        ?? recognizedTextWithFastRecognition?.string
        ?? ""
    }
    
    init(boundingBox: CGRect, rect: CGRect) {
        self.ids = [UUID()]
        self.boundingBox = boundingBox
        self.rect = rect
        
        self.recognizedTextWithLC = nil
        self.recognizedTextWithoutLC = nil
        self.recognizedTextWithFastRecognition = nil
        
        self.attribute = nil
        self.value1 = nil
        self.value2 = nil
        self.color = .purple
    }
    
    init(recognizedTextWithLC: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.ids = [recognizedTextWithLC.id]
        self.recognizedTextWithLC = recognizedTextWithLC
        self.boundingBox = recognizedTextWithLC.boundingBox
        self.rect = recognizedTextWithLC.rect
        self.recognizedTextWithoutLC = nil
        self.recognizedTextWithFastRecognition = nil

        self.value1 = nil
        self.value2 = nil
        self.attribute = nil
        self.color = .gray
        
        self.setup(dataFrame: nutrientsDataFrame, id: recognizedTextWithLC.id)
    }
    
    func setup(dataFrame: DataFrame, id: UUID) {
        if let row = dataFrame.rowWhereValue1IsFromRecognizedText(with: id), let valueWithId = row["value1"] as? ValueText
        {
            value1 = valueWithId.value
            color = .blue
        }
        
        if let row = dataFrame.rowWhereValue2IsFromRecognizedText(with: id), let valueWithId = row["value2"] as? ValueText
        {
            value2 = valueWithId.value
            color = .blue
        }
        
        if let row = dataFrame.rowWhereAttributeIsFromRecognizedText(with: id), let attributeWithId = row["attribute"] as? AttributeText
        {
            attribute = attributeWithId.attribute
            if value1 != nil || value2 != nil {
                color = .blue
            } else {
                color = .cyan
            }
        }
    }

    init(recognizedTextWithFastRecognition: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.ids = [recognizedTextWithFastRecognition.id]
        self.recognizedTextWithFastRecognition = recognizedTextWithFastRecognition
        self.boundingBox = recognizedTextWithFastRecognition.boundingBox
        self.rect = recognizedTextWithFastRecognition.rect
        self.recognizedTextWithLC = nil
        self.recognizedTextWithoutLC = nil

        self.value1 = nil
        self.value2 = nil
        self.attribute = nil
        self.color = .gray
        
        self.setup(dataFrame: nutrientsDataFrame, id: recognizedTextWithFastRecognition.id)
    }
    
    init(recognizedTextWithoutLC: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.ids = [recognizedTextWithoutLC.id]
        self.recognizedTextWithoutLC = recognizedTextWithoutLC
        self.boundingBox = recognizedTextWithoutLC.boundingBox
        self.rect = recognizedTextWithoutLC.rect
        self.recognizedTextWithLC = nil
        self.recognizedTextWithFastRecognition = nil

        self.value1 = nil
        self.value2 = nil
        self.attribute = nil
        self.color = .gray
        
        self.setup(dataFrame: nutrientsDataFrame, id: recognizedTextWithoutLC.id)

//        if let row = nutrientsDataFrame.rows.first(where: {
//            guard let valueText = $0["value1"] as? ValueText else { return false }
//            return valueText.text.id == recognizedTextWithoutLC.id
//        }), let valueText = row["value1"] as? ValueText
//        {
//            value1 = valueText.value
//            value2 = nil
//            color = .indigo
//        } else {
//            value1 = nil
//            value2 = nil
//            color = .mint
//        }
//        attribute = nil
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
        hasher.combine(recognizedTextWithFastRecognition)
        hasher.combine(attribute)
        hasher.combine(value1)
        hasher.combine(value2)
        hasher.combine(status)
        hasher.combine(expectedAttribute)
        hasher.combine(expectedValue1)
        hasher.combine(expectedValue1Unit)
        hasher.combine(expectedValue2)
        hasher.combine(expectedValue2Unit)
    }
    
    static func ==(lhs: Box, rhs: Box) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DataFrame {
    func rowWhereValue1IsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let valueWithId = $0["value1"] as? ValueText else { return false }
            return valueWithId.text.id == id
        })
    }
    func rowWhereValue2IsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let valueWithId = $0["value2"] as? ValueText else { return false }
            return valueWithId.text.id == id
        })
    }
    func rowWhereAttributeIsFromRecognizedText(with id: UUID) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let attributeWithId = $0["attribute"] as? AttributeText else { return false }
            return attributeWithId.text.id == id
        })
    }
}
