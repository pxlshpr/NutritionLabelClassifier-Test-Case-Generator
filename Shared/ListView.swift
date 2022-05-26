import SwiftUI

enum ListType: String, CaseIterable {
    case texts = "Recognized Texts"
    case output = "Classifier Output"
}
struct ListView: View {
    
    @ObservedObject var vm: ContentView.ViewModel
    @State var listType: ListType = .texts
    
    var body: some View {
        NavigationView {
            list
                .toolbar { navigationTitleContent }
//                .navigationTitle("Recognized Texts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { bottomToolbarContent }
        }
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

    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            filtersMenu
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    var filtersMenu: some View {
        Menu {
            ForEach(BoxStatus.allCases, id: \.self) { status in
                if vm.boxes.contains(where: { $0.status == status }) {
                    Button {
                        if vm.statusFilter == status {
                            vm.statusFilter = nil
                        } else {
                            vm.statusFilter = status
                        }
                    } label: {
                        if vm.statusFilter == status {
                            Label(status.description, systemImage: "checkmark")
                        } else {
                            Text(status.description)
                        }
                    }
                }
            }
            Divider()
            ForEach(BoxType.allCases, id: \.self) { type in
                if vm.boxes.contains(where: { $0.type == type }) {
                    Button {
                        if vm.typeFilter == type {
                            vm.typeFilter = nil
                        } else {
                            vm.typeFilter = type
                        }
                    } label: {
                        if vm.typeFilter == type {
                            Label(type.description, systemImage: "checkmark")
                        } else {
                            Text(type.description)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle\(vm.statusFilter != nil || vm.typeFilter != nil ? ".fill" : "")")
        }
    }
    
    var recognizedTextsList: some View {
        List {
            ForEach(BoxType.allCases, id: \.self) { boxType in
                if vm.filteredBoxes.contains(where: { $0.type == boxType }) {
                    Section("\(boxType.description)") {
                        ForEach(vm.filteredBoxes.indices, id: \.self) { index in
                            if vm.filteredBoxes[index].type == boxType {
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
        if let output = vm.classifierOutput {
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
        if let output = vm.classifierOutput {
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
                BoxDetailsView(box: $vm.filteredBoxes[index], vm: vm)
            } label: {
                BoxCell(box: $vm.filteredBoxes[index])
                    .id(vm.refreshBool)
            }
//        }
    }
}

struct BoxCell: View {
    @Binding var box: Box
    
    var body: some View {
        HStack {
            Text(box.cellTitle)
            Spacer()
            Image(systemName: "\(box.status.systemImage).square")
                .foregroundColor(box.status.color)
//                .renderingMode(.original)
        }
    }
}
