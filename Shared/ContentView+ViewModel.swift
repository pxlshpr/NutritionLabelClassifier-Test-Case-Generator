import SwiftUI
import NutritionLabelClassifier
import VisionSugar
import Vision
import SwiftUISugar

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var pickedImage: UIImage? = nil
        @Published var isPresentingImagePicker = false
        @Published var recognizedTexts: [RecognizedText] = []
        @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil
        var contentSize: CGSize = .zero
        var observations: [VNRecognizedTextObservation]? = nil
    }
}

extension ContentView.ViewModel {
    
    func didPickImage(_ image: UIImage) {
        print("Got an image with size: \(image.size)")
        DispatchQueue.main.async {
            self.pickedImage = image
        }
        self.recognizeTextsInImage(image)
    }
    
    func recognizeTextsInImage(_ image: UIImage) {
        observations = []
        VisionSugar.recognizeTexts(in: image) { observations in
            guard let observations = observations else {
                print("Could not process image")
                return
            }
            self.observations = observations
            self.calculateBoxes(in: image)
        }
    }
    
    func calculateBoxes(in image: UIImage) {
        guard let observations = observations else { return }
        
        let recognizedTexts = VisionSugar.recognizedTexts(of: observations, for: image, inContentSize: self.contentSize)
        let dataFrame = NutritionLabelClassifier.dataFrameOfNutrients(from: recognizedTexts)
        
        for row in dataFrame.rows {
            if let valueWithId = row["value1"] as  {
                print(valueWithId)
            }
        }
        
        DispatchQueue.main.async {
            self.recognizedTexts = recognizedTexts
        }
    }

}
