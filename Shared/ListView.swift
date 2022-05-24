import SwiftUI

struct ListView: View {
    
    @ObservedObject var vm: ContentView.ViewModel

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
                Text("Recognized Texts")
                    .disabled(true)
                Text("Classifier Output")
            } label: {
                HStack {
                    Text("Recognized Texts")
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
    
    var list: some View {
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
