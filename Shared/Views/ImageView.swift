import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics
import SwiftHaptics

struct ImageView: View {

    @StateObject var imageController = ImageController()
//    @State var isPresentingImagePicker = false
//    @State var isPresentingList: Bool = false
    @State var shrinkImageView: Bool = false

    @State var isHidingBoxes: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = imageController.pickedImage {
                    zoomableScrollView(with: image)
                } else {
                    Button("Choose Image") {
                        imageController.isPresentingImagePicker = true
                    }
                }
            }
            .navigationTitle("Test Case Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar { bottomToolbarContent }
        .bottomSheet(isPresented: $imageController.isPresentingList,
                     largestUndimmedDetentIdentifier: .medium,
//                     detents: [.large()],
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            ListView(imageController: imageController)
        }
        .bottomSheet(item: $imageController.selectedBox,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let box = imageController.selectedBox, let index = imageController.boxes.firstIndex(where: { $0.id == box.id }) {
                NavigationView {
                    BoxDetailsView(box: $imageController.boxes[index], imageController: imageController)
                }
            }
        }
        .sheet(isPresented: $imageController.isPresentingImagePicker) {
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
                imageController.contentSize = proxy.size
            }
            .frame(maxHeight: shrinkImageView ? proxy.size.height / 2.0 : proxy.size.height)
            .onChange(of: imageController.selectedBox) { newValue in
                updateSize(for: proxy.size, reduceSize: newValue != nil)
            }
            .onChange(of: imageController.isPresentingList) { newValue in
                updateSize(for: proxy.size, reduceSize: imageController.isPresentingList)
            }
        }
    }
    
    func updateSize(for size: CGSize, reduceSize: Bool) {
        guard let image = imageController.pickedImage else { return }
        
        isHidingBoxes = true
        NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
        
        var contentSize = size
        if reduceSize {
            contentSize.height = size.height / 2.0
        }
        imageController.contentSize = contentSize
        imageController.recalculateBoxes(for: image)
        
        withAnimation {
            shrinkImageView = reduceSize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isHidingBoxes = false
            }
        }
    }
    
    @ViewBuilder
    var boxesLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(imageController.filteredBoxes, id: \.self) { box in
                Button {
                    Haptics.feedback(style: .rigid)
//                    imageController.selectedBox = box
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                        imageController.sendZoomNotification(for: box)
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
                    if let selectedBox = imageController.selectedBox {
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
        if let imagePickerDelegate = imageController.imagePickerDelegate {
            ImagePickerView(filter: .any(of: [.images, .livePhotos]), selectionLimit: 1, delegate: imagePickerDelegate)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func setImagePickerDelegate() {
        imageController.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $imageController.isPresentingImagePicker, didCancel: { (phPickerViewController) in
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
}

extension ImageView {
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            imageController.listButton
            imageController.filtersMenu
            Spacer()
            choosePhotoButton
            imageController.shareButton
        }
    }
    
    @ViewBuilder
    var choosePhotoButton: some View {
        Button {
            imageController.isPresentingImagePicker = true
        } label: {
            Image(systemName: "photo\(imageController.pickedImage == nil ? "" : ".fill")")
        }
    }
    
//    @ViewBuilder
//    var listButton: some View {
//        if imageController.pickedImage != nil {
//            Button {
//                imageController.isPresentingList = true
//            } label: {
//                Image(systemName: imageController.isPresentingList ? "list.bullet.circle.fill" : "list.bullet.circle")
//            }
//        }
//    }
    
//    @ViewBuilder
//    var shareButton: some View {
//        if imageController.pickedImage != nil {
//            Button {
//                
//            } label: {
//                Image(systemName: "square.and.arrow.up")
//            }
//        }
//    }
}
