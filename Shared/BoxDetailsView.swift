import SwiftUI

struct BoxDetailsView: View {
    
    var box: Binding<Box?>
    @ObservedObject var vm: ContentView.ViewModel
    @State var boxImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            Form {
                recognizedTextsSection
                Section {
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
                        Label("Mark as Valid", systemImage: "app.badge.checkmark")
                            .foregroundColor(.green)
                    }
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
    var recognizedTextsSection: some View {
        Section("Recognized Text") {
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
            if let recognizedText = box.wrappedValue?.recognizedTextWithLC {
                HStack {
                    Text("With LC")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(recognizedText.string)
                }
            }
            if let recognizedText = box.wrappedValue?.recognizedTextWithoutLC {
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
        if box.wrappedValue?.hasClassifierResult == true {
            Section("Classifier Output") {
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
                        Text("Value 1")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value1.description)
                    }
                }
                if let value2 = box.wrappedValue?.value2 {
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
