//
//  ViewController.swift
//  VT
//
//  Created by Nada  on 14/11/2021.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    var isEditingEnabled = false
    
    @IBOutlet weak var EditButton: UIBarButtonItem!
    
    @IBOutlet weak var SegControl: UISegmentedControl!
    
    
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    // MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        setupMapView()
        
    }
    // MARK:- Setup Fetched Results Controller
    func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        
    }
    // MARK:- Setup Map View
    func setupMapView() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTapped(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.delegate = self
        
        if let region = getMapRegion(){
            
            mapView.setRegion(region, animated: true)
            
        }
        if let pins = fetchedResultsController.fetchedObjects {
            createAnnotations(pins)
            
        }
        
        
        
        
    }
    // MARK:- Handle Long Tap Gesture
    @objc func longTapped(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            
            let location = gestureRecognizer.location(in:mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom:mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            mapView.setCenter(mapView.centerCoordinate, animated: true)
            
            let pin = Pin(context: CoreDataController.shared.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            
            CoreDataController.shared.saveViewContext()
            try? fetchedResultsController.performFetch()
        }
        
    }
    
    // MARK: - Map Region
    func setupMapRegion(region:MKCoordinateRegion?){
        if let region = region {
            let userRegion = ["latitude":region.center.latitude ,
                              "longitude":region.center.longitude,
                              "latitudeDelta":region.span.latitudeDelta,
                              "longitudeDelta":region.span.longitudeDelta]
            UserDefaults.standard.set(userRegion,forKey:"userRegion")
            
        }
        
    }
    func getMapRegion()->MKCoordinateRegion?{
        if let userRegion  =  UserDefaults.standard.dictionary(forKey: "userRegion"){
            let centerCoordinate = CLLocationCoordinate2D(latitude: userRegion ["latitude"] as! CLLocationDegrees ,longitude: userRegion["longitude"] as! CLLocationDegrees )
            let spanCoordinate = MKCoordinateSpan(latitudeDelta: userRegion ["latitudeDelta"] as! CLLocationDegrees , longitudeDelta: userRegion["longitudeDelta"] as! CLLocationDegrees )
            return MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
            
        }
        else {
            return nil
        }
        
        
    }
    
    // MARK:- Map Annotations
    func createAnnotations(_ pins: [Pin]){
        var annotations = [MKAnnotation]()
        for pin in pins {
            
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
            
            
        }
        mapView.addAnnotations(annotations)
    }
    
    
    @IBAction func segControlTapped(segment: UISegmentedControl){
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
        @IBAction func editButtonTapped(_ sender: Any) {
            isEditingEnabled = !isEditingEnabled
            if isEditingEnabled == true {
                changeNavTitle(navTitle: "Select a pin to delete", title: "Done", color: UIColor.blue)
            }
            else {
                changeNavTitle(navTitle: "Virtual Tourist", title: "Edit", color: UIColor.black)
                
            }
        }
        func changeNavTitle(navTitle: String, title: String, color: UIColor ){
            EditButton.title  = title
            navigationItem.title = navTitle
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:color]
            
        }
}

extension MapVC :MKMapViewDelegate {
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
    internal func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let photoAlbumVC : ImgVC
        photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "ImgVC") as! ImgVC
        
        
        mapView.deselectAnnotation(view.annotation!, animated: false)
        if let pins = fetchedResultsController.fetchedObjects {
            
            
            if isEditingEnabled{
                
                //https://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
                let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
                let epsilon = 0.000000001;
                let coordinate = view.annotation!.coordinate
                let fetchPredicate = NSPredicate(format: "latitude > %lf AND latitude < %lf AND longitude > %lf AND longitude < %lf",
                                                 coordinate.latitude - epsilon,  coordinate.latitude + epsilon,
                                                 coordinate.longitude - epsilon, coordinate.longitude + epsilon)
                fetchRequest.predicate = fetchPredicate
                do {
                    let pins = try CoreDataController.shared.viewContext.fetch(fetchRequest)
                    
                    for pin in pins {
                        CoreDataController.shared.viewContext.delete(pin)
                        CoreDataController.shared.saveViewContext()
                    }
                    mapView.removeAnnotation(view.annotation!)
                    CoreDataController.shared.saveViewContext()
                } catch {
                    fatalError("The fetch could not be performed: \(error.localizedDescription)")
                }
            }
            else {
                for pin in pins {
                    if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                        photoAlbumVC.pin = pin
                        photoAlbumVC.SegControl = SegControl
                        photoAlbumVC.segControl(segment: SegControl)
                        navigationController!.pushViewController(photoAlbumVC, animated: true)
                        
                    }
                }
            }
        }
        
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setupMapRegion(region: mapView.region)
    }
}

