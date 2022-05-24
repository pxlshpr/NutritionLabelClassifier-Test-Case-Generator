import SwiftUI
import SwiftUISugar
import NutritionLabelClassifier

extension Attribute: SelectionOption {
    public var optionId: String {
        rawValue
    }
}

extension BoxDetailsView: FieldContentProvider {
    func menuTitle(for option: SelectionOption, isPlural: Bool) -> String? {
        option.optionId
    }
    
    func title(for option: SelectionOption, isPlural: Bool) -> String? {
        option.optionId
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
            markSection
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

//        .onDisappear {
//            NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
//        }
    }

    @State var refreshBool = false
    
    var markSection: some View {
        Section {
            Button {
                box.status = .valid
                refreshBool.toggle()
            } label: {
                Label("Mark as Valid", systemImage: "checkmark")
                    .foregroundColor(.green)
            }
            
            Button {
                
            } label: {
                Label("Mark as Irrelevant", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    @State var expectedAttribute: SelectionOption = Attribute.energy
    
    var expectedResultSection: some View {
        Section("Mark as Invalid (Specify expected result)") {
            Field(label: "Attribute",
                  units: .constant(Attribute.allCases),
                  selectedUnit: $expectedAttribute,
                  contentProvider: self)
            { selection in
//                guard let unit = selection as? VolumeTeaspoonUserUnit else { return }
//                Store.setDefaultVolumeTeaspoonUnit(unit)
//                Haptics.feedback(style: .medium)
            }
            Button {
                
            } label: {
                Label("Value 1", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
            Button {
                
            } label: {
                Label("Value 2", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
        }
    }
    
    @ViewBuilder
    var statusMenu: some View {
        Menu {
            ForEach(BoxStatus.allCases.filter({ $0 != .unmarked }), id: \.self) { status in
                Button {
                    box.status = status
                    if let index = vm.filteredBoxes.firstIndex(where: { $0.id == box.id }) {
                        vm.filteredBoxes[index].status = status
                    }
                    refreshBool.toggle()
                } label: {
                    Label(status.description, systemImage: status.systemImage)
                }
            }
        } label: {
            Image(systemName: box.status.systemImage)
                .renderingMode(.original)
        }
        .id(refreshBool)
    }
    
    var backButton: some View {
        Button(action : {
            NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
            self.mode.wrappedValue.dismiss()
        }){
            Image(systemName: "arrow.left")
        }
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
                        Text("Attribute:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(attribute.rawValue)
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
