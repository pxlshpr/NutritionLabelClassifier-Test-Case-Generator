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
        rawValue
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
    @ObservedObject var vm: ContentView.ViewModel
    @State var boxImage: UIImage? = nil
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var body: some View {
        Form {
            recognizedTextsSection
            sectionForClassifierResult
//            markSection
            expectedResultSection
        }
        .navigationTitle("Recognized Text")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let image = vm.pickedImage else { return }
            box.croppedImage(from: image, for: vm.contentSize) {
                self.boxImage = $0
            }
            vm.sendZoomNotification(for: box)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .navigationBarItems(trailing: statusMenu)
        .toolbar { bottomToolbarContent }
        
        //        .onDisappear {
        //            NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
        //        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                box.status = .valid
                Haptics.feedback(style: .rigid)
                refreshAndPop()
            } label: {
                Image(systemName: BoxStatus.valid.systemImage)
                    .foregroundColor(BoxStatus.valid.color)
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
        vm.refreshBool.toggle()
        popNavigationView()
    }
    
    @State var expectedAttribute: SelectionOption = Attribute.energy
    
    var expectedResultSection: some View {
        Section(header: Text("Expected Result"), footer: Text("Setting this will mark this as invalid")) {
            attributeField
            value1Field
            value2Field
        }
    }
    
    @State var expectedValue1: String = ""
    @State var expectedValue1Unit: SelectionOption = NutritionUnit.g
    @State var expectedValue2: String = ""
    @State var expectedValue2Unit: SelectionOption = NutritionUnit.g
    
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
            .id(vm.refreshBool)
//        Menu {
//            ForEach(BoxStatus.allCases.filter({ $0 != .unmarked }), id: \.self) { status in
//                Button {
//                    box.status = status
//                    if let index = vm.filteredBoxes.firstIndex(where: { $0.id == box.id }) {
//                        vm.filteredBoxes[index].status = status
//                    }
//                    vm.refreshBool.toggle()
//                } label: {
//                    Label(status.description, systemImage: status.systemImage)
//                }
//            }
//        } label: {
//            Image(systemName: box.status.systemImage)
//                .renderingMode(.original)
//        }
//        .id(vm.refreshBool)
    }
    
    var backButton: some View {
        Button(action : {
            popNavigationView()
        }){
            Image(systemName: "arrow.left")
        }
    }
    
    func popNavigationView() {
        NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
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
            Section("Classifier Result") {
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
        }
    }
}
