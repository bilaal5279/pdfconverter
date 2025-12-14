import UIKit
import PDFKit
import WebKit

struct PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    // MARK: - Export
    
    func createPDF(from images: [UIImage]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "PhotoScan Pro",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "Doc_\(Date().timeIntervalSince1970).pdf"
        let pdfURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Standard A4 Size: 595.2 x 841.8
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            try renderer.writePDF(to: pdfURL) { context in
                for image in images {
                    context.beginPage()
                    
                    // Calculate Aspect Fit Rect
                    let aspectWidth = pageWidth / image.size.width
                    let aspectHeight = pageHeight / image.size.height
                    let aspectRatio = min(aspectWidth, aspectHeight)
                    
                    let scaledWidth = image.size.width * aspectRatio
                    let scaledHeight = image.size.height * aspectRatio
                    
                    // Center the image
                    let xPosition = (pageWidth - scaledWidth) / 2
                    let yPosition = (pageHeight - scaledHeight) / 2
                    
                    let imageRect = CGRect(x: xPosition, y: yPosition, width: scaledWidth, height: scaledHeight)
                    
                    image.draw(in: imageRect)
                }
            }
            return pdfURL
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Import (Conversion)
    
    func convertPDFToImages(url: URL) -> [UIImage]? {
        guard let document = PDFDocument(url: url) else { return nil }
        var images: [UIImage] = []
        
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            images.append(image)
        }
        return images
    }
    
    // ASYNC: General Document Converter (DOCX, TXT, RTF) using WKWebView
    @MainActor
    func convertDocumentToImages(url: URL) async -> [UIImage]? {
        return await withCheckedContinuation { continuation in
            let webView = WKWebView()
            let delegate = WebViewDelegate(continuation: continuation)
            
            // Keep a strong reference to delegate until done
            objc_setAssociatedObject(webView, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            webView.navigationDelegate = delegate
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
}

// Helper Delegate for WKWebView
class WebViewDelegate: NSObject, WKNavigationDelegate {
    let continuation: CheckedContinuation<[UIImage]?, Never>
    
    init(continuation: CheckedContinuation<[UIImage]?, Never>) {
        self.continuation = continuation
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Create PDF from WebView
        let config = WKPDFConfiguration()
        
        // Standard A4
        config.rect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        
        webView.createPDF(configuration: config) { result in
            switch result {
            case .success(let pdfData):
                // PDF Data -> Images
                if let pdfDoc = PDFDocument(data: pdfData) {
                    var images: [UIImage] = []
                    for i in 0..<pdfDoc.pageCount {
                        if let page = pdfDoc.page(at: i) {
                            let pageRect = page.bounds(for: .mediaBox)
                            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                            let image = renderer.image { ctx in
                                UIColor.white.set()
                                ctx.fill(pageRect)
                                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                                page.draw(with: .mediaBox, to: ctx.cgContext)
                            }
                            images.append(image)
                        }
                    }
                    self.continuation.resume(returning: images)
                } else {
                    self.continuation.resume(returning: nil)
                }
            case .failure(let error):
                print("WebView PDF Create Failed: \(error)")
                self.continuation.resume(returning: nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView Load Failed: \(error)")
        continuation.resume(returning: nil)
    }
}
