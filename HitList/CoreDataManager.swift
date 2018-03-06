//
//  CoreDataManager.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/27/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    static let shared = CoreDataManager()
    // MARK: - My Methods

    func getUserWith(login: String) -> User? {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "login == %@", login)

        do {
            let users = try managedContext.fetch(fetchRequest)
            //check
            if users.count > 1 { fatalError("Multiple users with same login.") }
            return users.first
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }

    func saveNewUser(login: String, email: String, password: String){
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        let userContext = User(context: managedContext)
        userContext.login = login
        userContext.email = email
        userContext.password = password
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func saveNewLetter(from: User, to: User, message: String, date: Date ) {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        
        let letterContext = Letter(context: managedContext)
        letterContext.from = from
        letterContext.to = to
        letterContext.message = message
        letterContext.date = date
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func validateUser(login: String, password: String) -> User?{
        if let user = getUserWith(login: login){
            if user.password == password {
                return user
            }
            return nil
        }
        return nil
    }
    
    func getFetchResultsControllerWithUserMessages(user1: User, user2: User) -> NSFetchedResultsController<Letter>{
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        
        let request: NSFetchRequest<Letter> = Letter.fetchRequest()
        request.predicate = NSPredicate(format: "(to == %@ AND from == %@) OR (to == %@ AND from == %@)", user1, user2, user2, user1)
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [dateSort]
        let moc = managedContext
        
        let fetchedResultsController = NSFetchedResultsController<Letter>(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
        
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "HitList")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
