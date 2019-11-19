import UIKit
import SimplePDFKit

class ViewController: UIViewController {
	@IBOutlet private var reasonHolder: UIView!
	
	private var pdfController: SimplePDFViewController! {
		didSet { loadPDF() }
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// embed segue
		pdfController = (segue.destination as! SimplePDFViewController)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// you can add extra insets to the pdf view like this, in case you're drawing stuff over it but want its content to be fully visible within the uncovered area
		pdfController.additionalSafeAreaInsets.bottom = reasonHolder.frame.height
	}
	
	private func loadPDF() {
		let document = try! PDFDocument(atPath: Bundle.main.path(forResource: "example easy", ofType: "pdf")!)
		pdfController.page = try! document.page(0)
	}
}
