import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics

extension Notification.Name {
    static var resetZoomableScrollViewScale: Notification.Name { return .init("resetZoomableScrollViewScale") }
}

struct ContentView: View {

    @StateObject var vm: ViewModel = ViewModel()
    @State var isPresentingImagePicker = false
    @State var selectedBox: Box? = nil
    
    @State var isShowingList: Bool = false
    @State var isHidingBoxes: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = vm.pickedImage {
                    GeometryReader { proxy in
                        ZoomableScrollView {
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
                        .onAppear {
                            vm.contentSize = proxy.size
                        }
                        .onChange(of: isShowingList) { newValue in
                            isHidingBoxes = true
                            NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
                            guard let image = vm.pickedImage else { return }
                            vm.contentSize = proxy.size
                            vm.calculateBoxes(in: image)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    isHidingBoxes = false
                                }
                            }
                        }
                    }
                    if isShowingList {
                        Group {
                            Divider()
                            List {
                                Text("Testing")
                            }
                            .listStyle(.plain)
                        }
                        .transition(.opacity)
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
            Button {
                withAnimation {
                    isShowingList.toggle()
                }
            } label: {
                Image(systemName: isShowingList ? "list.bullet.circle.fill" : "list.bullet.circle")
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

import SwiftUI

public struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        
        // create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        NotificationCenter.default.addObserver(forName: .resetZoomableScrollViewScale, object: nil, queue: .main) { notification in
            scrollView.setZoomScale(1, animated: true)
        }
        return scrollView
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }
    
    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    // MARK: - Coordinator
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
