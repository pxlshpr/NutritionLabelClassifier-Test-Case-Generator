import SwiftUI
import SwiftUISugar
import NutritionLabelClassifier
import SwiftHaptics

extension Attribute: SelectionOption {
    public var optionId: String {
        rawValue
    }
}

extension NutritionUnit: SelectionOption {
    public var optionId: String {
        description
    }
}

extension BoxDetailsView: FieldContentProvider {
    func menuTitle(for option: SelectionOption, isPlural: Bool) -> String? {
        if let option = option as? CustomStringConvertible {
            return option.description
        } else {
            return option.optionId
        }
    }
    
    func title(for option: SelectionOption, isPlural: Bool) -> String? {
        if let option = option as? CustomStringConvertible {
            return option.description
        } else {
            return option.optionId
        }
    }
}
struct BoxDetailsView: View {
    
    @Binding var box: Box
//    @ObservedObject var classifierController: ClassifierController
    @State var boxImage: UIImage? = nil
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    @State var expectedAttribute: SelectionOption = Attribute.energy
    @State var expectedValue1: String = ""
    @State var expectedValue1Unit: SelectionOption = NutritionUnit.g
    @State var expectedValue2: String = ""
    @State var expectedValue2Unit: SelectionOption = NutritionUnit.g
    
    init(box: Binding<Box>) {
        self._box = box
//        self.classifierController = classifierController
        self.fillFields()
    }
    
    init(boxId: UUID) {
        if let box = ClassifierController.shared.boxes.first(where: { $0.id == boxId }) {
            self._box = .constant(box)
        } else {
            self._box = .constant(ClassifierController.shared.boxes[0])
        }
//        self.classifierController = classifierController
        self.fillFields()
    }
    
    func fillFields() {
        if let expectedAttribute = box.expectedAttribute {
            self.expectedAttribute = expectedAttribute
        }
        if let expectedValue1 = box.expectedValue1 {
            self.expectedValue1 = expectedValue1
        }
        if let expectedValue1Unit = box.expectedValue1Unit {
            self.expectedValue1Unit = expectedValue1Unit
        }
        if let expectedValue2 = box.expectedValue2 {
            self.expectedValue2 = expectedValue2
        }
        if let expectedValue2Unit = box.expectedValue2Unit {
            self.expectedValue2Unit = expectedValue2Unit
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                recognizedTextsSection
                sectionForClassifierResult
    //            markSection
                expectedResultSection
            }
            .navigationTitle("Recognized Text")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard let image = ClassifierController.shared.pickedImage else { return }
                box.croppedImage(from: image, for: ClassifierController.shared.contentSize) {
                    self.boxImage = $0
                }
                DispatchQueue.main.async {
                    ClassifierController.shared.focus(on: box)
                }
                fillFields()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: dismissButton)
            .navigationBarItems(trailing: statusMenu)
            .toolbar { bottomToolbarContent }
            .onDisappear {
                ClassifierController.shared.resignBoxFocus()
            }
        }
    }
    
    func markAsValid() {
        box.status = .valid
        
        if let attribute = box.attribute {
            box.expectedAttribute = attribute
            expectedAttribute = attribute
        }
        if let value1 = box.value1 {
            box.expectedValue1 = value1.amount.clean
            box.expectedValue1Unit = value1.unit
            expectedValue1 = value1.amount.clean
            if let unit = value1.unit {
                expectedValue1Unit = unit
            }
        }
        if let value2 = box.value2 {
            box.expectedValue2 = value2.amount.clean
            box.expectedValue2Unit = value2.unit
            expectedValue2 = value2.amount.clean
            if let unit = value2.unit {
                expectedValue2Unit = unit
            }
        }

        Haptics.feedback(style: .rigid)
        refreshAndPop()
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                markAsValid()
            } label: {
                Image(systemName: ObservationStatus.valid.systemImage)
                    .disabled(box.status == .valid)
            }
            Spacer()
        }
    }
    
//    var markSection: some View {
//        Section {
//            Button {
//                box.status = .valid
//                Haptics.feedback(style: .rigid)
//                refreshAndPop()
//            } label: {
//                Label("Mark as Valid", systemImage: "checkmark")
//                    .foregroundColor(.green)
//            }
//            Button {
//                box.status = .irrelevant
//                Haptics.feedback(style: .heavy)
//                refreshAndPop()
//            } label: {
//                Label("Mark as Irrelevant", systemImage: "trash")
//                    .foregroundColor(.red)
//            }
//        }
//    }
    
    func refreshAndPop() {
        ClassifierController.shared.refreshBool.toggle()
        dismiss()
    }
    
    var expectedResultSection: some View {
        Section(header: Text("Expected Result"), footer: Text("Setting this will mark this as invalid")) {
            attributeField
            value1Field
            value2Field
        }
    }
    
    var attributeField: some View {
        Field(label: "Attribute",
              units: .constant(Attribute.allCases),
              selectedUnit: $expectedAttribute,
              selectorStyle: .prominent,
              contentProvider: self)
        { selection in
            //                guard let unit = selection as? VolumeTeaspoonUserUnit else { return }
            //                Store.setDefaultVolumeTeaspoonUnit(unit)
            //                Haptics.feedback(style: .medium)
        }
    }
    var value1Field: some View {
        Field(label: "Value 1",
              value: $expectedValue1,
              units: .constant(NutritionUnit.allCases),
              selectedUnit: $expectedValue1Unit,
              keyboardType: .decimalPad,
              selectorStyle: .prominent,
              contentProvider: self
        ) { selectedOption in
        }
    }
    
    var value2Field: some View {
        Field(label: "Value 2",
              value: $expectedValue2,
              units: .constant(NutritionUnit.allCases),
              selectedUnit: $expectedValue2Unit,
              keyboardType: .decimalPad,
              selectorStyle: .prominent,
              contentProvider: self
        ) { selectedOption in
        }
    }
    
    @ViewBuilder
    var statusMenu: some View {
        Image(systemName: box.status.systemImage)
            .foregroundColor(box.status.color)
            .id(ClassifierController.shared.refreshBool)
//        Menu {
//            ForEach(ObservationStatus.allCases.filter({ $0 != .unmarked }), id: \.self) { status in
//                Button {
//                    box.status = status
//                    if let index = classifierController.filteredBoxes.firstIndex(where: { $0.id == box.id }) {
//                        classifierController.filteredBoxes[index].status = status
//                    }
//                    classifierController.refreshBool.toggle()
//                } label: {
//                    Label(status.description, systemImage: status.systemImage)
//                }
//            }
//        } label: {
//            Image(systemName: box.status.systemImage)
//                .renderingMode(.original)
//        }
//        .id(classifierController.refreshBool)
    }
    
    var dismissButton: some View {
        Button(action : {
            dismiss()
        }){
            Image(systemName: "chevron.down")
        }
    }
    
    func dismiss() {
        ClassifierController.shared.resignBoxFocus()
        self.mode.wrappedValue.dismiss()
    }
    
    @ViewBuilder
    var recognizedTextsSection: some View {
        Section {
            if let image = boxImage {
                HStack {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                    Spacer()
                }
            }
            if let recognizedText = box.recognizedTextWithLC {
                HStack {
                    Text("With LC")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(recognizedText.string)
                }
            }
            if let recognizedText = box.recognizedTextWithoutLC {
                HStack {
                    Text("Without LC")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(recognizedText.string)
                }
            }
        }
    }
    
    @ViewBuilder
    var sectionForClassifierResult: some View {
        if box.hasClassifierResult {
            Section("Classifier Output") {
                if let attribute = box.attribute {
                    HStack {
                        Text("Attribute")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(attribute.description)
                    }
                }
                if let value1 = box.value1 {
                    HStack {
                        Text("Value 1")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value1.description)
                    }
                }
                if let value2 = box.value2 {
                    HStack {
                        Text("Value 2")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value2.description)
                    }
                }
            }
            relatedSection
        }
    }
    
    @ViewBuilder
    var relatedSection: some View {
        if box.hasRelatedFields {
            Section("Related Texts") {
                if let attribute = box.relatedAttribute {
                    HStack {
                        Text("Attribute")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(attribute.description)
                    }
                }
                if let value1 = box.relatedValue1 {
                    HStack {
                        Text("Value 1")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value1.description)
                    }
                }
                if let value2 = box.relatedValue2 {
                    HStack {
                        Text("Value 2")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value2.description)
                    }
                }
            }
        }
    }
}
