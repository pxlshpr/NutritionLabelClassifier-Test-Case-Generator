import SwiftUI
import VisionSugar
import NutritionLabelClassifier
import TabularData
import SwiftUISugar

class Box: ObservableObject {
    var id: UUID
    var boundingBox: CGRect
    var rect: CGRect

    var recognizedTextWithLC: RecognizedText?
    var recognizedTextWithoutLC: RecognizedText?

    let attribute: Attribute?
    let value1: Value?
    let value2: Value?
    
    @Published var color: Color
    
    init(recognizedTextWithLC: RecognizedText, nutrientsDataFrame: DataFrame) {
        self.id = UUID()
        self.recognizedTextWithLC = recognizedTextWithLC
        self.boundingBox = recognizedTextWithLC.boundingBox
        self.rect = recognizedTextWithLC.rect
        self.recognizedTextWithoutLC = nil

        if let row = nutrientsDataFrame.rows.first(where: {
            guard let valueWithId = $0["value1"] as? ValueWithId else { return false }
            return valueWithId.observationId == recognizedTextWithLC.id
        }), let valueWithId = row["value1"] as? ValueWithId
        {
            value1 = valueWithId.value
            value2 = nil
            color = .green
        } else {
            value1 = nil
            value2 = nil
            color = .cyan
        }
        attribute = nil
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
