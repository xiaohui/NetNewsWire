//
//  ArticleFetcher.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 2/4/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import Articles
import ArticlesDatabase

@MainActor public protocol ArticleFetcher {

	func fetchArticles() throws -> Set<Article>
	func fetchArticlesAsync(_ completion: @escaping ArticleSetResultBlock)
	func fetchUnreadArticles() throws -> Set<Article>
	func fetchUnreadArticlesBetween(before: Date?, after: Date?) throws -> Set<Article>
	func fetchUnreadArticlesAsync(_ completion: @escaping ArticleSetResultBlock)
//    func asyncFetchUnreadArticles() async throws -> Set<Article>
}

extension Feed: ArticleFetcher {
	
    @MainActor public func fetchArticles() throws -> Set<Article> {
		return try account?.fetchArticles(.feed(self)) ?? Set<Article>()
	}

	public func fetchArticlesAsync(_ completion: @escaping ArticleSetResultBlock) {
		guard let account = account else {
			assertionFailure("Expected feed.account, but got nil.")
			completion(.success(Set<Article>()))
			return
		}
		account.fetchArticlesAsync(.feed(self), completion)
	}

    @MainActor public func fetchUnreadArticles() throws -> Set<Article> {
		return try fetchArticles().unreadArticles()
	}

	public func fetchUnreadArticlesBetween(before: Date? = nil, after: Date? = nil) throws -> Set<Article> {
		return try account?.fetchUnreadArticlesBetween(feeds: [self], limit: nil, before: before, after: after) ?? Set<Article>()
	}

	public func fetchUnreadArticlesAsync(_ completion: @escaping ArticleSetResultBlock) {
		guard let account = account else {
			assertionFailure("Expected feed.account, but got nil.")
			completion(.success(Set<Article>()))
			return
		}
		account.fetchArticlesAsync(.feed(self)) { articleSetResult in
			switch articleSetResult {
			case .success(let articles):
				completion(.success(articles.unreadArticles()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

    public func asyncFetchUnreadArticles() async throws -> Set<Article> {
        guard let account else {
            assertionFailure("Expected feed.account, but got nil.")
            return Set<Article>()
        }
        let articles = try await account.asyncFetchArticles(.feed(self))
        return articles.unreadArticles()
    }
}

extension Folder: ArticleFetcher {
	
    @MainActor public func fetchArticles() throws -> Set<Article> {
		guard let account = account else {
			assertionFailure("Expected folder.account, but got nil.")
			return Set<Article>()
		}
		return try account.fetchArticles(.folder(self, false))
	}

	public func fetchArticlesAsync(_ completion: @escaping ArticleSetResultBlock) {
		guard let account = account else {
			assertionFailure("Expected folder.account, but got nil.")
			completion(.success(Set<Article>()))
			return
		}
		account.fetchArticlesAsync(.folder(self, false), completion)
	}

    @MainActor public func fetchUnreadArticles() throws -> Set<Article> {
		guard let account = account else {
			assertionFailure("Expected folder.account, but got nil.")
			return Set<Article>()
		}
		return try account.fetchArticles(.folder(self, true))
	}

	public func fetchUnreadArticlesBetween(before: Date? = nil, after: Date? = nil) throws -> Set<Article> {
		guard let account = account else {
			assertionFailure("Expected folder.account, but got nil.")
			return Set<Article>()
		}
		return try account.fetchUnreadArticlesBetween(folder: self, limit: nil, before: before, after: after)
	}

	public func fetchUnreadArticlesAsync(_ completion: @escaping ArticleSetResultBlock) {
		guard let account = account else {
			assertionFailure("Expected folder.account, but got nil.")
			completion(.success(Set<Article>()))
			return
		}
		account.fetchArticlesAsync(.folder(self, true), completion)
	}
}
