//
//  Response.swift
//  NetworkingTests
//
//  Created by Patryk Mikolajczyk on 1/23/19.
//  Copyright © 2019 Patryk Mikolajczyk. All rights reserved.
//

import Foundation

public struct SampleResponseStruct: Codable, Equatable {
    let batches: Int
    let items: [Item]
    let total: Int
    let currentBatch: Int
    let next: Int
}

public struct Item: Codable, Equatable {
    let desc: String
    let name: String
    let stats: Stats
    let url: String
    let image: String
    let domain: String
    let id: Int
    let title: String
}

extension Item {
    public func with(
        desc: String? = nil,
        name: String? = nil,
        stats: Stats? = nil,
        url: String? = nil,
        image: String? = nil,
        domain: String? = nil,
        id: Int? = nil,
        title: String? = nil
        ) -> Item {
        return Item(
            desc: desc ?? self.desc,
            name: name ?? self.name,
            stats: stats ?? self.stats,
            url: url ?? self.url,
            image: image ?? self.image,
            domain: domain ?? self.domain,
            id: id ?? self.id,
            title: title ?? self.title
        )
    }
}


public struct Stats: Codable, Equatable {
    let articles: Int
    let pages: Int
    let videos: Int
}

public extension SampleResponseStruct {
    public static var mock = SampleResponseStruct(batches: 2,
                                                  items: (1...25)
                                                    .map { val in
                                                        return Item.mock.with(id: val)
        },
                                                  total: 50,
                                                  currentBatch: 1,
                                                  next: 0)
}

public extension Item {
    public static var mock = Item(desc: "description",
                                  name: "name",
                                  stats: .mock,
                                  url: "https://www.google.com",
                                  image: "https://www.google.com",
                                  domain: "https://www.google.com",
                                  id: 1,
                                  title: "title")
}

public extension Stats {
    public static var mock = Stats(articles: 3, pages: 5, videos: 10)
}

