Need to display very complex PDFs with good performance?  
Consider your prayers answered (well, kinda):

# SimplePDFKit
A performant, PDFium-based iOS PDF rendering library for single pages.

### Pros
* It's fast. Like _really_ fast.
* Supports virtually any zoom level (well, any zoom level `UIScrollView` supports; all I'm saying is this library isn't going to be the limiting factor).

### Cons
* No bitcode support, since I couldn't manage to compile PDFium correctly. In fact, I just used the build from [UXReader](https://github.com/vfr/UXReader-iOS). This means you'll have to disable bitcode in any target you need this library for.
* Contains 282 MB PDFium binary. Yeah, this is a big problem. looks like it's only taking up 240 MB total on my phone though, if that helps ¯\\\_(ツ)\_/¯
