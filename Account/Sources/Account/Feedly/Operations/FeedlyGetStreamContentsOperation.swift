//
//  FeedlyGetStreamOperation.swift
//  Account
//
//  Created by Kiel Gillard on 20/9/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import RSParser
import RSCore

protocol FeedlyEntryProviding {
	var entries: [FeedlyEntry] { get }
}

protocol FeedlyParsedItemProviding {
	var parsedItemProviderName: String { get }
	var parsedEntries: Set<ParsedItem> { get }
}

protocol FeedlyGetStreamContentsOperationDelegate: AnyObject {
	func feedlyGetStreamContentsOperation(_ operation: FeedlyGetStreamContentsOperation, didGetContentsOf stream: FeedlyStream)
}

/// Get the stream content of a Collection from Feedly.
final class FeedlyGetStreamContentsOperation: FeedlyOperation, FeedlyEntryProviding, FeedlyParsedItemProviding, Logging {
	
	struct ResourceProvider: FeedlyResourceProviding {
		var resource: FeedlyResourceID
	}
	
	let resourceProvider: FeedlyResourceProviding
	
	var parsedItemProviderName: String {
		return resourceProvider.resource.id
	}
	
	var entries: [FeedlyEntry] {
		guard let entries = stream?.items else {
//			assert(isFinished, "This should only be called when the operation finishes without error.")
			assertionFailure("Has this operation been addeded as a dependency on the caller?")
			return []
		}
		return entries
	}
	
	var parsedEntries: Set<ParsedItem> {
		if let entries = storedParsedEntries {
			return entries
		}
		
		let parsed = Set(entries.compactMap {
			FeedlyEntryParser(entry: $0).parsedItemRepresentation
		})
		
		if parsed.count != entries.count {
			let entryIDs = Set(entries.map { $0.id })
			let parsedIDs = Set(parsed.map { $0.uniqueID })
			let difference = entryIDs.subtracting(parsedIDs)
            logger.debug("Dropping articles with ids: \(difference, privacy: .public)")
		}
		
		storedParsedEntries = parsed
		
		return parsed
	}
	
	private(set) var stream: FeedlyStream? {
		didSet {
			storedParsedEntries = nil
		}
	}
	
	private var storedParsedEntries: Set<ParsedItem>?
	
	let account: Account
	let service: FeedlyGetStreamContentsService
	let unreadOnly: Bool?
	let newerThan: Date?
	let continuation: String?
	
	weak var streamDelegate: FeedlyGetStreamContentsOperationDelegate?

	init(account: Account, resource: FeedlyResourceID, service: FeedlyGetStreamContentsService, continuation: String? = nil, newerThan: Date?, unreadOnly: Bool? = nil) {
		self.account = account
		self.resourceProvider = ResourceProvider(resource: resource)
		self.service = service
		self.continuation = continuation
		self.unreadOnly = unreadOnly
		self.newerThan = newerThan
	}
	
	convenience init(account: Account, resourceProvider: FeedlyResourceProviding, service: FeedlyGetStreamContentsService, newerThan: Date?, unreadOnly: Bool? = nil) {
		self.init(account: account, resource: resourceProvider.resource, service: service, newerThan: newerThan, unreadOnly: unreadOnly)
	}
	
	override func run() {
		service.getStreamContents(for: resourceProvider.resource, continuation: continuation, newerThan: newerThan, unreadOnly: unreadOnly) { result in
			switch result {
			case .success(let stream):
				self.stream = stream
				
				self.streamDelegate?.feedlyGetStreamContentsOperation(self, didGetContentsOf: stream)
				
				self.didFinish()
				
			case .failure(let error):
                self.logger.error("Unable to get stream contents: \(error.localizedDescription, privacy: .public)")
				self.didFinish(with: error)
			}
		}
	}
}
