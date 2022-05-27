import SwiftUI
import SwiftUISugar
import NutritionLabelClassifier

enum ListType: String, CaseIterable {
    case output = "Classifier Output"
    case texts = "Recognized Texts"
}

class ListViewModel: ObservableObject {
    @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil
}

struct ListView: View {
    
    @ObservedObject var classifierController: ClassifierController
    @State var isPresentingImagePicker = false
    
    @StateObject var listViewModel = ListViewModel()
    
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
        .onAppear {
            setImagePickerDelegate()
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
                if classifierController.listTypeBeingPresented == .texts {
                    Text(classifierController.filtersDescription)
                        .font(.footnote)
                }
                if classifierController.listTypeBeingPresented == .output {
                    Menu {
                        Button {
                            
                        } label: {
                            Label("Validate All", systemImage: "checkmark")
                        }
                        Button(role: .destructive) {
                            
                        } label: {
                            Label("Invalidate All", systemImage: "xmark")
                        }
                    } label: {
                        Image(systemName: "\(BoxStatus.unmarked.systemImage).square")
                            .foregroundColor(BoxStatus.unmarked.color)
                    }
                }
            }
        }
    }
    
    var listTypeSegmentedButton: some View {
        Picker("", selection: $classifierController.listTypeBeingPresented) {
            Text("Output").tag(ListType.output)
            Text("Texts").tag(ListType.texts)
        }
        .pickerStyle(.segmented)
        .scaledToFit()
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
            nutrientsSection
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    var servingSection: some View {
        if let output = classifierController.classifierOutput {
            Section("Serving") {
                if let servingsPerContainer = output.serving?.perContainer {
                    HStack {
                        if let identifiableName = servingsPerContainer.identifiableName {
                            Button {
                                
                            } label: {
                                Text("Servings per \(identifiableName.string)")
                                    .padding(3)
                                    .background(Color(.secondarySystemBackground))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
                            Button {
                            } label: {
                                Text("Servings per container")
                                    .padding(5)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(5)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        Spacer()
                        Button(servingsPerContainer.identifiableAmount.double.clean) {
                            
                        }
                        .padding(5)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                Button {
                } label: {
                    Label("Add Serving Attribute", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }

    @ViewBuilder
    var nutrientsSection: some View {
        if let output = classifierController.classifierOutput {
            Section("Nutrients") {
                ForEach(output.nutrients.rows, id: \.attributeId) { row in
                    cell(for: row)
                }
                Button {
                } label: {
                    Label("Add Nutrient", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    func cell(for row: Output.Nutrients.Row) -> some View {
        HStack {
            Button(row.identifiableAttribute.attribute.description) {
                boxIdBeingPresented = row.identifiableAttribute.id
            }
            .padding(5)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5)
            .buttonStyle(BorderlessButtonStyle())
            Spacer()
            if let identifiableValue1 = row.identifiableValue1 {
                Button(identifiableValue1.value.description) {
                    boxIdBeingPresented = row.identifiableValue1?.id
                }
                .padding(5)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)
                .buttonStyle(BorderlessButtonStyle())
            }
            if let identifiableValue2 = row.identifiableValue2 {
                Button(identifiableValue2.value.description) {
                    boxIdBeingPresented = row.identifiableValue2?.id
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
            }
            .padding(5)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5)
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    var list: some View {
        Group {
            switch classifierController.listTypeBeingPresented {
            case .texts:
                recognizedTextsList
            case .output:
                classifierOutputList
            }
        }
    }
    
    @State var boxIdBeingPresented: UUID? = nil
    
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
        }
    }
    
    var choosePhotoButton: some View {
        Button {
            self.isPresentingImagePicker = true
        } label: {
            Image(systemName: "photo.fill")
        }
    }
    
    var shareButton: some View {
        Button {
            
        } label: {
            Image(systemName: "square.and.arrow.up")
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
    var shareButton: some View {
        if pickedImage != nil {
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

}