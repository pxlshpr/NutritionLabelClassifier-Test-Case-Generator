import SwiftUI
import SwiftUISugar

enum ListType: String, CaseIterable {
    case output = "Classifier Output"
    case texts = "Recognized Texts"
}

class ListViewModel: ObservableObject {
    @Published var imagePickerDelegate: ImagePickerView.Delegate? = nil
}

struct ListView: View {
    
    @ObservedObject var imageController: ImageController
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
    }
    
    func setImagePickerDelegate() {
        listViewModel.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $isPresentingImagePicker, didCancel: { (phPickerViewController) in
            print("didCancel")
        }, didSelect: { (result) in
            guard let image = result.images.first else {
                fatalError("Couldn't get picked image")
            }
            imageController.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }

    
    var navigationTitleContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            HStack {
                Menu {
                    ForEach(ListType.allCases, id: \.self) { listType in
                        Button(listType.rawValue) {
                            imageController.listTypeBeingPresented = listType
                        }
                        .disabled(imageController.listTypeBeingPresented == listType)
                    }
                } label: {
                    HStack {
                        Text(imageController.listTypeBeingPresented.rawValue)
                        Image(systemName: "arrowtriangle.down.fill")
                            .scaleEffect(0.5)
                            .offset(x: -5, y: 0)
                    }
                }
                Spacer()
                if imageController.listTypeBeingPresented == .texts {
                    Text(imageController.filtersDescription)
                        .font(.footnote)
                }
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
                if imageController.filteredBoxes.contains(where: { $0.type == boxType }) {
                    Section("\(boxType.description)") {
                        ForEach(imageController.filteredBoxes.indices, id: \.self) { index in
                            if imageController.filteredBoxes[index].type == boxType {
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
        if let output = imageController.classifierOutput {
            Section("Serving") {
                if let servingsPerContainer = output.serving?.perContainer {
                    HStack {
                        if let name = servingsPerContainer.nameWithId {
                            Button {
                                
                            } label: {
                                Text("Servings per \(name.containerName.rawValue)")
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
                        Button(servingsPerContainer.valueWithId.double.clean) {
                            
                        }
                        .padding(5)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    var nutrientsSection: some View {
        if let output = imageController.classifierOutput {
            Section("Nutrients") {
                ForEach(output.nutrients.rows, id: \.attributeWithId.id) { row in
                    HStack {
                        Button(row.attributeWithId.attribute.description) {
                            
                        }
                        .padding(5)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                        if let value1WithId = row.value1WithId {
                            Button(value1WithId.value.description) {
                                
                            }
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(5)
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        if let value2WithId = row.value2WithId {
                            Button(value2WithId.value.description) {
                                
                            }
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(5)
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
        }
    }

    var list: some View {
        Group {
            switch imageController.listTypeBeingPresented {
            case .texts:
                recognizedTextsList
            case .output:
                classifierOutputList
            }
        }
    }
    
    @ViewBuilder
    func cell(for index: Int) -> some View {
//        if let index = vm.filteredBoxes.firstIndex(where: { $0.id == box.id }) {
            NavigationLink {
                BoxDetailsView(
                    box: $imageController.filteredBoxes[index],
                    imageController: imageController)
            } label: {
                BoxCell(box: $imageController.filteredBoxes[index])
                    .id(imageController.refreshBool)
            }
//        }
    }
}

//MARK: - Toolbar

extension ListView {
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            imageController.listButton
            if imageController.listTypeBeingPresented == .texts {
                imageController.filtersMenu
            }
            Spacer()
            choosePhotoButton
            imageController.shareButton
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

extension ImageController {
    
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
