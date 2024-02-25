//
//  BookSelectionViewController.swift
//  GestuRead
//
//  Created by jcordon5 on 2024.
//

import Foundation
import UIKit
import MobileCoreServices

class BookSelectionViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var selectBookButton: UIButton!
    
    @IBAction func selectBookTapped(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        print("Selected file URL: \(selectedFileURL)")
        
        // Instantiate PDFReaderViewController
        if let pdfReaderVC = storyboard?.instantiateViewController(identifier: "PDFReaderViewController") as? PDFReaderViewController {
            pdfReaderVC.title = "Selected Book"
            pdfReaderVC.loadPDF(from: selectedFileURL)
            navigationController?.pushViewController(pdfReaderVC, animated: true)
        }
    }
    
}
