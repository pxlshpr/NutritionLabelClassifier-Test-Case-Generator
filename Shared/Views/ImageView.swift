import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics
import SwiftHaptics

struct ImageView: View {

    @StateObject var classifierController = ClassifierController.shared
//    @State var isPresentingImagePicker = false
//    @State var isPresentingList: Bool = false
    @State var shrinkImageView: Bool = false

    @State var isHidingBoxes: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = classifierController.pickedImage {
                    zoomableScrollView(with: image)
                } else {
                    Button("Choose Image") {
                        classifierController.isPresentingImagePicker = true
                    }
                }
            }
            .navigationTitle("Test Case Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar { bottomToolbarContent }
        .bottomSheet(isPresented: $classifierController.isPresentingList,
                     largestUndimmedDetentIdentifier: .medium,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            ListView(classifierController: classifierController)
        }
        .bottomSheet(item: $classifierController.selectedBox,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            if let box = classifierController.selectedBox, let index = classifierController.boxes.firstIndex(where: { $0.id == box.id }) {
                BoxDetailsView(box: $classifierController.boxes[index])
            }
        }
        .sheet(isPresented: $classifierController.isPresentingImagePicker) {
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
                classifierController.contentSize = proxy.size
            }
            .frame(maxHeight: shrinkImageView ? proxy.size.height / 2.0 : proxy.size.height)
            .onChange(of: classifierController.selectedBox) { newValue in
                updateSize(for: proxy.size, reduceSize: newValue != nil)
            }
            .onChange(of: classifierController.isPresentingList) { newValue in
                updateSize(for: proxy.size, reduceSize: classifierController.isPresentingList)
            }
        }
    }
    
    func updateSize(for size: CGSize, reduceSize: Bool) {
        guard let image = classifierController.pickedImage else { return }
        
        isHidingBoxes = true
        ClassifierController.shared.resignBoxFocus()
        
        var contentSize = size
        if reduceSize {
            contentSize.height = size.height / 2.0
        }
        classifierController.contentSize = contentSize
        classifierController.recalculateBoxes(for: image)
        
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
            ForEach(classifierController.filteredBoxes, id: \.self) { box in
                Button {
                    Haptics.feedback(style: .rigid)
//                    classifierController.selectedBox = box
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                        classifierController.sendZoomNotification(for: box)
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
                    if let focusedBox = classifierController.focusedBox {
                        if box.id == focusedBox.id {
                            if box.status == .valid {
                                Color.valid
                            } else if box.status == .invalid {
                                Color.invalid
                            } else {
                                Color.focused
                            }
                        } else if focusedBox.relatedBoxes.contains(where: { $0.id == box.id }) {
                            if box.status == .valid {
                                Color.validSupplementary
                            } else if box.status == .invalid {
                                Color.invalidSupplementary
                            } else {
                                Color.focusedSupplementary
                            }
                        } else {
                            Color.unfocused
                        }
                    } else {
                        if box.status == .valid {
                            Color.valid
                        } else if box.status == .invalid {
                            Color.invalid
                        } else {
                            Color.unmarked
                        }
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
        if let imagePickerDelegate = classifierController.imagePickerDelegate {
            ImagePickerView(filter: .any(of: [.images, .livePhotos]), selectionLimit: 1, delegate: imagePickerDelegate)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func setImagePickerDelegate() {
        classifierController.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $classifierController.isPresentingImagePicker, didCancel: { (phPickerViewController) in
            print("didCancel")
        }, didSelect: { (result) in
            guard let image = result.images.first else {
                fatalError("Couldn't get picked image")
            }
            classifierController.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }
}

extension Color {
    static var valid: Color {
        Color.green
    }
    
    static var invalid: Color {
        Color.red
    }
    
    static var focused: Color {
        Color.yellow
    }
    
    static var validSupplementary: Color {
        Color.valid.opacity(0.7)
    }
    
    static var invalidSupplementary: Color {
        Color.invalid.opacity(0.7)
    }
    
    static var focusedSupplementary: Color {
        Color.focused.opacity(0.7)
    }
    
    static var unfocused: Color {
        Color.white
    }
    
    static var unmarked: Color {
        Color.cyan
    }
}

extension ImageView {
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            classifierController.listButton
            classifierController.filtersMenu
            Spacer()
            choosePhotoButton
            classifierController.shareButton
        }
    }
    
    @ViewBuilder
    var choosePhotoButton: some View {
        Button {
            classifierController.isPresentingImagePicker = true
        } label: {
            Image(systemName: "photo\(classifierController.pickedImage == nil ? "" : ".fill")")
        }
    }
    
//    @ViewBuilder
//    var listButton: some View {
//        if classifierController.pickedImage != nil {
//            Button {
//                classifierController.isPresentingList = true
//            } label: {
//                Image(systemName: classifierController.isPresentingList ? "list.bullet.circle.fill" : "list.bullet.circle")
//            }
//        }
//    }
    
//    @ViewBuilder
//    var shareButton: some View {
//        if classifierController.pickedImage != nil {
//            Button {
//                
//            } label: {
//                Image(systemName: "square.and.arrow.up")
//            }
//        }
//    }
}
