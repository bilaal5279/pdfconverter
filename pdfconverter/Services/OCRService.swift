import UIKit
import Vision

struct OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func recognizeText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                print("OCR Error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(recognizedText)
        }
        
        request.recognitionLevel = .accurate
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR request: \(error)")
            completion(nil)
        }
    }
}
