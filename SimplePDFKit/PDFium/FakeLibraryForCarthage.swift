// Created by Julian Dunskus

import Foundation

#if arch(x86_64)

func FPDF_InitLibrary() { fatalError() }
func FPDF_GetLastError() -> UInt { fatalError() }

struct FPDF_DOCUMENT {}
func FPDF_LoadDocument(_ path: String, _ password: String?) -> FPDF_DOCUMENT? {fatalError() }
func FPDF_CloseDocument(_ doc: FPDF_DOCUMENT) { fatalError() }

func FPDF_GetPageCount(_ doc: FPDF_DOCUMENT) -> Int32 { fatalError() }
func FPDF_GetPageSizeByIndex(_ doc: FPDF_DOCUMENT, _ number: Int32, _ w: inout Double, _ h: inout Double) { fatalError() }

struct FPDF_PAGE {}
func FPDF_LoadPage(_ doc: FPDF_DOCUMENT, _ number: Int32) -> FPDF_PAGE? { fatalError() }
func FPDF_ClosePage(_ page: FPDF_PAGE) { fatalError() }

func FPDF_RenderPageBitmap(_ bitmap: FPDF_BITMAP, _ page: FPDF_PAGE, _ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ rotation: Int32, _ options: Int32) { fatalError() }
let FPDF_NO_CATCH: Int32 = 0

struct FPDF_BITMAP {}
func FPDFBitmap_CreateEx(_ w: Int32, _ h: Int32, _ format: Int32, _ data: UnsafeMutableRawPointer?, _ stride: Int32) -> FPDF_BITMAP? { fatalError() }
func FPDFBitmap_Destroy(_ bitmap: FPDF_BITMAP) { fatalError() }
let FPDFBitmap_BGRx: Int32 = 0

#endif
