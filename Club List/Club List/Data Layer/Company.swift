//
//  Company.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit


private struct DummyCodable: Codable {}

struct Members : Codable {
    var members : [Member]
    
    init(from decoder: Decoder) throws {
        var members = [Member]()
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let route = try? container.decode(Member.self) {
                members.append(route)
            }
            else {
                _ = try? container.decode(DummyCodable.self) // <-- TRICK
            }
        }
        self.members = members
    }
}

struct Companies : Codable {
    var companies : [Company]
    
    init(from decoder: Decoder) throws {
        var companies = [Company]()
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let route = try? container.decode(Company.self) {
                companies.append(route)
            }
            else {
                _ = try? container.decode(DummyCodable.self) // <-- TRICK
            }
        }
        self.companies = companies
    }
}

struct Company : Codable {
    let _id : String
    let logo : String
    let company : String
    let website : String
    let about : String
    var members : [Member]
    var favorite : Bool
    var follow : Bool

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try values.decode(String.self, forKey: ._id)
        self.logo = try values.decode(String.self, forKey: .logo)
        self.company = try values.decode(String.self, forKey: .company)
        self.website = try values.decode(String.self, forKey: .website)
        self.about = try values.decode(String.self, forKey: .about)
        let memberList = try values.decode(Members.self, forKey: .members)
        self.members = memberList.members
        self.favorite = false
        self.follow = false
    }
    
    mutating func toggleFollow()
    {
        self.follow = !self.follow
    }
    
    mutating func toggleFavorite()
    {
        self.favorite = !self.favorite
    }
}
