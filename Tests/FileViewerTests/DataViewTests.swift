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

	// MARK: - snapToAllowed

	@Test func snapZeroOrNegativeGivesOne() {
		#expect(FileViewer.DataView.snapToAllowed(0) == 1)
		#expect(FileViewer.DataView.snapToAllowed(-5) == 1)
	}

	@Test func snapSmallValuesAreUnchanged() {
		for n in 1...8 {
			#expect(FileViewer.DataView.snapToAllowed(n) == n)
		}
	}

	@Test func snapAboveEightRoundsDownToMultipleOfEight() {
		#expect(FileViewer.DataView.snapToAllowed(9) == 8)
		#expect(FileViewer.DataView.snapToAllowed(15) == 8)
		#expect(FileViewer.DataView.snapToAllowed(16) == 16)
		#expect(FileViewer.DataView.snapToAllowed(17) == 16)
		#expect(FileViewer.DataView.snapToAllowed(23) == 16)
		#expect(FileViewer.DataView.snapToAllowed(24) == 24)
		#expect(FileViewer.DataView.snapToAllowed(100) == 96)
	}

	// MARK: - preferredBytesPerRow

	@Test func tinyWidthGivesAtLeastOneByte() {
		#expect(FileViewer.DataView.preferredBytesPerRow(for: 0) == 1)
		#expect(FileViewer.DataView.preferredBytesPerRow(for: 50) == 1)
	}

	@Test func widthGrowsByOneByteUpToEight() {
		// Just check that the width→bytes function is monotonically increasing
		// and hits each value 1..8 for progressively wider widths.
		var seen = Set<Int>()
		for w in stride(from: CGFloat(80), through: 600, by: 10) {
			let n = FileViewer.DataView.preferredBytesPerRow(for: w)
			seen.insert(n)
		}
		// Expect to have seen small sizes 1..8
		for expected in 1...8 {
			#expect(seen.contains(expected), "expected to observe \(expected) bytes/row somewhere in 80…600pt")
		}
	}

	@Test func aboveEightJumpsInEights() {
		let values = (80...2000).map { FileViewer.DataView.preferredBytesPerRow(for: CGFloat($0)) }
		let largeValues = Set(values.filter { $0 > 8 })
		// Only multiples of 8 should appear above 8.
		for v in largeValues {
			#expect(v % 8 == 0, "\(v) is not a multiple of 8")
		}
	}

	@Test func preferredBytesPerRowIsNonDecreasing() {
		var last = 0
		for w in stride(from: CGFloat(0), through: 2000, by: 5) {
			let n = FileViewer.DataView.preferredBytesPerRow(for: w)
			#expect(n >= last, "at width \(w): \(n) < previous \(last)")
			last = n
		}
	}

	// MARK: - byteIndex (position → byte mapping used by drag selection)

	@Test func byteIndexReturnsNilForEmptyRow() {
		let idx = FileViewer.DataView.byteIndex(at: 10, rowStart: 0, rowLen: 0, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == nil)
	}

	@Test func byteIndexClampsNegativeXToFirstByte() {
		let idx = FileViewer.DataView.byteIndex(at: -5, rowStart: 100, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == 100)
	}

	@Test func byteIndexHitsFirstCellAtZero() {
		let idx = FileViewer.DataView.byteIndex(at: 0, rowStart: 0, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == 0)
	}

	@Test func byteIndexHitsSecondCell() {
		// x = 17 → falls into cell 1 (offset 17..34)
		let idx = FileViewer.DataView.byteIndex(at: 17, rowStart: 0, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == 1)
	}

	@Test func byteIndexAccountsForGroupGap() {
		// bytesPerRow=8, cellWidth=17, groupGapWidth=10 (class constant).
		// After 4 bytes: 4*17 = 68, then 10pt gap → byte 4 starts at 78
		let before = FileViewer.DataView.byteIndex(at: 72, rowStart: 0, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		let after = FileViewer.DataView.byteIndex(at: 80, rowStart: 0, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		#expect(before == 3)   // x=72 is in the gap, picks last cell that ended before it
		#expect(after == 4)    // x=80 is in cell 4 (offset 78..95)
	}

	@Test func byteIndexClampsPastEndToLastByte() {
		// Row length 5, any x past the content maps to byte 4
		let idx = FileViewer.DataView.byteIndex(at: 1000, rowStart: 0, rowLen: 5, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == 4)
	}

	@Test func byteIndexRespectsRowStartOffset() {
		// Row starts at byte 16, first hit should be 16, not 0
		let idx = FileViewer.DataView.byteIndex(at: 5, rowStart: 16, rowLen: 8, bytesPerRow: 8, cellWidth: 17)
		#expect(idx == 16)
	}

	// MARK: - selectedRange via selection state (reachable through DataView's public API)

	@Test func selectedRangeIsNilByDefault() {
		let view = FileViewer.DataView(source: .data(Data([0, 1, 2]), name: "t.bin"))
		#expect(view.selectedRange == nil)
	}

	// MARK: - asciiString (for Cmd-C)

	@Test func asciiStringForPrintableBytes() {
		let result = FileViewer.DataView.asciiString(for: Data("hello".utf8), range: 0..<5)
		#expect(result == "hello")
	}

	@Test func asciiStringSubstitutesDotForNonPrintable() {
		let result = FileViewer.DataView.asciiString(for: Data([0x48, 0x00, 0x69, 0x7f, 0x21]), range: 0..<5)
		#expect(result == "H.i.!")
	}

	@Test func asciiStringForPartialRange() {
		let result = FileViewer.DataView.asciiString(for: Data("hello world".utf8), range: 6..<11)
		#expect(result == "world")
	}

	@Test func asciiStringClampsUpperBound() {
		// Range past end should clamp, not crash
		let result = FileViewer.DataView.asciiString(for: Data("abc".utf8), range: 1..<100)
		#expect(result == "bc")
	}

	@Test func asciiStringClampsLowerBound() {
		let result = FileViewer.DataView.asciiString(for: Data("abc".utf8), range: -5..<2)
		#expect(result == "ab")
	}

	@Test func asciiStringEmptyRange() {
		let result = FileViewer.DataView.asciiString(for: Data("abc".utf8), range: 1..<1)
		#expect(result == "")
	}

	@Test func asciiStringEmptyData() {
		let result = FileViewer.DataView.asciiString(for: Data(), range: 0..<10)
		#expect(result == "")
	}

	// MARK: - hexString (for Cmd-Shift-C)

	@Test func hexStringJoinsBytesContiguously() {
		let result = FileViewer.DataView.hexString(for: Data([0x01, 0xab, 0xff]), range: 0..<3)
		#expect(result == "01abff")
	}

	@Test func hexStringForPartialRange() {
		let result = FileViewer.DataView.hexString(for: Data([0x11, 0x22, 0x33, 0x44]), range: 1..<3)
		#expect(result == "2233")
	}

	@Test func hexStringSingleByte() {
		let result = FileViewer.DataView.hexString(for: Data([0xff, 0x00]), range: 0..<1)
		#expect(result == "ff")
	}

	@Test func hexStringClampsUpperBound() {
		let result = FileViewer.DataView.hexString(for: Data([0x12, 0x34]), range: 0..<10)
		#expect(result == "1234")
	}

	@Test func hexStringClampsLowerBound() {
		let result = FileViewer.DataView.hexString(for: Data([0x12, 0x34]), range: -5..<1)
		#expect(result == "12")
	}

	@Test func hexStringEmptyRange() {
		let result = FileViewer.DataView.hexString(for: Data([0x12]), range: 0..<0)
		#expect(result == "")
	}

	@Test func hexStringEmptyData() {
		let result = FileViewer.DataView.hexString(for: Data(), range: 0..<10)
		#expect(result == "")
	}
}
