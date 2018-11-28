// Created by Julian Dunskus

import UIKit
import SimplePDFKit

class ViewController: UIViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let document = try! PDFDocument(atPath: Bundle.main.path(forResource: "example easy", ofType: "pdf")!)
		let page = try! document.page(0)
		
		// embed segue
		let pdfController = segue.destination as! SimplePDFViewController
		pdfController.page = page
	}
}
