import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct EditorView: View {
    @Bindable var document: ScannedDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var ocrText: String = ""
    @State private var showOCRSheet = false
    @State private var isProcessingOCR = false
    @State private var draggingItem: String?
    
    // Adaptive Grid for Cards
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(document.pagePaths.enumerated()), id: \.element) { index, path in
                        if let image = FileService.shared.loadImage(from: path) {
                            PageCard(
                                image: image,
                                pageIndex: index + 1,
                                onDelete: {
                                    deletePage(at: path)
                                }
                            )
                            .onDrag {
                                draggingItem = path
                                return NSItemProvider(object: path as NSString)
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(destinationItem: path, items: $document.pagePaths, draggedItem: $draggingItem))
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 20)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: document.pagePaths)
            }
            
            // Loading Overlay
            if isProcessingOCR {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Extracting Text...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(Material.ultraThinMaterial)
                .cornerRadius(20)
            }
            
            // Bottom Action Bar Removed

        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    dismiss()
                }
                .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: performOCR) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.royalBlue)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showOCRSheet) {
            NavigationStack {
                ScrollView {
                    Text(ocrText)
                        .padding()
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .navigationTitle("Extracted Text")
                .background(DesignSystem.Colors.background)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Copy") {
                            UIPasteboard.general.string = ocrText
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            showOCRSheet = false
                        }
                    }
                }
            }
        }
    }
    
    private func exportPDF() {
        let images = document.pagePaths.compactMap { FileService.shared.loadImage(from: $0) }
        guard !images.isEmpty else { return }
        
        if let pdfURL = PDFService.shared.createPDF(from: images) {
            shareURL = pdfURL
            showShareSheet = true
        }
    }
    
    private func deletePage(at path: String) {
        withAnimation {
            if let index = document.pagePaths.firstIndex(of: path) {
                document.pagePaths.remove(at: index)
            }
        }
    }
    
    private func performOCR() {
        guard let firstPath = document.pagePaths.first,
              let image = FileService.shared.loadImage(from: firstPath) else { return }
        
        isProcessingOCR = true
        
        OCRService.shared.recognizeText(from: image) { text in
            DispatchQueue.main.async {
                self.isProcessingOCR = false
                if let text = text, !text.isEmpty {
                    self.ocrText = text
                    self.showOCRSheet = true
                }
            }
        }
    }
}

// Premium Page Card
struct PageCard: View {
    let image: UIImage
    let pageIndex: Int
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Area
            Image(uiImage: image)
                .resizable()
                .scaledToFill() // Fill the squareish area
                .frame(height: 200)
                .clipped()
                .contentShape(Rectangle())
            
            // Footer
            HStack {
                Text("Page \(pageIndex)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Page", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.secondaryBackground)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Drop Delegate
struct DropViewDelegate: DropDelegate {
    let destinationItem: String
    @Binding var items: [String]
    @Binding var draggedItem: String?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Drag logic to reorder items live
        guard let draggedItem = draggedItem else { return }
        
        if draggedItem != destinationItem {
            if let from = items.firstIndex(of: draggedItem),
               let to = items.firstIndex(of: destinationItem) {
                
                if items[to] != draggedItem {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                         items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                    }
                }
            }
        }
    }
}
