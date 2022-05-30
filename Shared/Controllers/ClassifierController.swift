import SwiftUI
import NutritionLabelClassifier
import VisionSugar
import Vision
import SwiftUISugar
import TabularData
import Zip

typealias AttributeRow = (value1: Value?, value2: Value?, double: Double?, string: String?)

class ClassifierController: NSObject, ObservableObject {
    
    static let shared = ClassifierController()

    @Published var pickedImage: UIImage? = nil
    @Published var isPresentingImagePicker = false
    @Published var isPresentingList: Bool = false
    @Published var listTypeBeingPresented: ListType = .output

    @Published var focusedBox: Box? = nil

    @Published var selectedBox: Box? = nil
    @Published var refreshBool = false

    @Published var isPresentingFilePickerForExistingFile = false
    @Published var isPresentingFilePickerForCreatedFile = false
    
//        @Published var recognizedTexts: [RecognizedText]? = nil
//        @Published var nutrientsDataFrame: DataFrame? = nil
    
    var recognizedTextsWithLC: [RecognizedText] = []
    var recognizedTextsWithoutLC: [RecognizedText] = []

    @Published var boxes: [Box] = []
    @Published var boxesToDisplay: [Box] = []
    @Published var filteredBoxes: [Box] = []
    @Published var classifierOutput: Output? = nil
    @Published var outputAttributeStatuses: [Attribute: BoxStatus] = [:]
    
    @Published var expectations: [Expectation] = []
//    @Published var expectedAttributes: [Attribute: AttributeRow] = [:]

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
    
    var status: BoxStatus {
        guard outputAttributeStatuses.count > 0 else { return .unmarked }
        for status in outputAttributeStatuses.values {
            if status == .invalid {
                return .unmarked
            }
        }
        return .valid
    }
    var contentSize: CGSize = .zero
    var observationsWithLC: [VNRecognizedTextObservation] = []
    var observationsWithoutLC: [VNRecognizedTextObservation] = []
}

extension ClassifierController {
    
    var hasAnyColumnHeaders: Bool {
        return false
    }

    func containsExpectation(for attribute: Attribute) -> Bool {
        expectations.contains(where: { $0.attribute == attribute })
    }
    
    func shouldAllowAdding(_ attribute: Attribute) -> Bool {
        if containsOutputAttributeFor(attribute) {
            if let status = outputAttributeStatuses[attribute] {
                return status == .invalid && !containsExpectation(for: attribute)
            } else {
                return false
            }
        }
        return !containsExpectation(for: attribute)
    }
    
    func containsOutputAttributeFor(_ attribute: Attribute) -> Bool {
        guard let output = classifierOutput else { return false }
        return output.containsAttribute(attribute)
    }
    
    var filtersDescription: String {
        let status = statusFilter?.description
        let type = typeFilter?.description
        if let status = status {
            if let type = type {
                return "\(status.description), \(type.description)"
            } else {
                return status.description
            }
        } else if let type = type {
            return type.description
        } else {
            return ""
        }
    }
    
    func focus(on box: Box) {
        guard let image = pickedImage else { return }
        
        focusedBox = box
        
        /// Send zoom notification
        let userInfo: [String: Any] = [
            Notification.Keys.boundingBox: box.boundingBoxIncludingRelatedFields,
            Notification.Keys.imageSize: image.size,
        ]
        NotificationCenter.default.post(name: .scrollZoomableScrollViewToRect, object: nil, userInfo: userInfo)
    }
    
    func resignBoxFocus() {
        focusedBox = nil
        NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
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
    
    func reset() {
        boxes = []
        filteredBoxes = []
        classifierOutput = nil
        outputAttributeStatuses = [:]
        expectations = []
//        expectedAttributes = [:]
    }
    
    func validateAll() {
        guard let output = classifierOutput else { return }
        for attribute in output.nutrients.rows.map({$0.attribute}) {
            outputAttributeStatuses[attribute] = .valid
        }
    }
    
    var containsServingAttributes: Bool {
        guard let output = classifierOutput else { return false }
        return output.containsServingAttributes
    }

//    func add(_ attribute: Attribute) {
//        expectedAttributes[attribute] = AttributeRow(value1: nil, value2: nil, double: nil, string: nil)
//    }
    
    func didPickImage(_ image: UIImage) {
        reset()
        pickedImage = image
        DispatchQueue.global(qos: .userInteractive).async {
            self.recognizeTextsInImage(image)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.listTypeBeingPresented = .output
            self.statusFilter = nil
            self.typeFilter = nil
            self.isPresentingList = true
        }
    }
    
    func recognizeTextsInImage(_ image: UIImage) {
        observationsWithLC = []
        VisionSugar.recognizeTexts(in: image, useLanguageCorrection: true, recognitionLevel: .fast) { observations in
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
        recognizedTextsWithLC = VisionSugar.recognizedTexts(
            of: observationsWithLC,
            for: image, inContentSize: self.contentSize)

        recognizedTextsWithoutLC = VisionSugar.recognizedTexts(
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
        recognizedTextsWithLC = VisionSugar.recognizedTexts(
            of: observationsWithLC,
            for: image, inContentSize: self.contentSize)

        recognizedTextsWithoutLC = VisionSugar.recognizedTexts(
            of: observationsWithoutLC,
            for: image, inContentSize: self.contentSize)
                
        let arrayOfRecognizedTexts = [recognizedTextsWithLC, recognizedTextsWithoutLC]
        let observationsDataFrame = NutritionLabelClassifier(arrayOfRecognizedTexts: arrayOfRecognizedTexts).dataFrameOfObservations()
        let classifierOutput = NutritionLabelClassifier.classify(arrayOfRecognizedTexts)
        
        var boxes: [Box] = []
        for recognizedText in recognizedTextsWithLC {
            boxes.append(Box(recognizedTextWithLC: recognizedText, nutrientsDataFrame: observationsDataFrame))
        }
        for recognizedText in recognizedTextsWithoutLC {
            if let box = boxes.first(where: { $0.rect == recognizedText.rect }) {
                box.recognizedTextWithoutLC = recognizedText
            } else {
                boxes.append(Box(recognizedTextWithoutLC: recognizedText, nutrientsDataFrame: observationsDataFrame))
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

extension ClassifierController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        
        appendTestCaseToExistingFile(at: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true) {
        }
        print("Cancelled")
    }
}
