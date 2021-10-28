import UIKit
import CGeometry

public protocol SimplePDFDocument {
	associatedtype Page: SimplePDFPage
	
	init(at url: URL) throws
	init(atPath path: String) throws
	
	func page(_ pageNumber: Int) throws -> Page
}

public enum SimplePDFError: Error {
	case invalidPageNumber
}

public protocol SimplePDFPage {
	associatedtype RenderDestination: SimplePDFRenderDestination
	associatedtype ID: Hashable
	
	var id: ID { get }
	var size: CGSize { get }
	
	func render(in bitmap: RenderDestination, bounds: CGRect)
}

extension SimplePDFPage where Self: AnyObject {
	public var id: ObjectIdentifier { .init(self) }
}

public protocol SimplePDFRenderDestination {
	var context: CGContext { get }
	
	init(referencing context: CGContext) throws
}

struct PreparedCanvas {
	let renderSize: CGSize
	let renderFunction: (CGRect) -> CGImage
	
	func render(bounds: CGRect) -> CGImage {
		renderFunction(bounds)
	}
}

protocol SimplePDFRenderer: AnyObject {
	var pageSize: CGSize { get }
	
	func prepareCanvas(size: CGSize) -> PreparedCanvas
	func prepareCanvas(scale: CGFloat) -> PreparedCanvas
}

final class RendererProvider<Page: SimplePDFPage>: SimplePDFRenderer {
	public typealias RenderDestination = Page.RenderDestination
	
	public let page: Page
	public let pageSize: CGSize
	public var backgroundColor: CGColor?
	
	init(_ page: Page) {
		self.page = page
		self.pageSize = page.size
	}
	
	/// makes a bitmap with the specified size in points (i.e. automatically scaled up on retina screens)
	private func makeRenderDestination(size: CGSize) -> RenderDestination {
		UIGraphicsBeginImageContextWithOptions(size, false, 0) // false = not opaque; 0 = screen scale
		let context = UIGraphicsGetCurrentContext()!
		UIGraphicsEndImageContext() // yes, this is safe
		
		// normalize to (0, 1)
		context.scaleBy(x: size.width, y: size.height)
		
		return try! .init(referencing: context)
	}
	
	func prepareCanvas(scale: CGFloat) -> PreparedCanvas {
		prepareCanvas(size: scale * pageSize)
	}
	
	func prepareCanvas(size: CGSize) -> PreparedCanvas {
		let destination = makeRenderDestination(size: size)
		let context = destination.context
		
		return .init(renderSize: context.size) { [unowned self] bounds in
			// background color
			context.clear(.init(origin: .zero, size: .one)) // .infinite doesn't work…
			if let backgroundColor = backgroundColor {
				context.setFillColor(backgroundColor)
			}
			context.fill(bounds)
			
			let renderBounds = bounds * context.size
			
			page.render(in: destination, bounds: renderBounds)
			return context.makeImage()!
		}
	}
}

extension CGContext {
	var size: CGSize {
		.init(width: width, height: height)
	}
	
	func scale(by scale: CGSize) {
		scaleBy(x: scale.width, y: scale.height)
	}
	
	func translate(by offset: CGVector) {
		translateBy(x: offset.dx, y: offset.dy)
	}
}
