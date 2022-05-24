import SwiftUI
import NutritionLabelClassifier
import VisionSugar
import Vision
import SwiftUISugar
import TabularData

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var pickedImage: UIImage? = nil
        @Published var isPresentingImagePicker = false

//        @Published var recognizedTexts: [RecognizedText]? = nil
//        @Published var nutrientsDataFrame: DataFrame? = nil
        
        @Published var boxes: [Box] = []
        @Published var boxesToDisplay: [Box] = []
        @Published var filteredBoxes: [Box] = []

        @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil

        @Published var typeFilter: BoxType? = nil {
            didSet {
                setFilteredBoxes()
            }
        }
        
        @Published var statusFilter: BoxStatus? = nil {
            didSet {
                setFilteredBoxes()
            }
        }
        
        var contentSize: CGSize = .zero
        var observationsWithLC: [VNRecognizedTextObservation] = []
        var observationsWithoutLC: [VNRecognizedTextObservation] = []
    }
}

extension ContentView.ViewModel {

    func setFilteredBoxes() {
        filteredBoxes = boxes.filter({ box in
            if let statusFilter = statusFilter {
                if box.status != statusFilter {
                    return false
                }
            }
            if let typeFilter = typeFilter {
                if box.type != typeFilter {
                    return false
                }
            }
            return true
        })
    }
    
    func didPickImage(_ image: UIImage) {
        print("Got an image with size: \(image.size)")
        DispatchQueue.main.async {
            self.pickedImage = image
        }
        self.recognizeTextsInImage(image)
    }
    
    func recognizeTextsInImage(_ image: UIImage) {
        observationsWithLC = []
        VisionSugar.recognizeTexts(in: image, useLanguageCorrection: true) { observations in
            guard let observations = observations else { return }
            self.observationsWithLC = observations
            
            VisionSugar.recognizeTexts(in: image, useLanguageCorrection: false) { observations in
                guard let observations = observations else { return }
                self.observationsWithoutLC = observations
                self.calculateBoxes(in: image)
            }
        }
    }
    
    func calculateBoxes(in image: UIImage) {
        let recognizedTextsWithLC = VisionSugar.recognizedTexts(
            of: observationsWithLC,
            for: image, inContentSize: self.contentSize)

        let recognizedTextsWithoutLC = VisionSugar.recognizedTexts(
            of: observationsWithoutLC,
            for: image, inContentSize: self.contentSize)
                
        let nutrientsDataFrame = NutritionLabelClassifier.dataFrameOfNutrients(from: [recognizedTextsWithLC, recognizedTextsWithoutLC])
        
        var boxes: [Box] = []
        for recognizedText in recognizedTextsWithLC {
            boxes.append(Box(recognizedTextWithLC: recognizedText, nutrientsDataFrame: nutrientsDataFrame))
        }
        for recognizedText in recognizedTextsWithoutLC {
            if let box = boxes.first(where: { $0.rect == recognizedText.rect }) {
                box.recognizedTextWithoutLC = recognizedText
            } else {
                boxes.append(Box(recognizedTextWithoutLC: recognizedText, nutrientsDataFrame: nutrientsDataFrame))
            }
        }
        
        DispatchQueue.main.async {
            self.boxes = boxes
            self.filteredBoxes = boxes
        }
    }

}
