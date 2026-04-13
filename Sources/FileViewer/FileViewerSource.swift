import Foundation
import UniformTypeIdentifiers
import Suite

public enum FileViewerSource: Sendable {
	case url(URL)
	case data(Data, name: String, type: UTType? = nil)

	public var displayName: String {
		switch self {
		case .url(let url): url.lastPathComponent
		case .data(_, let name, _): name
		}
	}

	public var fileType: UTType {
		switch self {
		case .url(let url): url.fileType ?? .data
		case .data(_, let name, let type):
			type ?? UTType(filenameExtension: (name as NSString).pathExtension) ?? .data
		}
	}

	public var data: Data? {
		switch self {
		case .url(let url): try? Data(contentsOf: url)
		case .data(let data, _, _): data
		}
	}

	public var url: URL? {
		if case .url(let url) = self { return url }
		return nil
	}

	public var byteCount: Int {
		switch self {
		case .url(let url): Int(url.fileSize)
		case .data(let data, _, _): data.count
		}
	}

	public var pathExtension: String {
		switch self {
		case .url(let url): url.pathExtension
		case .data(_, let name, _): (name as NSString).pathExtension
		}
	}
}

extension URLResourceKey {
	static var propertiesOfInterest: [URLResourceKey] {
		[
			.contentTypeKey, .isSymbolicLinkKey, .isPackageKey, .isSystemImmutableKey,
			.isHiddenKey, .hasHiddenExtensionKey, .creationDateKey,
			.attributeModificationDateKey, .linkCountKey, .labelColorKey,
			.isReadableKey, .isWritableKey, .isExecutableKey, .addedToDirectoryDateKey,
			.fileContentIdentifierKey, .mayHaveExtendedAttributesKey,
			.fileAllocatedSizeKey, .totalFileSizeKey, .totalFileAllocatedSizeKey,
			.isAliasFileKey, .ubiquitousItemIsUploadedKey, .ubiquitousItemIsDownloadingKey,
			.ubiquitousItemUploadingErrorKey, .ubiquitousItemDownloadingErrorKey,
			.localizedNameKey, .localizedLabelKey, .localizedTypeDescriptionKey,
			.fileProtectionKey, .canonicalPathKey,
		]
	}
}
