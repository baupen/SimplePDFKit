Need to display very complex PDFs with good performance?  
Consider your prayers answered:

# SimplePDFKit
A performant, PDFium-based iOS PDF rendering library for single pages.

The PDFium build used is from [prsolucoes/mobile-pdfium](https://github.com/prsolucoes/mobile-pdfium), who managed what I never could: to get PDFium to build for iOS (thanks so much!).

### Pros
* It's fast. Like _really_ fast. Many PDFs that are barely viewable with the built-in `PDFKit` are no problem at all for this library.
* Supports virtually any zoom level (well, any zoom level `UIScrollView` supports; all I'm saying is this library isn't going to be the limiting factor).
* Has simple but powerful APIs for overlaying things onto the PDF, as well as changing the overall visuals.

### Cons
* While PDFium is very good at rendering curves, it's actually _less_ performant than the built-in `PDFKit` when it comes to rendering font-based text! It's not terrible, but definitely noticeable.
* Contains 42 MB PDFium binary. This is really not a big problem though, especially considering bitcode + app thinning will trim it down even further for end users—12 MB of that is x64 rather than ARM, for the simulator.

