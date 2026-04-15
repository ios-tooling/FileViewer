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

	// MARK: - spacedHex

	@Test func spacedHexThreeBytesHaveNoGroupSpace() {
		// Fewer than 4 bytes → no group boundary
		let result = FileViewer.DataView.spacedHex(of: Data([0x01, 0xab, 0xff]), bytesPerRow: 3)
		#expect(result == "01abff")
	}

	@Test func spacedHexGroupsEveryFourBytes() {
		let result = FileViewer.DataView.spacedHex(of: Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]), bytesPerRow: 8)
		#expect(result.hasPrefix("01020304 0506"))
	}

	@Test func spacedHexEightBytesIsTwoGroups() {
		let result = FileViewer.DataView.spacedHex(of: Data(0x01...0x08), bytesPerRow: 8)
		#expect(result == "01020304 05060708")
	}

	@Test func spacedHexSixteenBytesIsFourGroups() {
		let data = Data(0x01...0x10)
		let result = FileViewer.DataView.spacedHex(of: data, bytesPerRow: 16)
		#expect(result == "01020304 05060708 090a0b0c 0d0e0f10")
	}

	@Test func spacedHexPadsShortRowToFullWidth() {
		// 8 bytes per row: full width = 8*2 + (8-1)/4 = 16 + 1 = 17 chars
		let result = FileViewer.DataView.spacedHex(of: Data([0x12, 0x34]), bytesPerRow: 8)
		#expect(result.count == 17)
		#expect(result.hasPrefix("1234"))
	}

	@Test func spacedHexSingleByte() {
		let result = FileViewer.DataView.spacedHex(of: Data([0xff]), bytesPerRow: 1)
		#expect(result == "ff")
	}

	@Test func spacedHexEmptyDataStillPadsToFullWidth() {
		// 16 bytes per row → 16*2 + 3 group separators = 35 chars
		let result = FileViewer.DataView.spacedHex(of: Data(), bytesPerRow: 16)
		#expect(result.count == 35)
		#expect(result.allSatisfy { $0 == " " })
	}

	@Test func spacedHexGuardsZeroBytesPerRow() {
		#expect(FileViewer.DataView.spacedHex(of: Data([0x42]), bytesPerRow: 0) == "")
	}

	// MARK: - spacedAscii

	@Test func spacedAsciiThreeCharsHaveNoGroupSpace() {
		let result = FileViewer.DataView.spacedAscii(of: Data("abc".utf8))
		#expect(result == "abc")
	}

	@Test func spacedAsciiGroupsEveryFourBytes() {
		let result = FileViewer.DataView.spacedAscii(of: Data("abcdef".utf8))
		#expect(result == "abcd ef")
	}

	@Test func spacedAsciiEightBytesIsTwoGroups() {
		let result = FileViewer.DataView.spacedAscii(of: Data("abcdefgh".utf8))
		#expect(result == "abcd efgh")
	}

	@Test func spacedAsciiSubstitutesDotForNonPrintable() {
		let result = FileViewer.DataView.spacedAscii(of: Data([0x00, 0x41, 0x01, 0x7f]))
		#expect(result == ".A..")  // within first group of 4, no separator yet
	}

	@Test func spacedAsciiSubstitutesAcrossGroupBoundary() {
		let result = FileViewer.DataView.spacedAscii(of: Data([0x00, 0x41, 0x42, 0x43, 0x01, 0x7f]))
		#expect(result == ".ABC ..")
	}

	@Test func spacedAsciiEmpty() {
		#expect(FileViewer.DataView.spacedAscii(of: Data()) == "")
	}
}
