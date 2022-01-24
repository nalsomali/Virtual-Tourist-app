//
//  WeatherVC.swift
//  VT
//
//  Created by Nada  on 22/11/2021.
//
import UIKit
import Foundation

class WeatherVC :UIViewController {
    
    var pin:Pin!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        locationLabel.text = ""
        imageView.image = nil
        temperatureLabel.text = ""
        descriptionLabel.text = ""
        
        
        getWeatherInfo()
    }
    func getWeatherInfo(){
        activityIndicator.startAnimating()
        
       WeatherC.getWeatherInfo(latitude:pin.latitude,longitude: pin.longitude){ (temp ,icon ,location,description ,error) in
            if error == nil {
                //Temperature
                guard temp == temp else {
                    return
                }
                self.temperatureLabel.text = "\(Double(round(1000*(temp! - 273.15)/1000))) ℃"
                //Icon
                guard icon == icon else {
                    return
                }
                 
                let url = URL(string: "https://openweathermap.org/img/wn/\(icon!)@2x.png")
                let imageData = try? Data(contentsOf: url!)
                self.imageView.image = UIImage(data: imageData!)
                
                //Location
                guard let location =  location else{
                    return
                }
                self.locationLabel.text = location
                
                //Weather description
                guard description == description else{
                    return
                }
                self.descriptionLabel.text = description
            }
            else{
                
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
            self.activityIndicator.stopAnimating()
        }
    }
    
     
}







