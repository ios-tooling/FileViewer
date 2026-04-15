import SwiftUI
import Suite
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension FileViewer {
	struct DataView: View {
		static let hexByteWidth: CGFloat = 22
		static let asciiCharWidth: CGFloat = 12
		static let groupGapWidth: CGFloat = 10
		static let rowHeight: CGFloat = 19

		let data: Data
		@State private var containerWidth: CGFloat = 0
		@State private var selectionStart: Int?
		@State private var selectionEnd: Int?
		#if os(macOS)
		@State private var keyMonitor: Any?
		#endif

		init(source: FileViewerSource) {
			self.data = source.data ?? Data()
		}

		var body: some View {
			let bytesPerRow = Self.preferredBytesPerRow(for: containerWidth)
			let rows = Self.visibleRows(byteCount: data.count, bytesPerRow: bytesPerRow)

			ScrollView {
				LazyVStack(alignment: .leading, spacing: 2) {
					ForEach(0..<rows, id: \.self) { row in
						rowView(at: row, bytesPerRow: bytesPerRow)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.multilineTextAlignment(.leading)
				.font(.system(size: 14).monospaced())
				.lineLimit(1)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(
				GeometryReader { geo in
					Color.clear
						.onChange(of: geo.size.width) { newWidth in
							containerWidth = geo.size.width
						}
						.onAppear { containerWidth = geo.size.width }
				}
			)
			#if os(macOS)
			.onAppear { installKeyMonitor() }
			.onDisappear { removeKeyMonitor() }
			#else
			.background(copyShortcuts)
			#endif
		}

		#if !os(macOS)
		// Hidden buttons that drive the Cmd-C / Cmd-Shift-C shortcuts on iOS hardware keyboards.
		@ViewBuilder
		private var copyShortcuts: some View {
			Button("Copy ASCII") { copyAscii() }
				.keyboardShortcut("c", modifiers: .command)
				.opacity(0)
				.frame(width: 0, height: 0)
				.accessibilityHidden(true)
			Button("Copy Hex") { copyHex() }
				.keyboardShortcut("c", modifiers: [.command, .option])
				.opacity(0)
				.frame(width: 0, height: 0)
				.accessibilityHidden(true)
		}
		#endif

		#if os(macOS)
		private func installKeyMonitor() {
			guard keyMonitor == nil else { return }
			keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
				let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
				guard mods.contains(.command),
					  event.charactersIgnoringModifiers?.lowercased() == "c" else {
					return event
				}
				if mods.contains(.option) {
					copyHex()
				} else {
					copyAscii()
				}
				return nil
			}
		}

		private func removeKeyMonitor() {
			if let keyMonitor {
				NSEvent.removeMonitor(keyMonitor)
				self.keyMonitor = nil
			}
		}
		#endif

		private func copyAscii() {
			guard let range = selectedRange else { return }
			Self.copyToPasteboard(Self.asciiString(for: data, range: range))
		}

		private func copyHex() {
			guard let range = selectedRange else { return }
			Self.copyToPasteboard(Self.hexString(for: data, range: range))
		}

		/// Returns the "." -substituted printable representation of the bytes in `range`.
		static func asciiString(for data: Data, range: Range<Int>) -> String {
			let lower = max(0, range.lowerBound)
			let upper = min(data.count, range.upperBound)
			guard lower < upper else { return "" }
			var result = ""
			for byte in data[lower..<upper] {
				let code: UInt8 = (byte >= 32 && byte < 127) ? byte : 0x2e
				result.append(Character(UnicodeScalar(code)))
			}
			return result
		}

		/// Returns contiguous lowercase hex for the bytes in `range`.
		static func hexString(for data: Data, range: Range<Int>) -> String {
			let lower = max(0, range.lowerBound)
			let upper = min(data.count, range.upperBound)
			guard lower < upper else { return "" }
			return data[lower..<upper].map { String(format: "%02x", $0) }.joined()
		}

		static func copyToPasteboard(_ string: String) {
			#if os(macOS)
			NSPasteboard.general.clearContents()
			NSPasteboard.general.setString(string, forType: .string)
			#elseif os(iOS)
			UIPasteboard.general.string = string
			#endif
		}

		var selectedRange: Range<Int>? {
			guard let s = selectionStart, let e = selectionEnd else { return nil }
			return min(s, e)..<(max(s, e) + 1)
		}

		private func isSelected(_ index: Int) -> Bool {
			selectedRange?.contains(index) ?? false
		}

		@ViewBuilder
		private func rowView(at row: Int, bytesPerRow: Int) -> some View {
			let rowStart = row * bytesPerRow
			let rowLen = max(0, min(bytesPerRow, data.count - rowStart))

			HStack(spacing: 8) {
				Text(String(format: "%08x", rowStart))
					.foregroundStyle(.secondary)
					.frame(width: 75, alignment: .leading)

				hexStrip(originRow: row, rowStart: rowStart, rowLen: rowLen, bytesPerRow: bytesPerRow)

				Spacer()

				Divider()

				asciiStrip(originRow: row, rowStart: rowStart, rowLen: rowLen, bytesPerRow: bytesPerRow)
			}
			.frame(height: Self.rowHeight)
		}

		@ViewBuilder
		private func hexStrip(originRow: Int, rowStart: Int, rowLen: Int, bytesPerRow: Int) -> some View {
			HStack(spacing: 0) {
				ForEach(0..<bytesPerRow, id: \.self) { i in
					byteCell(at: rowStart + i, hasData: i < rowLen, width: Self.hexByteWidth, content: hexCellText(at: rowStart + i, hasData: i < rowLen))
					if (i + 1) % 4 == 0, i < bytesPerRow - 1 {
						Color.clear.frame(width: Self.groupGapWidth)
					}
				}
			}
			.contentShape(Rectangle())
			.gesture(stripGesture(originRow: originRow, bytesPerRow: bytesPerRow, cellWidth: Self.hexByteWidth))
		}

		@ViewBuilder
		private func asciiStrip(originRow: Int, rowStart: Int, rowLen: Int, bytesPerRow: Int) -> some View {
			HStack(spacing: 0) {
				ForEach(0..<bytesPerRow, id: \.self) { i in
					byteCell(at: rowStart + i, hasData: i < rowLen, width: Self.asciiCharWidth, content: asciiCellText(at: rowStart + i, hasData: i < rowLen))
					if (i + 1) % 4 == 0, i < bytesPerRow - 1 {
						Color.clear.frame(width: Self.groupGapWidth)
					}
				}
			}
			.contentShape(Rectangle())
			.gesture(stripGesture(originRow: originRow, bytesPerRow: bytesPerRow, cellWidth: Self.asciiCharWidth))
		}

		@ViewBuilder
		private func byteCell(at index: Int, hasData: Bool, width: CGFloat, content: String) -> some View {
			Text(content)
				.frame(width: width, alignment: .leading)
				.background(hasData && isSelected(index) ? Color.accentColor.opacity(0.35) : Color.clear)
		}

		private func hexCellText(at index: Int, hasData: Bool) -> String {
			hasData ? String(format: "%02x", data[index]) : "  "
		}

		private func asciiCellText(at index: Int, hasData: Bool) -> String {
			guard hasData else { return " " }
			let byte = data[index]
			let code: UInt8 = (byte >= 32 && byte < 127) ? byte : 0x2e
			return String(UnicodeScalar(code))
		}

		private func stripGesture(originRow: Int, bytesPerRow: Int, cellWidth: CGFloat) -> some Gesture {
			DragGesture(minimumDistance: 0, coordinateSpace: .local)
				.onChanged { value in
					let totalRows = Self.visibleRows(byteCount: data.count, bytesPerRow: bytesPerRow)
					// Start anchor: always in the origin row at the starting x.
					let originRowLen = max(0, min(bytesPerRow, data.count - originRow * bytesPerRow))
					if let s = Self.byteIndex(at: value.startLocation.x, rowStart: originRow * bytesPerRow, rowLen: originRowLen, bytesPerRow: bytesPerRow, cellWidth: cellWidth) {
						selectionStart = s
					}
					// End cursor: target row derived from vertical offset relative to strip top.
					let rowOffset = Int((value.location.y / Self.rowHeight).rounded(.down))
					let targetRow = max(0, min(max(0, totalRows - 1), originRow + rowOffset))
					let targetRowStart = targetRow * bytesPerRow
					let targetRowLen = max(0, min(bytesPerRow, data.count - targetRowStart))
					if let e = Self.byteIndex(at: value.location.x, rowStart: targetRowStart, rowLen: targetRowLen, bytesPerRow: bytesPerRow, cellWidth: cellWidth) {
						selectionEnd = e
					}
				}
		}

		/// Maps a horizontal offset within a strip to a byte index, accounting for
		/// fixed-width cells and the extra gap inserted after every 4 bytes. A point
		/// that falls inside a group gap maps back to the byte just before the gap.
		static func byteIndex(at x: CGFloat, rowStart: Int, rowLen: Int, bytesPerRow: Int, cellWidth: CGFloat) -> Int? {
			guard rowLen > 0 else { return nil }
			if x < 0 { return rowStart }
			var offset: CGFloat = 0
			for i in 0..<rowLen {
				let cellEnd = offset + cellWidth
				if x < cellEnd { return rowStart + i }
				offset = cellEnd
				if (i + 1) % 4 == 0, i < bytesPerRow - 1 {
					let gapEnd = offset + groupGapWidth
					if x < gapEnd { return rowStart + i }
					offset = gapEnd
				}
			}
			return rowStart + rowLen - 1
		}

		static func visibleRows(byteCount: Int, bytesPerRow: Int) -> Int {
			guard bytesPerRow > 0 else { return 0 }
			let fullRows = byteCount / bytesPerRow
			return fullRows + (byteCount % bytesPerRow == 0 ? 0 : 1)
		}

		/// Picks the largest row width that fits in the given container width,
		/// growing by 1 byte up to 8, then snapping to multiples of 8.
		static func preferredBytesPerRow(for width: CGFloat) -> Int {
			// hexByteWidth (22) + asciiCharWidth (12) + amortized group gap (~5) ≈ 39pt per byte.
			let overhead: CGFloat = 115
			let perByte: CGFloat = 39
			let rawFit = Int((width - overhead) / perByte)
			return snapToAllowed(rawFit)
		}

		/// Snaps a raw byte count into the allowed set: {1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, ...}
		static func snapToAllowed(_ n: Int) -> Int {
			if n <= 1 { return 1 }
			if n <= 8 { return n }
			return (n / 8) * 8
		}
	}
}
