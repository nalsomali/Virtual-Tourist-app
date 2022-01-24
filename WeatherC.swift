//
//  weatherC .swift
//  VT
//
//  Created by Nada  on 22/11/2021.
//

import Foundation

import Foundation
class WeatherC {
    
    class public func getWeatherInfo(latitude: Double, longitude: Double, completion: @escaping (Double?,String?,String?,String?,Error?) -> Void)
    {
        let request = URLRequest(url: URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&APPID=08aad6da751a1891d71b0d3b81189408")!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async{
                completion(nil,nil,nil,nil,error)
                }
                return
            }
            let result = try! JSONDecoder().decode(WeatherR.WeatherIno.self, from: data)
            
            DispatchQueue.main.async{
                completion(result.main?.temp,result.weather?.first?.icon,result.name ,result.weather?.first?.description,nil)
            }
        }
        task.resume()
    }
     
}
