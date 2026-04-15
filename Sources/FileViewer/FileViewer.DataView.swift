import SwiftUI
import Suite

extension FileViewer {
	struct DataView: View {
		let data: Data
		@State private var containerWidth: CGFloat = 0

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
		}

		@ViewBuilder
		private func rowView(at row: Int, bytesPerRow: Int) -> some View {
			HStack {
				Text(String(format: "%08x", row * bytesPerRow))
					.foregroundStyle(.secondary)
					.frame(width: 75, alignment: .leading)

				let rowData = data.subdata(in: (row * bytesPerRow)..<min((row + 1) * bytesPerRow, data.count))
				Text(Self.spacedHex(of: rowData, bytesPerRow: bytesPerRow))

				Spacer()

				Divider()

				Text(Self.spacedAscii(of: rowData))
			}
		}

		/// Formats the bytes as lowercase hex pairs, grouped in runs of 4 bytes
		/// with a single space between groups. Padded to the full row width so
		/// alignment stays consistent across rows.
		static func spacedHex(of data: Data, bytesPerRow: Int) -> String {
			guard bytesPerRow > 0 else { return "" }
			var result = ""
			for (i, byte) in data.enumerated() {
				if i > 0, i % 4 == 0 { result += " " }
				result += String(format: "%02x", byte)
			}
			let targetWidth = bytesPerRow * 2 + max(0, (bytesPerRow - 1) / 4)
			return result.padding(toLength: max(targetWidth, result.count), withPad: " ", startingAt: 0)
		}

		/// Formats the bytes as printable characters grouped in runs of 4
		/// with a single space between groups. Non-printable bytes render as ".".
		static func spacedAscii(of data: Data) -> String {
			var result = ""
			for (i, byte) in data.enumerated() {
				if i > 0, i % 4 == 0 { result += " " }
				let code: UInt8 = (byte >= 32 && byte < 127) ? byte : 0x2e
				result += String(UnicodeScalar(code))
			}
			return result
		}

		static func visibleRows(byteCount: Int, bytesPerRow: Int) -> Int {
			guard bytesPerRow > 0 else { return 0 }
			let fullRows = byteCount / bytesPerRow
			return fullRows + (byteCount % bytesPerRow == 0 ? 0 : 1)
		}

		/// Picks the largest row width that fits in the given container width,
		/// growing by 1 byte up to 8, then snapping to multiples of 8.
		static func preferredBytesPerRow(for width: CGFloat) -> Int {
			// In SF Mono at 14pt: ~8.4pt per character.
			// Per byte: 2 hex chars (~17pt) + 1 ascii char (~8.4pt) + ~4pt amortized group spacing ≈ 30pt
			// Overhead: 8-digit offset column (75pt) + HStack spacing + divider ≈ 115pt
			let overhead: CGFloat = 115
			let perByte: CGFloat = 30
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
