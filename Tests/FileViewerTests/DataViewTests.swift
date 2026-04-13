import Testing
import Foundation
@testable import FileViewer

@Suite("DataView byte-row arithmetic")
struct DataViewTests {

	@Test func emptyDataHasZeroRows() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 0, bytesPerRow: 12) == 0)
	}

	@Test func exactlyOneFullRow() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 12, bytesPerRow: 12) == 1)
	}

	@Test func partialFirstRowCountsAsOne() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 1, bytesPerRow: 12) == 1)
		#expect(FileViewer.DataView.visibleRows(byteCount: 11, bytesPerRow: 12) == 1)
	}

	@Test func twoFullRows() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 24, bytesPerRow: 12) == 2)
	}

	@Test func twoFullRowsPlusPartial() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 25, bytesPerRow: 12) == 3)
	}

	@Test func aLargeFile() {
		// 1MB / 12 bytes per row
		#expect(FileViewer.DataView.visibleRows(byteCount: 1_000_000, bytesPerRow: 12) == 83_334)
	}

	@Test func differentBytesPerRow() {
		#expect(FileViewer.DataView.visibleRows(byteCount: 16, bytesPerRow: 16) == 1)
		#expect(FileViewer.DataView.visibleRows(byteCount: 17, bytesPerRow: 16) == 2)
		#expect(FileViewer.DataView.visibleRows(byteCount: 32, bytesPerRow: 16) == 2)
	}

	@Test func zeroBytesPerRowDegradesGracefully() {
		// Defensive: avoid division by zero
		#expect(FileViewer.DataView.visibleRows(byteCount: 100, bytesPerRow: 0) == 0)
	}

	@Test func regressionForOriginalBugWith12BytesPerRow() {
		// The original FileBrowser DataView used `data.count % 16` instead of
		// `data.count % bytesPerRow`. With bytesPerRow=12 and a file of 16 bytes:
		// - Buggy:  fullRows=1 + (16 % 16 == 0 ? 0 : 1) = 1   ← WRONG, drops 4 trailing bytes
		// - Fixed:  fullRows=1 + (16 % 12 == 0 ? 0 : 1) = 2
		#expect(FileViewer.DataView.visibleRows(byteCount: 16, bytesPerRow: 12) == 2)
	}
}
