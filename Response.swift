//
//  Response.swift
//  VT
//
//  Created by Nada  on 14/11/2021.
//

import Foundation
class Response:Codable {
    
    let url :String?
    let title: String
    
    enum CodingKeys: String, CodingKey{
        case url = "url_m"
        case title
    }
}
