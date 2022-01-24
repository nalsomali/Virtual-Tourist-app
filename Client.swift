//
//  Client.swift
//  VT
//
//  Created by Nada  on 14/11/2021.
//

 import Foundation

class FlickrClient {
    static let apiKey = "f93f14f806183c218d652c3d7781b7fa"
    static let base = "https://www.flickr.com/services/rest/?method="
    
    enum EndPoint{
        
        case searchForPhotos(latitude:Double , longitude:Double)
        
        var stringValue:String {
            switch self {
            
            case let.searchForPhotos(latitude: latitude, longitude: longitude):
                return base + "flickr.photos.search&api_key=\(apiKey)&privacy_filter=1&media=photo&lat=\(latitude)&lon=\(longitude)&extras=url_m&per_page=15&page=\(Int.random(in: 1..<10))&format=json&nojsoncallback=1"
            }
            
        }
        var url:URL {
            return URL(string: stringValue)!
        }
        
        
    }
    
    class func getSearchForPhotos(latitude:Double ,longitude:Double,completion : @escaping ([Response],Error?)-> Void ) {
        taskForGETRequest(url: EndPoint.searchForPhotos(latitude: latitude, longitude: longitude).url, responseType: ImgSearch.self) { response , error in
            
            guard let response = response else {
                completion([],error)
                return
                
            }
            completion(response.photos.photo,nil)
        }
    }
    
    class func taskForGETRequest<ResponseType:Codable>(url: URL,responseType:ResponseType.Type,completion : @escaping (ResponseType?,Error?)-> Void ) {
        let task = URLSession.shared.dataTask(with: url){data,response,error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil , error)
                }
                return
            }
            print(String(data: data, encoding: .utf8)!)
            
            let decoder = JSONDecoder()
            do {
                
                let response = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response , nil)
                }
            }
            catch{
                
                DispatchQueue.main.async {
                    completion(nil , error)
                    
                }
            }
            
        }
        task.resume()
        
    }
    
    class func downloadImage(url: URL, completion: @escaping(Data?, Error?) -> Void ){
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data,nil)
            }
        }
        task.resume()
    }
}
