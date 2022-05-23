import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics

extension Notification.Name {
    static var resetZoomableScrollViewScale: Notification.Name { return .init("resetZoomableScrollViewScale") }
    static var scrollZoomableScrollViewToRect: Notification.Name { return .init("scrollZoomableScrollViewToRect") }
    
}

extension Notification {
    struct Keys {
        static let rect = "rect"
    }
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
                            list
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
    
    var list: some View {
        List {
            ForEach(vm.boxes) { box in
                Button {
                    guard let image = vm.pickedImage else { return }
                    let rect = box.boundingBox.rectForSize(image.size)
                    let userInfo = [Notification.Keys.rect: rect]
                    NotificationCenter.default.post(name: .scrollZoomableScrollViewToRect, object: nil, userInfo: userInfo)
                } label: {
                    Text(box.recognizedTextWithLC?.string ?? "")
                }
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
import CoreMedia

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
        
        NotificationCenter.default.addObserver(forName: .scrollZoomableScrollViewToRect, object: nil, queue: .main) { notification in
            guard let rect = notification.userInfo?[Notification.Keys.rect] as? CGRect else {
                return
            }
            let zoomRect = scrollView.zoomRectForScale(5, withCenter: CGPoint(x: rect.midX, y: rect.midY))
            scrollView.zoom(to: zoomRect, animated: true)
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

extension UIScrollView {
    
    func zoomRectForScale(_ scale: CGFloat, withCenter center: CGPoint) -> CGRect {

        let newCenter = convert(center, from: self)
        let rect = CGRect(center: newCenter, size: CGSize(width: 50, height: 50))
        return rect
        var zoomRect: CGRect = .zero

        // the zoom rect is in the content view's coordinates.
        //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = self.contentSize.height / scale
        zoomRect.size.width  = self.contentSize.width / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = (center.x * (2 - self.minimumZoomScale) - (zoomRect.size.width  / 2.0))
        zoomRect.origin.y = (center.y * (2 - self.minimumZoomScale) - (zoomRect.size.height / 2.0))

        return zoomRect
    }
}

extension CGRect
{
    /** Creates a rectangle with the given center and dimensions
    - parameter center: The center of the new rectangle
    - parameter size: The dimensions of the new rectangle
     */
    init(center: CGPoint, size: CGSize)
    {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
    /** the coordinates of this rectangles center */
    var center: CGPoint
        {
        get { return CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }
    
    /** the x-coordinate of this rectangles center
    - note: Acts as a settable midX
    - returns: The x-coordinate of the center
     */
    var centerX: CGFloat
        {
        get { return midX }
        set { origin.x = newValue - width * 0.5 }
    }
    
    /** the y-coordinate of this rectangles center
     - note: Acts as a settable midY
     - returns: The y-coordinate of the center
     */
    var centerY: CGFloat
        {
        get { return midY }
        set { origin.y = newValue - height * 0.5 }
    }
    
    // MARK: - "with" convenience functions
    
    /** Same-sized rectangle with a new center
    - parameter center: The new center, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(center: CGPoint?) -> CGRect
    {
        return CGRect(center: center ?? self.center, size: size)
    }
    
    /** Same-sized rectangle with a new center-x
    - parameter centerX: The new center-x, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY), size: size)
    }

    /** Same-sized rectangle with a new center-y
    - parameter centerY: The new center-y, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX, y: centerY ?? self.centerY), size: size)
    }
    
    /** Same-sized rectangle with a new center-x and center-y
    - parameter centerX: The new center-x, ignored if nil
    - parameter centerY: The new center-y, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?, centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY ?? self.centerY), size: size)
    }
}
