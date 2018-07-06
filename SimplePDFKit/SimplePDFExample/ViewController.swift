// Created by Julian Dunskus

import UIKit
import SimplePDFKit

class ViewController: UIViewController {
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		let document = try! PDFDocument(atPath: Bundle.main.path(forResource: "example easy", ofType: "pdf")!)
		let page = try! document.page(0)
		
		let controller = SimplePDFViewController()
		controller.page = page
		present(controller, animated: true)
	}
}
