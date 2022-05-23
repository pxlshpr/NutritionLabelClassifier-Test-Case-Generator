import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics

struct ContentView: View {

    @StateObject var vm: ViewModel = ViewModel()
    @State var isPresentingImagePicker = false
    @State var selectedBox: Box? = nil
    
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
        .toolbar { bottomToolbarContent }
        .bottomSheet(item: $selectedBox,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            BoxDetailsView(box: $selectedBox, vm: vm)
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            imagePickerView
        }
        .onAppear {
            setImagePickerDelegate()
        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                vm.boxes = []
                vm.pickedImage = nil
                self.isPresentingImagePicker = true
            } label: {
                Image(systemName: "photo")
            }
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    @ViewBuilder
    var boxesLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(vm.boxes, id: \.self) { box in
                Button {
                    Haptics.feedback(style: .rigid)
                    selectedBox = box
                } label: {
                    boxView(for: box)
                }
                .offset(x: box.rect.minX, y: box.rect.minY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func boxView(for box: Box) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Group {
                    if let selectedBox = selectedBox {
                        if box == selectedBox {
                            Color.yellow
                        } else {
                            Color.white
                        }
                    } else {
                        box.color
                    }
                }
                    .cornerRadius(6.0)
                    .opacity(0.4)
                    .frame(width: box.rect.width, height: box.rect.height)
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
