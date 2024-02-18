//
//  BookSelectionViewController.swift
//  GestuRead
//
//  Created by Jose Antonio Cordon Muñoz on 15/2/24.
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
        // Do any additional setup after loading the view.
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        //performSegue(withIdentifier: "showPDFReader", sender: selectedFileURL)
        
        // Handle the selected file URL
        // For now, we will just print the URL
        print("Selected file URL: \(selectedFileURL)")

        // TODO: Transition to the next view with the selected book
        
        // Instantiate PDFReaderViewController
        if let pdfReaderVC = storyboard?.instantiateViewController(identifier: "PDFReaderViewController") as? PDFReaderViewController {
            pdfReaderVC.title = "Selected Book"
            pdfReaderVC.loadPDF(from: selectedFileURL)
            navigationController?.pushViewController(pdfReaderVC, animated: true)
        }
    }
    
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPDFReader" {
            if let pdfReaderVC = segue.destination as? PDFReaderViewController,
               let selectedFileURL = sender as? URL {
                pdfReaderVC.loadPDF(from: selectedFileURL)
            }
        }
    }*/
}
