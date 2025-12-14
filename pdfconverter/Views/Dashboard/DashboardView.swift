import SwiftUI
import SwiftData
import VisionKit
import PhotosUI
import UniformTypeIdentifiers
import StoreKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScannedDocument.creationDate, order: .reverse) private var documents: [ScannedDocument]
    
    @State private var showScanner = false
    // @State private var showSettings = false // Removed for NavigationLink
    
    // Navigation Path
    @State private var navigationPath = NavigationPath()
    
    // Rating Logic
    @Environment(\.requestReview) var requestReview
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    // Import States
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isImporting = false // Spinner state (still used for Photos)
    
    @State private var pendingImportItem: ImportItem? // For File Import
    
    // Action States for Menu
    @State private var documentToRename: ScannedDocument?
    @State private var newTitle = ""
    @State private var documentToDelete: ScannedDocument?
    @State private var showDeleteAlert = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    
    // Quick Actions
    private let actions = [
        QuickAction(title: "Scan", icon: "camera.viewfinder", color: DesignSystem.Colors.royalBlue),
        QuickAction(title: "Photos", icon: "photo.on.rectangle", color: DesignSystem.Colors.royalBlue),
        QuickAction(title: "Files", icon: "folder", color: DesignSystem.Colors.royalBlue)
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // MARK: - Premium Mesh Background
                DesignSystem.Colors.background.ignoresSafeArea()
                
                // Ambient Blurs
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.royalBlue.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -120, y: -300)
                    
                    Circle()
                        .fill(DesignSystem.Colors.metallicGold.opacity(0.06))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: 120, y: -200)
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Header / Title (Custom for Premium Feel)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Scans")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text("Digitize & Organize")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            
                            // Navigation Link to Settings
                             NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(DesignSystem.Colors.textPrimary.opacity(0.8))
                                    .padding(10)
                                    .background(Material.thinMaterial) // Glass effect
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Quick Actions (Glass Cards)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                                    Button(action: {
                                        handleAction(action)
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: action.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(action.color)
                                                .frame(height: 30)
                                            
                                            Text(action.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                        .background(Color.white.opacity(0.6))
                                        .background(Material.ultraThinMaterial)
                                        .cornerRadius(20)
                                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white, lineWidth: 0.5)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Recent Scans List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, 20)
                                Spacer()
                            }
                            
                            if documents.isEmpty {
                                EmptyStateView()
                                    .padding(.top, 20)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(documents) { doc in
                                        DocumentRow(
                                            document: doc,
                                            onRename: { prepareRename(doc) },
                                            onPrint: { preparePrint(doc) },
                                            onExport: { prepareExport(doc) },
                                            onDelete: { prepareDelete(doc) }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                // Spinner (Only for Photo Importing now)
                if isImporting {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Importing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(20)
                }
            }
            .navigationTitle("") // Hidden, using custom header
            .toolbar(.hidden)
            .navigationDestination(for: DocumentNavigationWrapper.self) { wrapper in
                DocumentDetailView(document: wrapper.document)
            }
            // .sheet(isPresented: $showSettings) removed

            // Camera Scanner
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView { scan in
                    showScanner = false
                    handleScan(scan)
                } didCancel: {
                    showScanner = false
                } didFail: { error in
                    showScanner = false
                    print("Scan failed: \(error)")
                }
                .ignoresSafeArea()
            }
            // Photos Picker
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { key, newItem in
                if let newItem = newItem {
                    handlePhotoSelection(newItem)
                }
            }
            // File Importer
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image, .pdf, .officeDocument, .plainText, .rtf]) { result in
                handleFileImport(result: result)
            }
            // Conversion View (Premium Flow)
            .fullScreenCover(item: $pendingImportItem) { item in
                ConversionView(fileURL: item.url) { savedPaths in
                    if let doc = createDocument(from: savedPaths, source: "Import") {
                        // Warp in a Hashable wrapper for navigation
                        navigationPath.append(DocumentNavigationWrapper(document: doc))
                    }
                }
            }
            // Alerts & Sheets
            .alert("Rename Document", isPresented: Binding(get: { documentToRename != nil }, set: { if !$0 { documentToRename = nil } })) {
                TextField("Title", text: $newTitle)
                Button("Cancel", role: .cancel) { documentToRename = nil }
                Button("Save") {
                    if let doc = documentToRename {
                        doc.title = newTitle
                    }
                    documentToRename = nil
                }
            }
            .alert("Delete Document", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let doc = documentToDelete {
                        modelContext.delete(doc)
                    }
                    documentToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this document? This cannot be undone.")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .onAppear {
                checkForRatingPrompt()
            }
        }
    }
    
    // MARK: - Action Handlers for Menu
    
    private func prepareRename(_ doc: ScannedDocument) {
        newTitle = doc.title
        documentToRename = doc
    }
    
    private func prepareDelete(_ doc: ScannedDocument) {
        documentToDelete = doc
        showDeleteAlert = true
    }
    
    private func prepareExport(_ doc: ScannedDocument) {
        let images = doc.pagePaths.compactMap { FileService.shared.loadImage(from: $0) }
        guard !images.isEmpty, let pdfURL = PDFService.shared.createPDF(from: images) else { return }
        shareItems = [pdfURL]
        showShareSheet = true
    }
    
    private func preparePrint(_ doc: ScannedDocument) {
        let images = doc.pagePaths.compactMap { FileService.shared.loadImage(from: $0) }
        guard !images.isEmpty, let pdfURL = PDFService.shared.createPDF(from: images) else { return }
        
        if UIPrintInteractionController.canPrint(pdfURL) {
            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = .general
            printInfo.jobName = doc.title
            printController.printInfo = printInfo
            printController.printingItem = pdfURL
            printController.present(animated: true, completionHandler: nil)
        }
    }
    
    private func handleAction(_ action: QuickAction) {
        if action.title == "Scan" {
            showScanner = true
        } else if action.title == "Photos" {
            showPhotoPicker = true
        } else if action.title == "Files" {
            showFileImporter = true
        }
    }
    
    // MARK: - Handlers
    
    private func handleScan(_ scan: VNDocumentCameraScan) {
        var savedPaths: [String] = []
        for i in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: i)
            if let path = FileService.shared.saveImage(image) {
                savedPaths.append(path)
            }
        }
        createDocument(from: savedPaths, source: "Scan") // Ignore return
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        isImporting = true
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                isImporting = false
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        if let path = FileService.shared.saveImage(image) {
                            createDocument(from: [path], source: "Photo") // Ignore return
                        }
                    }
                    selectedPhotoItem = nil // Reset
                case .failure(let error):
                    print("Error loading photo: \(error)")
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Instead of converting immediately, trigger the Premium Conversion View
            pendingImportItem = ImportItem(url: url)
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
    
    @discardableResult
    private func createDocument(from paths: [String], source: String) -> ScannedDocument? {
        guard !paths.isEmpty else { return nil }
        let newDoc = ScannedDocument(title: "\(source) \(Date().formatted(date: .numeric, time: .shortened))", pagePaths: paths)
        modelContext.insert(newDoc)
        return newDoc
    }
    
    private func checkForRatingPrompt() {
        let currentTimestamp = Date().timeIntervalSince1970
        
        if firstLaunchDate == 0 {
            firstLaunchDate = currentTimestamp
        } else if !hasRequestedReview {
            let threeDaysInSeconds: Double = 3 * 24 * 60 * 60
            if currentTimestamp - firstLaunchDate >= threeDaysInSeconds {
                requestReview()
                hasRequestedReview = true
            }
        }
    }
}

// Wrapper to make Navigation work with SwiftData models safely
struct DocumentNavigationWrapper: Hashable {
    let document: ScannedDocument
    
    static func == (lhs: DocumentNavigationWrapper, rhs: DocumentNavigationWrapper) -> Bool {
        lhs.document.id == rhs.document.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(document.id)
    }
}

// Wrapper for URL to be Identifiable for fullScreenCover(item:)
struct ImportItem: Identifiable {
    let id = UUID()
    let url: URL
}

// Custom UTType for DOCX if not available
extension UTType {
    static var officeDocument: UTType {
        UTType("org.openxmlformats.wordprocessingml.document") ?? .data
    }
}

struct DocumentRow: View {
    let document: ScannedDocument
    let onRename: () -> Void
    let onPrint: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            
            // Navigate on tap of the content area
            NavigationLink(value: DocumentNavigationWrapper(document: document)) {
                HStack(spacing: 16) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignSystem.Colors.background)
                            .frame(width: 56, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(DesignSystem.Colors.royalBlue.opacity(0.4))
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text("\(document.pageCount) Pages • \(document.creationDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle()) // Needed to prevent whole row from flashing when menu is tapped
            
            // 3-Dot Menu
            Menu {
                Button(action: onRename) {
                    Label("Rename", systemImage: "pencil")
                }
                Button(action: onPrint) {
                    Label("Print", systemImage: "printer")
                }
                Button(action: onExport) {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            // Increase tap target
        }
        .padding(16)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4) // Premium Shadow
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            // Using a system image or custom illustration
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 50))
                    .foregroundColor(DesignSystem.Colors.royalBlue.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text("No Scans Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Tap the camera button to start scanning your documents.")
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct QuickAction {
    let title: String
    let icon: String
    let color: Color
}

#Preview {
    DashboardView()
}
