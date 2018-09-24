// Created by Julian Dunskus

import Foundation

// The PDFium binary only works for ARM, so we simulate it to essentially do nothing. This is helpful for testing on simulator and Carthage.
#if targetEnvironment(simulator)

func FPDF_InitLibrary() {}
func FPDF_GetLastError() -> UInt {
	return 0
}

// MARK: - Document

struct FPDF_DOCUMENT {}

func FPDF_LoadDocument(_ path: String, _ password: String?) -> FPDF_DOCUMENT? {
	return FPDF_DOCUMENT()
}

func FPDF_CloseDocument(_ doc: FPDF_DOCUMENT) {}

func FPDF_GetPageCount(_ doc: FPDF_DOCUMENT) -> Int32 {
	return 1
}

func FPDF_GetPageSizeByIndex(_ doc: FPDF_DOCUMENT, _ number: Int32, _ w: inout Double, _ h: inout Double) {
	w = 1024
	h = 1024
}

// MARK: - Page

struct FPDF_PAGE {}

func FPDF_LoadPage(_ doc: FPDF_DOCUMENT, _ number: Int32) -> FPDF_PAGE? {
	return FPDF_PAGE()
}

func FPDF_ClosePage(_ page: FPDF_PAGE) {}

// MARK: - Bitmap

let FPDFBitmap_BGRx: Int32 = 0

struct FPDF_BITMAP {
	var data: UnsafeMutableRawPointer
	var size: Int
}

func FPDFBitmap_CreateEx(_ w: Int32, _ h: Int32, _ format: Int32, _ data: UnsafeMutableRawPointer?, _ stride: Int32) -> FPDF_BITMAP? {
	return FPDF_BITMAP(data: data!, size: Int(w * h))
}

func FPDFBitmap_Destroy(_ bitmap: FPDF_BITMAP) {}

// MARK: - Rendering

func FPDF_RenderPageBitmap(_ bitmap: FPDF_BITMAP, _ page: FPDF_PAGE, _ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ rotation: Int32, _ options: Int32) {
	// paint everything a pleasing "you did something wrong" red
	bitmap.data.initializeMemory(
		as: Pixel.self,
		repeating: Pixel(b: 0xDD, g: 0xDD, r: 0xFF, a: 0xFF),
		count: bitmap.size
	)
}
let FPDF_NO_CATCH: Int32 = 0

private struct Pixel {
	var b, g, r, a: UInt8
}

#endif
