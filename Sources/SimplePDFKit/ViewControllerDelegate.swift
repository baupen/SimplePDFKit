import UIKit

@MainActor
public protocol SimplePDFViewControllerDelegate: AnyObject {
	func pdfZoomed(to scale: CGFloat)
	func pdfFinishedLoading()
}

extension SimplePDFViewControllerDelegate {
	func pdfZoomed(to scale: CGFloat) {}
	func pdfFinishedLoading() {}
}
