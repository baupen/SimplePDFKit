import PDFKit
import CGeometry
import HandyOperators

public final class PDFKitDocument: SimplePDFDocument {
	let wrapped: PDFDocument
	
	init(_ wrapped: PDFDocument) {
		self.wrapped = wrapped
	}
	
	public convenience init(at url: URL) throws {
		self.init(try PDFDocument(url: url) ??? Error.couldNotLoadDocument)
	}
	
	public convenience init(atPath path: String) throws {
		try self.init(at: URL(fileURLWithPath: path))
	}
	
	public func page(_ pageNumber: Int) throws -> PDFKitPage {
		try wrapped.page(at: pageNumber) ??? SimplePDFError.invalidPageNumber
	}
	
	public enum Error: Swift.Error {
		case couldNotLoadDocument
	}
}

private let displayBox = PDFDisplayBox.cropBox

public typealias PDFKitPage = PDFPage

extension PDFPage: SimplePDFPage {
	public typealias RenderDestination = PDFKitRenderDestination
	
	public var size: CGSize {
		bounds(for: displayBox).size
	}
	
	public func render(in bitmap: PDFKitRenderDestination, bounds: CGRect) {
		let context = bitmap.context
		context.saveGState()
		defer { context.restoreGState() }
		
		context.scale(by: .one / context.size)
		let pageBounds = self.bounds(for: displayBox)
		context.translate(by: CGVector(bounds.origin))
		context.scale(by: bounds.size / pageBounds.size)
		
		// flip vertically
		context.translateBy(x: 0, y: pageBounds.height)
		context.scaleBy(x: 1, y: -1)
		
		draw(with: displayBox, to: context)
	}
}

public final class PDFKitRenderDestination: SimplePDFRenderDestination {
	public let size: CGSize
	public let context: CGContext
	
	public init(referencing context: CGContext) throws {
		self.context = context
		
		size = .init(width: context.width, height: context.height)
	}
}
