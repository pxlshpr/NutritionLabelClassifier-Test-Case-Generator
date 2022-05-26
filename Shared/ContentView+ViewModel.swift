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
        @Published var isPresentingList: Bool = false

        @Published var selectedBox: Box? = nil
        @Published var refreshBool = false

//        @Published var recognizedTexts: [RecognizedText]? = nil
//        @Published var nutrientsDataFrame: DataFrame? = nil
        
        @Published var boxes: [Box] = []
        @Published var boxesToDisplay: [Box] = []
        @Published var filteredBoxes: [Box] = []
        @Published var classifierOutput: Output? = nil

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

    func sendZoomNotification(for box: Box) {
        guard let image = pickedImage else { return }
        
        let userInfo: [String: Any] = [
            Notification.Keys.boundingBox: box.boundingBox,
            Notification.Keys.imageSize: image.size,
        ]
        NotificationCenter.default.post(name: .scrollZoomableScrollViewToRect, object: nil, userInfo: userInfo)
    }
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
        boxes = []
        filteredBoxes = []
        classifierOutput = nil
        
        pickedImage = image
        DispatchQueue.global(qos: .userInteractive).async {
            self.recognizeTextsInImage(image)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPresentingList = true
        }
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

    func recalculateBoxes(for image: UIImage) {
        let recognizedTextsWithLC = VisionSugar.recognizedTexts(
            of: observationsWithLC,
            for: image, inContentSize: self.contentSize)

        let recognizedTextsWithoutLC = VisionSugar.recognizedTexts(
            of: observationsWithoutLC,
            for: image, inContentSize: self.contentSize)
        
        for box in boxes {
            if let recognizedText = recognizedTextsWithLC.first(where: { $0.id == box.recognizedTextWithLC?.id }) {
                box.recognizedTextWithLC = recognizedText
                box.rect = recognizedText.rect
            }
            if let recognizedText = recognizedTextsWithoutLC.first(where: { $0.id == box.recognizedTextWithoutLC?.id }) {
                box.recognizedTextWithoutLC = recognizedText
                box.rect = recognizedText.rect
            }
        }
        
        for box in filteredBoxes {
            if let recognizedText = recognizedTextsWithLC.first(where: { $0.id == box.recognizedTextWithLC?.id }) {
                box.recognizedTextWithLC = recognizedText
                box.rect = recognizedText.rect
            }
            if let recognizedText = recognizedTextsWithoutLC.first(where: { $0.id == box.recognizedTextWithoutLC?.id }) {
                box.recognizedTextWithoutLC = recognizedText
                box.rect = recognizedText.rect
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
                
        let arrayOfRecognizedTexts = [recognizedTextsWithLC, recognizedTextsWithoutLC]
        let nutrientsDataFrame = NutritionLabelClassifier.dataFrameOfNutrients(from: arrayOfRecognizedTexts)
        let classifierOutput = NutritionLabelClassifier.classify(arrayOfRecognizedTexts)
        
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
        
        /// Remove boxes that have no recognized text (either with or without lanugage correction)
        boxes = boxes.filter {
            !$0.cellTitle.isEmpty
        }
        
        DispatchQueue.main.async {
            self.boxes = boxes
            self.filteredBoxes = boxes
            self.classifierOutput = classifierOutput
        }
    }

}
