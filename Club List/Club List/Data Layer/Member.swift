//
//  Member.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit

struct Name:Codable {
    let first : String
    let last : String
}
struct Member:Codable {
    let _id : String
    let name : Name
    let age : Int
    let email : String
    let phone : String
    var favorite: Bool
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try values.decode(String.self, forKey: ._id)
        self.name = try values.decode(Name.self, forKey: .name)
        self.age = try values.decode(Int.self, forKey: .age)
        self.email = try values.decode(String.self, forKey: .email)
        self.phone = try values.decode(String.self, forKey: .phone)
        self.favorite = false
    }
    mutating func toggleFavorite()
    {
        self.favorite = !self.favorite
    }
    
}
