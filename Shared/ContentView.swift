import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier

struct ContentView: View {

    @StateObject var vm: ViewModel = ViewModel()
    @State var isPresentingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = vm.pickedImage {
                    GeometryReader { proxy in
                        ZoomableScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .overlay(content: {
                                    boxesLayer
                                })
                        }
                        .onAppear {
                            vm.contentSize = proxy.size
                        }
                    }
                } else {
                    Button("Choose Image") {
                        isPresentingImagePicker = true
                    }
                }
            }
            .navigationTitle("Test Case Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            imagePickerView
        }
        .onAppear {
            setImagePickerDelegate()
        }
    }
    
    @ViewBuilder
    var boxesLayer: some View {
        if let recognizedTexts = vm.recognizedTexts {
            ZStack(alignment: .topLeading) {
                ForEach(recognizedTexts, id: \.self) { recognizedText in
                    Button {
    //                    Haptics.feedback(style: .rigid)
    //                    lastTappedRecognizedText = recognizedText
    //                    let pasteBoard = UIPasteboard.general
    //                    pasteBoard.string = recognizedText.string
                    } label: {
                        recognizedTextView(for: recognizedText)
                    }
                    .offset(x: recognizedText.rect.minX, y: recognizedText.rect.minY)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    func color(for recognizedText: RecognizedText) -> some View {
        if let dataFrame = vm.nutrientsDataFrame, dataFrame.rows.contains(where: { row in
            guard let valueWithId = row["value1"] as? ValueWithId else {
                return false
            }
            return valueWithId.observationId == recognizedText.id
        }) {
            Color.green
        } else {
            Color.purple
        }
    }
    
    @ViewBuilder
    func recognizedTextView(for recognizedText: RecognizedText) -> some View {
        HStack {
            VStack(alignment: .leading) {
                color(for: recognizedText)
                    .cornerRadius(6.0)
                    .opacity(0.4)
                    .frame(width: recognizedText.rect.width, height: recognizedText.rect.height)
                Spacer()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var imagePickerView: some View {
        if let imagePickerDelegate = vm.imagePickerDelegate {
            ImagePickerView(filter: .any(of: [.images, .livePhotos]), selectionLimit: 1, delegate: imagePickerDelegate)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func setImagePickerDelegate() {
        vm.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $isPresentingImagePicker, didCancel: { (phPickerViewController) in
        }, didSelect: { (result) in
            guard let image = result.images.first else {
                fatalError("Couldn't get picked image")
            }
            vm.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }
}
