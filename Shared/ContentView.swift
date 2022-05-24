import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics
import SwiftHaptics

struct ContentView: View {

    @StateObject var vm: ViewModel = ViewModel()
    @State var isPresentingImagePicker = false
    @State var isPresentingList: Bool = false
    @State var shrinkImageView: Bool = false

    @State var isHidingBoxes: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = vm.pickedImage {
                    zoomableScrollView(with: image)
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
        .bottomSheet(isPresented: $isPresentingList,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            ListView(vm: vm)
        }
        .bottomSheet(item: $vm.selectedBox,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let box = vm.selectedBox, let index = vm.boxes.firstIndex(where: { $0.id == box.id }) {
                NavigationView {
                    BoxDetailsView(box: $vm.boxes[index], vm: vm)
                }
            }
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            imagePickerView
        }
        .onAppear {
            setImagePickerDelegate()
        }
    }
    
    func imageView(with image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .overlay(content: {
                if !isHidingBoxes {
                    boxesLayer
                        .transition(.opacity)
                }
            })
    }
    
    func zoomableScrollView(with image: UIImage) -> some View {
        GeometryReader { proxy in
            ZoomableScrollView {
                imageView(with: image)
            }
            .onAppear {
                vm.contentSize = proxy.size
            }
            .frame(maxHeight: shrinkImageView ? proxy.size.height / 2.0 : proxy.size.height)
            .onChange(of: vm.selectedBox) { newValue in
                updateSize(for: proxy.size, reduceSize: newValue != nil)
            }
            .onChange(of: isPresentingList) { newValue in
                updateSize(for: proxy.size, reduceSize: isPresentingList)
            }
        }
    }
    
    func updateSize(for size: CGSize, reduceSize: Bool) {
        guard let image = vm.pickedImage else { return }
        
        isHidingBoxes = true
        NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
        
        var contentSize = size
        if reduceSize {
            contentSize.height = size.height / 2.0
        }
        vm.contentSize = contentSize
        vm.recalculateBoxes(for: image)
        
        withAnimation {
            shrinkImageView = reduceSize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isHidingBoxes = false
            }
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
            if vm.pickedImage != nil {
                Button {
                    isPresentingList = true
                } label: {
                    Image(systemName: isPresentingList ? "list.bullet.circle.fill" : "list.bullet.circle")
                }
            }
            Spacer()
            if vm.pickedImage != nil {
                Button {
                    
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    @ViewBuilder
    var boxesLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(vm.filteredBoxes, id: \.self) { box in
                Button {
                    Haptics.feedback(style: .rigid)
//                    vm.selectedBox = box
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                        vm.sendZoomNotification(for: box)
//                    }
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
                    if let selectedBox = vm.selectedBox {
                        if box.id == selectedBox.id {
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
