//
//  WeatherR.swift
//  VT
//
//  Created by Nada  on 22/11/2021.
//

import Foundation
class WeatherR {
    
    struct WeatherIno:Codable {
        let weather:[Weather]?
        let main:Main?
        let name: String?
    }
    
    struct Main: Codable {
        let temp:  Double?
    }
    
    struct Weather: Codable {
        let description:String?
        let icon:String?
    }
    
}
