import SwiftUI
import SwiftUISugar
import NutritionLabelClassifier
import Introspect

enum ListType: String, CaseIterable {
    case output = "Classifier Output"
    case expectations = "Expectations"
    case texts = "Recognized Texts"
}

class ListViewModel: ObservableObject {
    @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil
}

extension ListView {
    func attributeView(for attribute: Attribute) -> some View {
        AttributeView(attribute: attribute)
    }
}

struct ListView: View {
    
    @ObservedObject var classifierController: ClassifierController
    @State var isPresentingImagePicker = false
    
    @State var attributeBeingPresented: Attribute? = nil
    @State var boxIdBeingPresented: UUID? = nil
    
    @StateObject var listViewModel = ListViewModel()
    
    @State var newAttribute: Attribute? = nil
    
    var body: some View {
        NavigationView {
            list
                .toolbar { navigationTitleContent }
//                .navigationTitle("Recognized Texts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { bottomToolbarContent }
                .sheet(isPresented: $isPresentingImagePicker) {
                    imagePickerView
                }
        }
        .sheet(isPresented: $classifierController.isPresentingFilePickerForExistingFile) {
            DocumentPicker(delegate: classifierController)
                .accentColor(Color.accentColor)
        }
        .sheet(isPresented: $classifierController.isPresentingFilePickerForCreatedFile, onDismiss: {
//            Store.cleanBackupFiles()
        }) {
            DocumentPicker(url: classifierController.testDataZipFileUrl, exportAsCopy: true)
                .accentColor(Color.accentColor)
        }
        .onAppear {
            setImagePickerDelegate()
        }
        .bottomSheet(item: $attributeBeingPresented,
                     largestUndimmedDetentIdentifier: .medium,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let attribute = attributeBeingPresented {
                attributeView(for: attribute)
            }
        }
        .bottomSheet(item: $newAttribute,
                     largestUndimmedDetentIdentifier: .medium,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let attribute = newAttribute {
                AttributeForm(attribute: attribute)
            }
        }
        .bottomSheet(item: $boxIdBeingPresented,
                     largestUndimmedDetentIdentifier: .medium,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let boxId = boxIdBeingPresented {
                BoxDetailsView(boxId: boxId)
            }
        }
    }
    
    func setImagePickerDelegate() {
        listViewModel.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $isPresentingImagePicker, didCancel: { (phPickerViewController) in
            print("didCancel")
        }, didSelect: { (result) in
            guard let image = result.images.first else {
                fatalError("Couldn't get picked image")
            }
            classifierController.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }
    
    var navigationTitleContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            HStack {
                listTypeSegmentedButton
//                listTypeMenu
                Spacer()
//                if classifierController.listTypeBeingPresented == .texts {
//                    Text(classifierController.filtersDescription)
//                        .font(.footnote)
//                }
                Menu {
                    Button {
                        classifierController.validateAll()
                    } label: {
                        Label("Validate All", systemImage: "checkmark")
                    }
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("Invalidate All", systemImage: "xmark")
                    }
                } label: {
                    Image(systemName: "\(classifierController.status.systemImage).square")
                        .foregroundColor(classifierController.status.color)
                }
                .opacity(classifierController.listTypeBeingPresented == .output ? 1.0 : 0.0)
            }
        }
    }
    
    var listTypeSegmentedButton: some View {
        Picker("", selection: $classifierController.listTypeBeingPresented) {
            Text("Output").tag(ListType.output)
            Text("Expectations").tag(ListType.expectations)
            Text("Texts").tag(ListType.texts)
        }
        .pickerStyle(.segmented)
//        .scaledToFit()
        .labelsHidden()
    }
    
    var listTypeMenu: some View {
        Menu {
            ForEach(ListType.allCases, id: \.self) { listType in
                Button(listType.rawValue) {
                    classifierController.listTypeBeingPresented = listType
                }
                .disabled(classifierController.listTypeBeingPresented == listType)
            }
        } label: {
            HStack {
                Text(classifierController.listTypeBeingPresented.rawValue)
                Image(systemName: "arrowtriangle.down.fill")
                    .scaleEffect(0.5)
                    .offset(x: -5, y: 0)
            }
        }
    }

    @ViewBuilder
    var imagePickerView: some View {
        if let imagePickerDelegate = listViewModel.imagePickerDelegate {
            ImagePickerView(filter: .any(of: [.images, .livePhotos]), selectionLimit: 1, delegate: imagePickerDelegate)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    var recognizedTextsList: some View {
        List {
            ForEach(BoxType.allCases, id: \.self) { boxType in
                if classifierController.filteredBoxes.contains(where: { $0.type == boxType }) {
                    Section("\(boxType.description)") {
                        ForEach(classifierController.filteredBoxes.indices, id: \.self) { index in
                            if classifierController.filteredBoxes[index].type == boxType {
                                cell(for: index)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    var classifierOutputList: some View {
        List {
            servingSection
            columnHeadersSection
            nutrientsSection
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    var servingSection: some View {
        if let output = classifierController.classifierOutput, output.containsServingAttributes {
            Section("Serving") {
                servingAmountField(from: output)
                servingsPerContainerAmount(from: output)
            }
        }
    }
    
    @ViewBuilder
    func servingAmountField(from output: Output) -> some View {
        if let amount = output.serving?.amount {
            cell(attribute: .servingAmount, value: amount.clean)
        }
    }
    
    @ViewBuilder
    func servingsPerContainerAmount(from output: Output) -> some View {
        if let amount = output.serving?.perContainer?.amount {
            cell(attribute: .servingsPerContainerAmount, value: amount.clean)
        }
    }

    func cell(attribute: Attribute, value: String) -> some View {
        Button {
            attributeBeingPresented = attribute
        } label: {
            HStack {
                Text(attribute.description)
                Spacer()
                Text(value)
                Image(systemName: "\(classifierController.outputAttributeStatuses[attribute]?.systemImage ?? "questionmark").square")
                    .foregroundColor(classifierController.outputAttributeStatuses[attribute]?.color ?? .orange)
            }
        }
        .buttonStyle(BorderlessButtonStyle())

    }
    
    @ViewBuilder
    var columnHeadersSection: some View {
        if classifierController.hasAnyColumnHeaders {
            Section("Column Headers") {
            }
        }
    }

    @ViewBuilder
    var nutrientsSection: some View {
        if let output = classifierController.classifierOutput {
            Section("Nutrients") {
                ForEach(output.nutrients.rows, id: \.attribute) { row in
                    cell(for: row)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    func cell(for row: Output.Nutrients.Row) -> some View {
        Button {
            attributeBeingPresented = row.attribute
            focusOn(row)
        } label: {
            HStack {
                Text(row.attributeText.attribute.description)
                Spacer()
                if let identifiableValue1 = row.valueText1 {
                    Text(identifiableValue1.value.description)
                }
                if let identifiableValue2 = row.valueText2 {
                    Text("•")
                    Text(identifiableValue2.value.description)
                }
                Image(systemName: "\(classifierController.outputAttributeStatuses[row.attribute]?.systemImage ?? "questionmark").square")
                    .foregroundColor(classifierController.outputAttributeStatuses[row.attribute]?.color ?? .orange)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    func cell_legacy(for row: Output.Nutrients.Row) -> some View {
        HStack {
            Button(row.attributeText.attribute.description) {
                boxIdBeingPresented = row.attributeText.textId
            }
            .padding(5)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5)
            .buttonStyle(BorderlessButtonStyle())
            Spacer()
            if let identifiableValue1 = row.valueText1 {
                Button(identifiableValue1.value.description) {
                    boxIdBeingPresented = row.valueText1?.textId
                }
                .padding(5)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)
                .buttonStyle(BorderlessButtonStyle())
            }
            if let identifiableValue2 = row.valueText2 {
                Button(identifiableValue2.value.description) {
                    boxIdBeingPresented = row.valueText2?.textId
                }
                .padding(5)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)
                .buttonStyle(BorderlessButtonStyle())
            }
            Menu {
                Button {
                } label: {
                    Label("Validate", systemImage: "checkmark")
                }
                Button(role: .destructive) {
                } label: {
                    Label("Invalidate", systemImage: "xmark")
                }
            } label: {
                Image(systemName: "\(BoxStatus.unmarked.systemImage).square")
                    .foregroundColor(BoxStatus.unmarked.color)
                    .contentShape(Rectangle())
                    .onTapGesture {
//                    .simultaneousGesture(TapGesture().onEnded {
                        toggleFocusOnRow(row)
                    }
            }
//            .contentShape(Rectangle())
//            .simultaneousGesture(TapGesture().onEnded {
//                toggleFocusOnRow(row)
//            })
            .padding(5)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5)
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    func focusOn(_ row: Output.Nutrients.Row) {
        guard let box = row.box else { return }
        classifierController.focus(on: box)
    }

    func toggleFocusOnRow(_ row: Output.Nutrients.Row) {
        /// Get the box for the `Output.Nutrients.Row`, which returns the box for its `Attribute`
        guard let box = row.box else { return }
        
        if classifierController.focusedBox != nil {
            classifierController.resignBoxFocus()
        } else {
            classifierController.focus(on: box)
        }
    }

    var list: some View {
        Group {
            switch classifierController.listTypeBeingPresented {
            case .texts:
                recognizedTextsList
            case .expectations:
                expectationsList
            case .output:
                classifierOutputList
            }
        }
    }
    
    @ViewBuilder
    func cell(for index: Int) -> some View {
//        if let index = vm.filteredBoxes.firstIndex(where: { $0.id == box.id }) {
        Button {
            boxIdBeingPresented = classifierController.filteredBoxes[index].id
        } label: {
            BoxCell(box: $classifierController.filteredBoxes[index])
                .id(classifierController.refreshBool)
        }
//            NavigationLink {
//                BoxDetailsView(
//                    box: $classifierController.filteredBoxes[index],
//                    classifierController: classifierController)
//            } label: {
//                BoxCell(box: $classifierController.filteredBoxes[index])
//                    .id(classifierController.refreshBool)
//            }
//        }
    }
}

//MARK: - Toolbar

extension ListView {
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            classifierController.listButton
            if classifierController.listTypeBeingPresented == .texts {
                classifierController.filtersMenu
            }
            Spacer()
            choosePhotoButton
            classifierController.shareButton
            classifierController.saveButton
        }
    }
    
    var choosePhotoButton: some View {
        Button {
            self.isPresentingImagePicker = true
        } label: {
            Image(systemName: "photo.fill")
        }
    }    
}

extension ClassifierController {
    
    @ViewBuilder
    var filtersMenu: some View {
        if pickedImage != nil {
            Menu {
                ForEach(BoxStatus.allCases, id: \.self) { status in
                    if self.boxes.contains(where: { $0.status == status }) {
                        Button {
                            self.statusFilter = status
                        } label: {
                            if self.statusFilter == status {
                                Label(status.description, systemImage: "checkmark")
                            } else {
                                Text(status.description)
                            }
                        }
                        .disabled(self.statusFilter == status)
                    }
                }
                Button {
                    self.statusFilter = nil
                } label: {
                    if self.statusFilter == nil {
                        Label("All Statuses", systemImage: "checkmark")
                    } else {
                        Text("All Statuses")
                    }
                }
                .disabled(self.statusFilter == nil)
                Divider()
                ForEach(BoxType.allCases, id: \.self) { type in
                    if self.boxes.contains(where: { $0.type == type }) {
                        Button {
                            self.typeFilter = type
                        } label: {
                            if self.typeFilter == type {
                                Label(type.description, systemImage: "checkmark")
                            } else {
                                Text(type.description)
                            }
                        }
                        .disabled(self.typeFilter == type)
                    }
                }
                Button {
                    self.typeFilter = nil
                } label: {
                    if self.typeFilter == nil {
                        Label("All Types", systemImage: "checkmark")
                    } else {
                        Text("All Types")
                    }
                }
                .disabled(self.typeFilter == nil)
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle\(statusFilter != nil || typeFilter != nil ? ".fill" : "")")
            }
        }
    }
    
    @ViewBuilder
    var listButton: some View {
        if pickedImage != nil {
            Button {
                self.isPresentingList.toggle()
            } label: {
                Image(systemName: isPresentingList ? "list.bullet.circle.fill" : "list.bullet.circle")
            }
        }
    }
    
    @ViewBuilder
    var saveButton: some View {
        if pickedImage != nil {
            Menu {
                Button {
                    ClassifierController.shared.isPresentingFilePickerForExistingFile = true
                } label: {
                    Label("Save to Existing File", systemImage: "doc.badge.plus")
                }
                Button {
                    self.createNewTestCaseFile()
                } label: {
                    Label("Save Test Case", systemImage: "plus.app")
                }
            } label: {
                Image(systemName: "square.and.arrow.down\(status == .valid ? ".fill" : "")")
            }
        }
    }

    @ViewBuilder
    var shareButton: some View {
        if ClassifierController.shared.testDataFileExists {
            Button {
                self.shareZipFile()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

extension Output.Nutrients.Row {
    var box: Box? {
        ClassifierController.shared.boxes.first(where: { $0.id == attributeId })
    }
}
