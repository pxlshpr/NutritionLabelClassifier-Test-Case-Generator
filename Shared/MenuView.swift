import SwiftUI

struct MenuView: View {
    
    var box: Binding<Box?>
    @ObservedObject var vm: ContentView.ViewModel
    @State var boxImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            Form {
                imageSection
                Section {
                    Button {
                        
                    } label: {
                        Label("Mark as Valid", systemImage: "app.badge.checkmark")
                            .foregroundColor(.green)
                    }
                }
                sectionForClassifierResult
                Section("Expected Result") {
                    Button {
                        
                    } label: {
                        Label("Choose Attribute", systemImage: "filemenu.and.selection")
                    }
                    Button {
                        
                    } label: {
                        Label("Enter Value for Column 1", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    Button {
                        
                    } label: {
                        Label("Enter Value for Column 2", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                }
                Section {
                    Button {
                        
                    } label: {
                        Label("Mark as Irrelevant", systemImage: "xmark.bin")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Box")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard let image = vm.pickedImage else { return }
                box.wrappedValue?.croppedImage(from: image, for: vm.contentSize) {
                    self.boxImage = $0
                }
            }
        }
    }
    
    @ViewBuilder
    var imageSection: some View {
        if let image = boxImage {
            Section {
                HStack {
                    Spacer()
                    Image(uiImage: image)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    var sectionForClassifierResult: some View {
        if box.wrappedValue?.hasClassifierResult == true {
            Section {
                if let attribute = box.wrappedValue?.attribute {
                    HStack {
                        Text("Attribute:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(attribute.rawValue)
                    }
                }
                if let value1 = box.wrappedValue?.value1 {
                    HStack {
                        Text("Value 1:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value1.description)
                    }
                }
                if let value2 = box.wrappedValue?.value2 {
                    HStack {
                        Text("Value 2:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value2.description)
                    }
                }
            }
        }
    }
}
