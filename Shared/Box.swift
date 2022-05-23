import SwiftUI
import VisionSugar
import NutritionLabelClassifier
import TabularData

class Box: ObservableObject {
    var id: UUID { recognizedText.id }
    let recognizedText: RecognizedText
    
    let attribute: Attribute?
    let value1: Value?
    let value2: Value?
    
    @Published var color: Color
    
    init(recognizedText: RecognizedText, nutrientsDataFrame: DataFrame) {
        
        self.recognizedText = recognizedText
        
        if let row = nutrientsDataFrame.rows.first(where: {
            guard let valueWithId = $0["value1"] as? ValueWithId else { return false }
            return valueWithId.observationId == recognizedText.id
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
    
    var hasClassifierResult: Bool {
        attribute != nil || value1 != nil || value2 != nil
    }
    
    func croppedImage(from image: UIImage, for contentSize: CGSize, completion: @escaping (UIImage) -> Void) {
        let cropRect = recognizedText.boundingBox.rectForSize(image.size)
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
        hasher.combine(recognizedText)
        hasher.combine(attribute)
        hasher.combine(value1)
        hasher.combine(value2)
    }
    
    static func ==(lhs: Box, rhs: Box) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
