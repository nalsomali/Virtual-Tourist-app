//
//  ImgVC .swift
//  VT
//
//  Created by Nada  on 14/11/2021.
//

import UIKit
import MapKit
import CoreData

class ImgVC : UIViewController {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activtyIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var SegControl: UISegmentedControl!
     
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    var pin:Pin!
    var urls = [URL]()
    
    
    
    var insert : [IndexPath]!
    var delete : [IndexPath]!
    var update : [IndexPath]!
    
    
    // MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        label.isHidden = true
        setupFetchedResultsController()
        setupMapView()
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            getFlickrPhotos()
        }
        
    }
    
    
    // MARK:- Setup Map View
    func setupMapView() {
        
        var annotations = [MKAnnotation]()
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        annotations.append(annotation)
        
        mapView.addAnnotations(annotations)
        
        
        let centerCoordinate =  CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.latitude)
        
        let spanCoordinate = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        mapView.region =  MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
        
        mapView.showAnnotations(annotations, animated: false)
        
    }
    
    // MARK:- Setup Fetched Results Controller
    func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK:- Get Flickr Photos
    func getFlickrPhotos() {
        
        FlickrClient.getSearchForPhotos(latitude: pin.latitude, longitude: pin.longitude) { photos, error in
            if let error =  error {
                
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
            else {
                if photos.count != 0 {
                    for photo in photos {
                        if photo.url != nil {
                            self.urls.append(URL(string:photo.url!)!)
                            
                        }
                    }
                    if((self.fetchedResultsController.fetchedObjects?.isEmpty)!) {
                        for url in self.urls {
                            self.downloadPhotos(url)
                        }
                    }
                    
                }
                
            }
            self.collectionView.reloadData()
        }
    }
    // MARK:- Add Photos
    func addPhotos(data: Data) {
        let photo = Photo(context: CoreDataController.shared.viewContext)
        photo.imageData = data
        photo.pin = pin
        CoreDataController.shared.saveViewContext()
    }
    // MARK:- Download Photos
    private func downloadPhotos(_ url: URL) {
        label.isHidden = false
       
        FlickrClient.downloadImage(url: url) { data, error in
            
            if let data = data {
                self.addPhotos(data:data)
            }
            self.label.isHidden = true
             
        }
    }
    // MARK:- New Collection Tapped
    @IBAction func newCollectionTapped(_ sender: Any) {
        if let  photosToDelete = fetchedResultsController.fetchedObjects{
            for photo in photosToDelete{
                CoreDataController.shared.viewContext.delete(photo)
            }
            CoreDataController.shared.saveViewContext()
            getFlickrPhotos()
            
            
        }
    }
    
    // MARK:- segmentControl
    func segControl(segment: UISegmentedControl){
        switch segment.selectedSegmentIndex {
        case 0:
            overrideUserInterfaceStyle = .light
        case 1:
            overrideUserInterfaceStyle = .dark
        case 2:
            overrideUserInterfaceStyle = .unspecified
        default:
            break
            
        }
        
    }
    // MARK:- weatherTapped
    @IBAction func weatherTapped(_ sender: Any) {
        performSegue(withIdentifier: "WeatherViewController", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WeatherViewController" {
            let WeatherVC = segue.destination as! WeatherVC
            WeatherVC.pin = pin
            
        }
    }
    

 
}


extension ImgVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .red
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}


extension ImgVC: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insert = [IndexPath]()
        delete = [IndexPath]()
        update = [IndexPath]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { collectionView.performBatchUpdates({() -> Void in
        
        for indexPath in self.insert {
            self.collectionView.insertItems(at: [indexPath])
        }
        for indexPath in self.delete {
            self.collectionView.deleteItems(at: [indexPath])
        }
        for indexPath in self.update {
            self.collectionView.reloadItems(at: [indexPath])
        }
    }, completion: nil)
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            collectionView.insertSections(sectionIndexSet)
            
        case .delete:
            collectionView.insertSections(sectionIndexSet)
            
            
        default:
            break
            
        }
    }
    
}

extension ImgVC: UICollectionViewDelegate, UICollectionViewDataSource{
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: (view.frame.size.width - (2 * 3)) / 3.0, height: (view.frame.size.width - (2 * 3)) / 3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
                            collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets{
      return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImgCell", for: indexPath) as!  ImgCell
        
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        
        if let image =  photo.imageData  {
            
            cell.imageView.image = UIImage(data: image)
        }
        
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photosToDelete = fetchedResultsController.object(at: indexPath)
        
        CoreDataController.shared.viewContext.delete(photosToDelete)
        CoreDataController.shared.saveViewContext()
    }
}

