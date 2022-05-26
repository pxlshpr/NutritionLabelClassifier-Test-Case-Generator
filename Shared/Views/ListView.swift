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
    
    @ObservedObject var contentVM: ContentView.ViewModel
    @State var listType: ListType = .output
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
            contentVM.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }

    
    var navigationTitleContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Menu {
                ForEach(ListType.allCases, id: \.self) { listType in
                    Button(listType.rawValue) {
                        self.listType = listType
                    }
                    .disabled(self.listType == listType)
                }
            } label: {
                HStack {
                    Text(listType.rawValue)
                    Image(systemName: "arrowtriangle.down.fill")
                        .scaleEffect(0.5)
                        .offset(x: -5, y: 0)
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
                if contentVM.filteredBoxes.contains(where: { $0.type == boxType }) {
                    Section("\(boxType.description)") {
                        ForEach(contentVM.filteredBoxes.indices, id: \.self) { index in
                            if contentVM.filteredBoxes[index].type == boxType {
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
        if let output = contentVM.classifierOutput {
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
        if let output = contentVM.classifierOutput {
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
            switch listType {
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
                BoxDetailsView(box: $contentVM.filteredBoxes[index], vm: contentVM)
            } label: {
                BoxCell(box: $contentVM.filteredBoxes[index])
                    .id(contentVM.refreshBool)
            }
//        }
    }
}

//MARK: - Toolbar

extension ListView {
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            choosePhotoButton
            filtersMenu
            Spacer()
            shareButton
        }
    }
    
    var choosePhotoButton: some View {
        Button {
            self.isPresentingImagePicker = true
        } label: {
            Image(systemName: "photo")
        }
    }

    var filtersMenu: some View {
        Menu {
            ForEach(BoxStatus.allCases, id: \.self) { status in
                if contentVM.boxes.contains(where: { $0.status == status }) {
                    Button {
                        if contentVM.statusFilter == status {
                            contentVM.statusFilter = nil
                        } else {
                            contentVM.statusFilter = status
                        }
                    } label: {
                        if contentVM.statusFilter == status {
                            Label(status.description, systemImage: "checkmark")
                        } else {
                            Text(status.description)
                        }
                    }
                }
            }
            Divider()
            ForEach(BoxType.allCases, id: \.self) { type in
                if contentVM.boxes.contains(where: { $0.type == type }) {
                    Button {
                        if contentVM.typeFilter == type {
                            contentVM.typeFilter = nil
                        } else {
                            contentVM.typeFilter = type
                        }
                    } label: {
                        if contentVM.typeFilter == type {
                            Label(type.description, systemImage: "checkmark")
                        } else {
                            Text(type.description)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle\(contentVM.statusFilter != nil || contentVM.typeFilter != nil ? ".fill" : "")")
        }
    }
    
    var shareButton: some View {
        Button {
            
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

}
