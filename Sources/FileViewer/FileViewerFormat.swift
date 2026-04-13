import Foundation
import SwiftUI

public protocol FileViewerFormat: AnyObject {
	static var fileExtension: String { get }
	static var name: String { get }

	init(url: URL) throws
	init(data: Data, name: String) throws

	var contentView: AnyView { get }
}

public var fileViewerFormats: [FileViewerFormat.Type] = []

public func registerFileViewer(format: FileViewerFormat.Type) {
	fileViewerFormats.append(format)
}

public func fileViewerFormatter(for fileExtension: String) -> (any FileViewerFormat.Type)? {
	fileViewerFormats.first { $0.fileExtension.lowercased() == fileExtension.lowercased() }
}
