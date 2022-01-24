//
//  CoreDataController.swift
//  VT
//
//  Created by Nada  on 14/11/2021.
//

import Foundation
import CoreData

class CoreDataController {
    
    static let shared = CoreDataController(modelName: "coreDataController")
    
    let persistentContainer: NSPersistentContainer!
    var backgroundContext:NSManagedObjectContext!
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func configureContexts(){
        backgroundContext = persistentContainer.newBackgroundContext()
        
        backgroundContext.automaticallyMergesChangesFromParent = true
        viewContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            self.configureContexts()
            self.autoSaveViewContext()
            completion?()
        }
    }
}

extension CoreDataController {
    func autoSaveViewContext(interval:TimeInterval = 30){
        
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? self.viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext()
        }
    }
    
    func saveViewContext(){
        try? viewContext.save()
    }
}

