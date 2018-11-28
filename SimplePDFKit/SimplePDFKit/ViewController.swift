// Created by Julian Dunskus

import UIKit

public final class SimplePDFViewController: UIViewController {
	/// used for displaying the PDF and scrolling/zooming around
	public var scrollView: UIScrollView!
	/// add any views you'd like to have overlaid on the PDF in here
	public var overlayView: UIView!
	/// the content view of the scroll view, for your convenience (this is also the scroll view's `viewForZooming`)
	public var contentView: UIView!
	
	/// Simply assign a page to this property and the view will be updated accordingly.
	public var page: PDFPage! {
		didSet {
			loadViewIfNeeded()
			
			contentWidth.constant = page.size.width
			contentHeight.constant = page.size.height
			
			prepareFallback()
		}
	}
	
	public weak var delegate: SimplePDFViewControllerDelegate?
	
	private var fallbackView: UIImageView!
	private var renderView: UIImageView!
	private var contentWidth: NSLayoutConstraint!
	private var contentHeight: NSLayoutConstraint!
	
	private let renderQueue = DispatchQueue(label: "rendering", qos: .userInteractive)
	private var renderBitmap: PDFBitmap!
	private var fallbackResolution: CGSize!
	/// how much extra area to render around the borders (for smoother scrolling), in terms of the render size
	private let overrenderFraction: CGFloat = 0.1
	private var shouldResetZoom = true
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	public override func loadView() {
		let frame = CGRect(origin: .zero, size: .one)
		
		view = UIView(frame: frame)
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		
		scrollView = UIScrollView(frame: frame)
		view.addSubview(scrollView)
		
		scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		contentView = UIView(frame: frame)
		scrollView.addSubview(contentView)
		
		contentView.translatesAutoresizingMaskIntoConstraints = false
		contentWidth = contentView.widthAnchor.constraint(equalToConstant: 1000)
		contentWidth.isActive = true
		contentHeight = contentView.heightAnchor.constraint(equalToConstant: 1000)
		contentHeight.isActive = true
		
		contentView.topAnchor     .constraint(equalTo: scrollView.topAnchor     ).isActive = true
		contentView.bottomAnchor  .constraint(equalTo: scrollView.bottomAnchor  ).isActive = true
		contentView.leadingAnchor .constraint(equalTo: scrollView.leadingAnchor ).isActive = true
		contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
		
		fallbackView = UIImageView(frame: frame)
		contentView.addSubview(fallbackView)
		
		fallbackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		renderView = UIImageView(frame: frame)
		contentView.addSubview(renderView)
		
		overlayView = UIView(frame: frame)
		contentView.addSubview(overlayView)
		
		overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
		doubleTapRecognizer.numberOfTapsRequired = 2
		view.addGestureRecognizer(doubleTapRecognizer)
	}
	
	public override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		
		if let container = view.superview {
			view.frame = container.bounds
			shouldResetZoom = true
			view.setNeedsLayout()
		}
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollView.delegate = self
	}
	
	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		// maintain zoom-to-fit if currently set
		if scrollView.zoomScale == scrollView.minimumZoomScale {
			coordinator.animate(alongsideTransition: { context in
				self.scrollView.zoomScale = self.scrollView.minimumZoomScale
			})
		}
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		renderBitmap = makeBitmap(size: scrollView.frame.size * (1 + 2 * overrenderFraction))
		
		let scrollableSize = scrollView.frame.inset(by: originalContentInset ?? scrollView.contentInset).size
		let scales = scrollableSize / page.size
		let scaleToFit = min(scales.width, scales.height)
		// set zoom scale bounds relatively to that
		scrollView.minimumZoomScale = scaleToFit * 1
		scrollView.maximumZoomScale = scaleToFit * 100
		
		let clampedScale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, scrollView.zoomScale))
		let scale = shouldResetZoom ? scaleToFit : clampedScale
		
		scrollView.setZoomScale(scale, animated: !shouldResetZoom)
		centerContentView()
		
		shouldResetZoom = false
	}
	
	@objc private func doubleTapped(_ tapRecognizer: UITapGestureRecognizer) {
		guard tapRecognizer.state == .recognized else { return }
		
		let position = tapRecognizer.location(in: contentView)
		if scrollView.zoomScale == scrollView.minimumZoomScale {
			let size = contentView.bounds.size / 4
			scrollView.zoom(to: CGRect(origin: position - size / 2, size: size), animated: true)
		} else {
			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
		}
	}
	
	/// renders a fallback image that's displayed when a part of the page isn't rendered yet; size is proportional to device screen size, which should be appropriate
	private func prepareFallback() {
		let screenBounds = UIScreen.main.bounds
		let targetSize = screenBounds.width * screenBounds.height * 3
		let pageSize = page.size.width * page.size.height
		let size = sqrt(targetSize / pageSize)
		let fallbackBitmap = makeBitmap(size: CGSize(width: size * page.size.width, height: size * page.size.height))
		fallbackResolution = fallbackBitmap.size
		
		render(in: fallbackBitmap) { image in
			self.fallbackView.image = image
			self.delegate?.pdfFinishedLoading()
		}
	}
	
	/// makes a bitmap with the specified size in points (i.e. automatically scaled up on retina screens)
	private func makeBitmap(size: CGSize) -> PDFBitmap {
		UIGraphicsBeginImageContextWithOptions(size, true, 0) // opaque; screen scale
		let context = UIGraphicsGetCurrentContext()!
		UIGraphicsEndImageContext() // yes, this is safe
		
		// normalize to (0, 1)
		context.scaleBy(x: size.width, y: size.height)
		
		// background color
		context.setFillColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
		
		return try! PDFBitmap(referencing: context)
	}
	
	private var originalContentInset: UIEdgeInsets?
	
	private func centerContentView() {
		let contentSize = CGSize(
			width: contentWidth.constant,
			height: contentHeight.constant
		)
		let scaledSize = contentSize * scrollView.zoomScale // dirty but works
		
		let inset = originalContentInset ?? scrollView.contentInset
		originalContentInset = inset
		
		let scrollableSize = scrollView.bounds.inset(by: inset).size
		let offset = 0.5 * (scrollableSize - scaledSize).map { max(0, $0) }
		
		var newInset = inset
		newInset.left += offset.x
		newInset.top += offset.y
		scrollView.contentInset = newInset
	}
	
	private func frameForRenderView() -> CGRect {
		let frame = contentView.convert(scrollView.frame, from: view)
		return CGRect(origin: frame.origin - overrenderFraction * frame.size,
					  size: frame.size * (1 + 2 * overrenderFraction))
	}
	
	private var currentRender: UUID?
	private func enqueueRender() {
		let id = UUID()
		currentRender = id
		
		let newFrame = frameForRenderView()
		// bounds of the page in newFrame's coordinate system
		let pageBounds = CGRect(origin: -newFrame.origin, size: contentView.bounds.size)
		let renderBounds = pageBounds / newFrame.size
		
		// see if render would be higher-res than fallback
		let renderDensity = renderBitmap.size.width / newFrame.width
		let fallbackDensity = fallbackResolution.width / fallbackView.frame.width
		guard renderDensity > fallbackDensity else { return }
		
		render(in: renderBitmap, bounds: renderBounds, if: self.currentRender == id) { image in
			self.renderView.image = image
			self.renderView.frame = newFrame
		}
	}
	
	/// - Parameter bounds: the bounds of the page in normalized (0...1) coordinates (ULO); unit rect by default.
	/// - Parameter condition: a condition to evaluate when getting the opportunity to render asynchronously, to allow invalidating outdated tasks.
	private func render(in bitmap: PDFBitmap,
						bounds: CGRect = CGRect(origin: .zero, size: .one),
						if condition: @autoclosure @escaping () -> Bool = true,
						completion: @escaping (UIImage) -> Void) {
		let page = self.page!
		renderQueue.async {
			guard condition(), page === self.page else { return }
			
			// background color
			bitmap.context.fill(CGRect(origin: .zero, size: .one))
			
			let renderBounds = bounds * bitmap.size
			
			page.render(in: bitmap, bounds: renderBounds)
			
			let image = UIImage(cgImage: bitmap.context.makeImage()!)
			
			DispatchQueue.main.async {
				guard page === self.page else { return }
				completion(image)
			}
		}
	}
}

extension SimplePDFViewController: UIScrollViewDelegate {
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		enqueueRender()
	}
	
	public func scrollViewDidZoom(_ scrollView: UIScrollView) {
		centerContentView()
		enqueueRender()
		
		delegate?.pdfZoomed(to: scrollView.zoomScale)
	}
	
	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		enqueueRender()
	}
	
	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		enqueueRender()
	}
	
	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		enqueueRender()
	}
	
	public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		enqueueRender()
	}
	
	public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return contentView
	}
}
