Need to display very complex PDFs with good performance?  
Consider your prayers answered:

# SimplePDFKit

A performant, PDFKit-based iOS PDF rendering library for single pages. This library used to use PDFium for vastly better performance than iOS's built-in PDFKit could achieve, but since the latter has improved since, SimplePDFKit now simply uses PDFKit as its backend (though it's easy enough to use a different backend if you provide it).

* It's fast. Many PDFs that are barely viewable with the built-in `PDFKit` are no problem at all for this library.
* Supports virtually any zoom level (well, any zoom level `UIScrollView` supports; all I'm saying is this library isn't going to be the limiting factor).
* Has simple but powerful APIs for overlaying things onto the PDF, as well as changing the overall visuals.
