import Foundation
import CoreGraphics

fileprivate var hasInitializedPDFium = false

fileprivate func initializePDFiumIfNeeded() {
	guard !hasInitializedPDFium else { return }
	FPDF_InitLibrary()
	hasInitializedPDFium = true
}

public final class PDFiumDocument: SimplePDFDocument {
	fileprivate let raw: FPDF_DOCUMENT
	
	private let pageCount: Int
	private var pages: [WeakReference<PDFiumPage>?]
	
	public convenience init(at url: URL) throws {
		try self.init(atPath: url.path)
	}
	
	public init(atPath path: String) throws {
		initializePDFiumIfNeeded()
		raw = try convert { FPDF_LoadDocument(path, nil) } // nil: no password
		pageCount = Int(FPDF_GetPageCount(raw))
		pages = Array(repeating: nil, count: pageCount)
	}
	
	deinit {
		FPDF_CloseDocument(raw)
	}
	
	/// gets the `pageNumber`th page of the document; starting at 0 for the first page
	public func page(_ pageNumber: Int) throws -> PDFiumPage {
		guard case 0..<pageCount = pageNumber else {
			throw SimplePDFError.invalidPageNumber
		}
		
		if let page = pages[pageNumber]?.pointee {
			return page
		} else {
			let page = try PDFiumPage(in: self, number: pageNumber)
			pages[pageNumber] = WeakReference(to: page)
			return page
		}
	}
}

fileprivate final class WeakReference<Object: AnyObject> {
	weak var pointee: Object?
	
	init(to pointee: Object) {
		self.pointee = pointee
	}
}

public final class PDFiumPage: SimplePDFPage {
	fileprivate let raw: FPDF_PAGE
	
	public let document: PDFiumDocument
	/// the size of the page, in its own coordinate system
	public let size: CGSize
	
	fileprivate init(in document: PDFiumDocument, number: Int) throws {
		self.document = document
		
		raw = try convert { FPDF_LoadPage(document.raw, Int32(number)) }
		
		var (width, height) = (0.0, 0.0)
		FPDF_GetPageSizeByIndex(document.raw, Int32(number), &width, &height)
		size = CGSize(width: width, height: height)
	}
	
	deinit {
		FPDF_ClosePage(raw)
	}
	
	/// - Parameter bounds: the bounds of the finished render within the bitmap, in bitmap coords.
	public func render(in bitmap: PDFiumBitmap, bounds: CGRect) {
		let renderingOptions = FPDF_NO_CATCH
		
		FPDF_RenderPageBitmap(
			bitmap.raw,
			raw,
			Int32(bounds.origin.x),
			Int32(bounds.origin.y),
			Int32(bounds.width),
			Int32(bounds.height),
			0,
			renderingOptions
		)
	}
}

public final class PDFiumBitmap: SimplePDFRenderDestination {
	fileprivate var raw: FPDF_BITMAP
	public let context: CGContext
	
	public init(referencing context: CGContext) throws {
		self.context = context
		
		try raw = convert {
			FPDFBitmap_CreateEx(
				Int32(context.width),
				Int32(context.height),
				FPDFBitmap_BGRA,
				context.data,
				Int32(context.bytesPerRow)
			)
		}
	}
	
	deinit {
		FPDFBitmap_Destroy(raw)
	}
}

public enum SimplePDFError: Error {
	case invalidPageNumber
}

public enum PDFiumError: Int, Error {
	case success = 0
	case unknownError
	case fileNotFound // or could not be opened
	case dataCorrupted
	case incorrectPassword
	case unsupportedSecurityScheme
	case pageNotFound // or content error
}

fileprivate func convert<T>(_ call: () -> T?) throws -> T {
	if let result = call() {
		return result
	} else {
		let errorCode = Int(FPDF_GetLastError())
		throw PDFiumError(rawValue: errorCode) ?? .unknownError
	}
}
