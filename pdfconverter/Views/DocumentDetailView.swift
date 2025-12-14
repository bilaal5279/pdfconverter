import SwiftUI
import SwiftData
import VisionKit

struct DocumentDetailView: View {
    @Bindable var document: ScannedDocument
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentPageIndex = 0
    @State private var showEditor = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showRenameAlert = false
    @State private var newTitle = ""
    @State private var showDeleteAlert = false
    
    // OCR State
    @State private var showOCRSheet = false
    @State private var ocrText = ""
    @State private var isProcessingOCR = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Slideshow
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(document.pagePaths.enumerated()), id: \.element) { index, path in
                        if let image = FileService.shared.loadImage(from: path) {
                            ZoomableImageView(image: image)
                                .tag(index)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .onAppear {
                     UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(DesignSystem.Colors.royalBlue)
                     UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.5)
                }
                
                // Bottom Toolbar (Pinned to Bottom)
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 20) {
                        // Rename
                        ToolbarButton(icon: "pencil", title: "Rename") {
                            newTitle = document.title
                            showRenameAlert = true
                        }
                        
                        // Share -> Export
                        ToolbarButton(icon: "square.and.arrow.up", title: "Export") {
                            prepareShareItems()
                        }
                        
                        // Edit (Organizer)
                        ToolbarButton(icon: "square.grid.2x2", title: "Edit") {
                            showEditor = true
                        }
                        
                        // Print
                        ToolbarButton(icon: "printer", title: "Print") {
                            printDocument()
                        }
                        
                        // Delete
                        ToolbarButton(icon: "trash", title: "Delete", color: .red) {
                            showDeleteAlert = true
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20) // Bottom safety padding handled by background logic if needed, but standard padding looks good.
                    .padding(.horizontal)
                }
                .background(DesignSystem.Colors.secondaryBackground.ignoresSafeArea(edges: .bottom))
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: performOCR) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.royalBlue)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                EditorView(document: document)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .sheet(isPresented: $showOCRSheet) {
            NavigationStack {
                ScrollView {
                    Text(ocrText)
                        .padding()
                        .font(.body)
                        .textSelection(.enabled)
                }
                .navigationTitle("Extracted Text")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Copy") {
                            UIPasteboard.general.string = ocrText
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") { showOCRSheet = false }
                    }
                }
            }
        }
        .alert("Rename Document", isPresented: $showRenameAlert) {
            TextField("Title", text: $newTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                document.title = newTitle
            }
        }
        .alert("Delete Document", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(document)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func prepareShareItems() {
        let images = document.pagePaths.compactMap { FileService.shared.loadImage(from: $0) }
        guard !images.isEmpty else { return }
        
        if let pdfURL = PDFService.shared.createPDF(from: images) {
            shareItems = [pdfURL]
            showShareSheet = true
        }
    }
    
    private func printDocument() {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = .general
        printInfo.jobName = document.title
        printController.printInfo = printInfo
        
        let images = document.pagePaths.compactMap { FileService.shared.loadImage(from: $0) }
        guard !images.isEmpty, let pdfURL = PDFService.shared.createPDF(from: images) else { return }
        
        if UIPrintInteractionController.canPrint(pdfURL) {
            printController.printingItem = pdfURL
            printController.present(animated: true, completionHandler: nil)
        }
    }
    
    private func performOCR() {
        guard document.pagePaths.indices.contains(currentPageIndex),
              let image = FileService.shared.loadImage(from: document.pagePaths[currentPageIndex]) else { return }
        
        isProcessingOCR = true
        OCRService.shared.recognizeText(from: image) { text in
            DispatchQueue.main.async {
                isProcessingOCR = false
                if let text = text {
                    ocrText = text
                    showOCRSheet = true
                }
            }
        }
    }
}

// MARK: - Helper Views

struct ToolbarButton: View {
    let icon: String
    let title: String
    var color: Color = DesignSystem.Colors.textPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(height: 24)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isUserInteractionEnabled = true // Enable interaction
        
        // Add Live Text Interaction
        let analyzer = ImageAnalyzer()
        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = .automatic
        imageView.addInteraction(interaction)
        context.coordinator.interaction = interaction
        context.coordinator.analyzer = analyzer
        context.coordinator.imageView = imageView
        
        scrollView.addSubview(imageView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = context.coordinator.imageView, imageView.image != image {
            imageView.image = image
            context.coordinator.analyzeImage(image)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        var interaction: ImageAnalysisInteraction?
        var analyzer: ImageAnalyzer?
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func analyzeImage(_ image: UIImage) {
            Task {
                if let analyzer = analyzer {
                    do {
                        let configuration = ImageAnalyzer.Configuration([.text])
                        let analysis = try await analyzer.analyze(image, configuration: configuration)
                        await MainActor.run {
                            self.interaction?.analysis = analysis
                            self.interaction?.preferredInteractionTypes = .textSelection
                        }
                    } catch {
                        print("Analysis failed: \(error)")
                    }
                }
            }
        }
    }
}
