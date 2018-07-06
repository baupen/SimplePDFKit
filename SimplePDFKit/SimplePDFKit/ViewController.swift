// Created by Julian Dunskus

import UIKit

public class SimplePDFViewController: UIViewController {
	var scrollView: UIScrollView!
	var contentView: UIView!
	var fallbackView: UIImageView!
	var renderView: UIImageView!
	var contentWidth: NSLayoutConstraint!
	var contentHeight: NSLayoutConstraint!
	
	/// Simply assign a page to this property and the view will be updated accordingly.
	public var page: PDFPage! {
		didSet {
			loadViewIfNeeded()
			
			contentWidth.constant = page.size.width
			contentHeight.constant = page.size.height
			
			prepareFallback()
		}
	}
	
	private let renderQueue = DispatchQueue(label: "rendering", qos: .userInteractive)
	private var renderBitmap: PDFBitmap!
	private var fallbackResolution: CGSize!
	/// how much extra area to render around the borders (for smoother scrolling), in terms of the render size
	private let overrenderFraction: CGFloat = 0.1
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	public override func loadView() {
		let frame = CGRect(origin: .zero, size: .one)
		
		view = UIView(frame: frame)
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
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollView.delegate = self
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		scrollView.zoomScale = scrollView.minimumZoomScale // zoom to fit
	}
	
	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
		
		let scales = scrollView.frame.size / page.size
		let scaleToFit = min(scales.width, scales.height)
		// set zoom scale bounds relatively to that
		scrollView.minimumZoomScale = scaleToFit * 1
		scrollView.maximumZoomScale = scaleToFit * 100
		let scale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, scrollView.zoomScale))
		scrollView.setZoomScale(scale * 1.000001, animated: false) // dirty hack to make it re-center
		scrollView.setZoomScale(scale, animated: true)
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
	
	private func centerContentView() {
		let offset = 0.5 * (scrollView.bounds.size - scrollView.contentSize).map { max(0, $0) }
		scrollView.contentInset = UIEdgeInsets(top: offset.y, left: offset.x, bottom: 0, right: 0)
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
		print(newFrame)
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
			guard condition() else { return }
			
			// background color
			bitmap.context.fill(CGRect(origin: .zero, size: .one))
			
			let renderBounds = bounds * bitmap.size
			
			page.render(in: bitmap, bounds: renderBounds)
			
			let image = UIImage(cgImage: bitmap.context.makeImage()!)
			
			DispatchQueue.main.async {
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
