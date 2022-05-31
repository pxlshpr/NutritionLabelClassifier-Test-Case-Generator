import SwiftUI
import SwiftUISugar
import NutritionLabelClassifier
import Introspect

enum ListType: String, CaseIterable {
    case observations = "Observations"
    case expectations = "Expectations"
    case texts = "Recognized Texts"
}

class ListViewModel: ObservableObject {
    @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil
}

struct ListView: View {
    
    @ObservedObject var classifierController: ClassifierController
    @State var isPresentingImagePicker = false
    
    @State var observationBeingPresented: Observation? = nil
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
        .bottomSheet(item: $observationBeingPresented,
                     largestUndimmedDetentIdentifier: .medium,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let observation = observationBeingPresented {
                ObservationView(observation: observation)
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
                Spacer()
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
                .opacity(classifierController.listTypeBeingPresented == .observations ? 1.0 : 0.0)
            }
        }
    }
    
    var listTypeSegmentedButton: some View {
        Picker("", selection: $classifierController.listTypeBeingPresented) {
            Text("Output").tag(ListType.observations)
            Text("Expectations").tag(ListType.expectations)
            Text("Texts").tag(ListType.texts)
        }
        .pickerStyle(.segmented)
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
    
    //MARK: - Lists
    
    var list: some View {
        Group {
            switch classifierController.listTypeBeingPresented {
            case .texts:
                recognizedTextsList
            case .expectations:
                expectationsList
            case .observations:
                observationsList
            }
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
    
    var expectationsList: some View {
        List {
            servingExpectationsSection
            headerExpectationsSection
            nutrientExpectationsSection
        }
        .listStyle(.plain)
    }

    var observationsList: some View {
        List {
            servingSection
            headersSection
            nutrientsSection
        }
        .listStyle(.plain)
    }
    
    //MARK: - Sections
    
    @ViewBuilder
    var servingSection: some View {
        if classifierController.containsServingObservations {
            Section("Serving") {
                cell(for: .servingAmount)
                cell(for: .servingUnit)
                cell(for: .servingUnitSize)
                cell(for: .servingEquivalentAmount)
                cell(for: .servingEquivalentUnit)
                cell(for: .servingEquivalentUnitSize)
                cell(for: .servingsPerContainerAmount)
                cell(for: .servingsPerContainerName)
            }
        }
    }
    
    @ViewBuilder
    var headersSection: some View {
        if classifierController.containsHeaderObservations {
            Section("Column Headers") {
                cell(for: .headerType1)
                cell(for: .headerType2)
                cell(for: .headerServingAmount)
                cell(for: .headerServingUnit)
                cell(for: .headerServingUnitSize)
                cell(for: .headerServingEquivalentAmount)
                cell(for: .headerServingEquivalentUnit)
                cell(for: .headerServingEquivalentUnitSize)
            }
        }
    }

    @ViewBuilder
    var nutrientsSection: some View {
        if classifierController.containsNutrientObservations {
            Section("Nutrients") {
                ForEach(classifierController.nutrientObservations, id: \.attribute) { observation in
                    cell(for: observation)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    //MARK: - Cell
    @ViewBuilder
    func cell(for attribute: Attribute) -> some View {
        if let observation = classifierController.observation(for: attribute) {
            cell(for: observation)
        }
    }
    
    func cell(for observation: Observation) -> some View {
        Button {
            observationBeingPresented = observation
            classifierController.focus(on: observation)
        } label: {
            HStack {
                Text(observation.attribute.description)
                Spacer()
                detail(for: observation)
                Image(systemName: "\(observation.status.systemImage).square")
                    .foregroundColor(observation.status.color)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    func detail(for observation: Observation) -> some View {
        Group {
            if observation.attribute.isNutrientAttribute {
                if let value = observation.value1 {
                    Text(value.description)
                }
                if let value = observation.value2 {
                    Text("•")
                    Text(value.description)
                }
            }
            else if let double = observation.double {
                Text(double.clean)
            }
            else if let string = observation.string {
                Text(string)
            }
            else if let unit = observation.unit {
                Text(unit.description)
            }
            else if let headerType = observation.headerType {
                Text(headerType.description)
            }
            else {
                Text("Unknown Type")
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
                ForEach(ObservationStatus.allCases, id: \.self) { status in
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
