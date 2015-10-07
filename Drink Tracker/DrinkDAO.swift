//
//  DrinkDAO.swift
//  Drink Tracker
//
//  Created by Scott Minter on 3/13/15.
//  Copyright (c) 2015 Scott Minter Designs. All rights reserved.
//

import UIKit
import Foundation
import CoreData


class DrinkDAO: NSObject {
    
    private var EntityName: String = "DrinkEvents"
    private var appDel = AppDelegate()
    private var context = NSManagedObjectContext()
    private var DrinkType = String()
    private var TimeObj = TimeKeeper()
    private var SessionDuration: NSNumber = 3 //hours
    private var SecInDay: NSNumber = 86400
    private var SecInHour: NSNumber = 3600
    
    override init() {
        super.init()
        
    }
    
    init(drinkType: String) {
        super.init()
        
        var dt = String()
        switch drinkType {
            case "beer":
                dt = "beer"
                break
            case "wine":
                dt = "wine"
                break
            case "shot":
                dt = "shot"
                break
            case "mixer":
                dt = "mixer"
                break
            default:
                dt = "beer"
                break
        }
        
        DrinkType = dt
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
    }
    
    /*
     *  Setter for drink type
     */
    func setDrinkType(dt: String) {
        self.DrinkType = dt
    }
    
    /*
     *
     */
    func getDrinkType()->String {
        return self.DrinkType
    }
    
    /*
     *  This saves a drink event
     */
    func saveDrinkEvent(dateDict: Dictionary<String, Any>)->Bool {
        //Get Model for the Drink Event
        let newDrinkEvent: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName(self.EntityName, inManagedObjectContext: self.context) 
        
        //Extract data from Date Dictionary
        let dayAsNsNum: NSNumber = (dateDict["dayAsInt"] != nil ? dateDict["dayAsInt"] : 0)  as! NSNumber
        let dayStr: String = (dateDict["dayOfWeekAsStr"] != nil ? dateDict["dayOfWeekAsStr"] : "") as! String
        let hour: NSNumber = (dateDict["hour"] != nil ? dateDict["hour"] : 0 ) as! NSNumber
        let min: NSNumber = (dateDict["minute"] != nil ? dateDict["minute"] : 0 ) as! NSNumber
        let month: NSNumber = (dateDict["month"] != nil ? dateDict["month"] : 0) as! NSNumber
        let sec: NSNumber = (dateDict["seconds"] != nil ? dateDict["seconds"] : 0) as! NSNumber
        let wkInMonth: NSNumber = (dateDict["weekInMonth"] != nil ? dateDict["weekInMonth"] : 0) as! NSNumber
        let year: NSNumber = (dateDict["year"] != nil ? dateDict["year"] : 0) as! NSNumber
        let unixTime: Double = (dateDict["unixTime"] != nil ? dateDict["unixTime"] : 0.0) as! Double
        
        //Add fields to the Event
        newDrinkEvent.setValue(dayAsNsNum, forKey: "dayAsInt")
        newDrinkEvent.setValue(dayStr, forKey: "dayAsString")
        newDrinkEvent.setValue(self.DrinkType, forKey: "drinkType")
        newDrinkEvent.setValue(hour, forKey: "hour")
        newDrinkEvent.setValue(min, forKey: "minute")
        newDrinkEvent.setValue(month, forKey: "month")
        newDrinkEvent.setValue(sec, forKey: "second")
        newDrinkEvent.setValue(wkInMonth, forKey: "weekInMonth")
        newDrinkEvent.setValue(year, forKey: "year")
        newDrinkEvent.setValue(unixTime, forKey: "unixTime")
        
        //Save the Event
        let err: NSErrorPointer = nil
        do {
            try context.save()
        } catch let error as NSError {
            err.memory = error
        }
        
        if err != nil {
            NSLog("Error Saving Data: \(err)")
            return false
        }
        else {
            //NSLog("Data Save Successful: \(newDrinkEvent)")
            return true
        }
    }
    
    /**
     * Delete most recent event of self type
     */
    func deleteMostRecentEvent() {

        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Build drink type predicate
        let predicate1: NSPredicate = NSPredicate(format: "drinkType == %@", self.DrinkType)
        
        //Add drink type predicate to the request
        request.predicate = predicate1
        
        //Sort Descending
        let sortDesc = NSSortDescriptor(key: "unixTime", ascending: false)
        
        //Add sort descriptors to the request
        request.sortDescriptors = [sortDesc]
        
        let err: NSErrorPointer = nil
        
        //Execute the fetch for results
        let results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
        } catch let error as NSError {
            err.memory = error
            results = nil
        }

        if results?.count > 0 {
            let toDelete: AnyObject = results!.first!
        
            context.deleteObject(toDelete as! NSManagedObject)
        }
    }
    
    /**
     * Returns drink totals for a date span
     */
    func getTotalByDates(startDt start: Dictionary<String, Any>, endDt end: Dictionary<String, Any>)->Int {

        let startUnix: NSNumber = start["unixTime"]! as! NSNumber
        let endUnix: NSNumber = end["unixTime"]! as! NSNumber

        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        var predArr: [NSPredicate] = []
        
        //Build drink type predicate
        let predicate1: NSPredicate = NSPredicate(format: "drinkType == %@", self.DrinkType)
        predArr.append(predicate1)
        
        //Build predicate for all unix greater than start
        let predicate2: NSPredicate = NSPredicate(format: "unixTime >= %@", startUnix)

        predArr.append(predicate2)
        
        //Build predicate for all unix less than end
        let predicate3: NSPredicate = NSPredicate(format: "unixTime <= %@", endUnix)
        predArr.append(predicate3)

        let allPredicates = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: predArr)
        
        //Sorting Description
        let sortDesc = NSSortDescriptor(key: "unixTime", ascending: true)
        
        request.predicate = allPredicates

    
        //Add sort descriptors to the request
        request.sortDescriptors = [sortDesc]

        let err: NSErrorPointer = nil
    
        //Execute the fetch for results
        let results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
        } catch let error as NSError {
            err.memory = error
            results = nil
        }
    
        if results != nil {
            return results!.count
        }
        else {
            NSLog("Error: \(err)")
            return 0
        }
    }
    
    /*
     *  Get all totals based on drink type
     */
    func getAllTimeTotal()->Int {
        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Add drink type predicate
        request.predicate = NSPredicate(format: "drinkType == %@", self.DrinkType)
        
        //Add this line because it helps something bc Rob Percival said so
        request.returnsObjectsAsFaults = false
        
        //Instantiate Error Obj
        let err: NSErrorPointer = nil
        
        //Get results from CoreData
        var results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
        } catch let error as NSError {
            err.memory = error
            results = nil
        }
        
        if err == nil {
            return results!.count
        }
        else {
            NSLog("Error: \(err)")
            return 0
        }
    }
    
    /*
     *  Get the year totals for current year
     */
    func getYearlyTotal()->Int {
        //Get the current date
        var dateDict: Dictionary = TimeObj.getFormattedDate()
        //Get the current year
        let currentYear: NSNumber = ((dateDict["year"] != nil ) ? dateDict["year"] : 0) as! NSNumber

        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        //Build drink type predicate
        let predicate1 = NSPredicate(format: "drinkType == %@", self.DrinkType)
        //Build current year predicate
        let predicate2 = NSPredicate(format: "year == %@", currentYear)
        //Combine Predicates with an AND
        let allPredicates = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate1, predicate2])
        //Add predicates to request
        request.predicate = allPredicates
        
        //Instantiate Error Obj
        let err: NSErrorPointer = nil
        
        //Get results
        var results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
        } catch let error as NSError {
            err.memory = error
            results = nil
        }
        
        if err == nil {
            return results!.count
        }
        else {
            NSLog("Error: \(err)")
            return 0
        }
    }
    
    /*
     *  Get the monthly totals
     */
    func getMonthlyTotal()->Int {
        //Get Current Date
        var dateDict: Dictionary = TimeObj.getFormattedDate()
        
        //Get Current Month
        let currentMonth: NSNumber = ((dateDict["month"] != nil) ? dateDict["month"] : 0) as! NSNumber
        
        //Set Up Request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Build drink type predicate
        let predicate1 = NSPredicate(format: "drinkType == %@", self.DrinkType)
        
        //Build current year predicate
        let predicate2 = NSPredicate(format: "month == %@", currentMonth)
        
        //Combine Predicates with an AND
        let allPredicates = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate1, predicate2])
        
        //Add predicates to request
        request.predicate = allPredicates
        
        //Get Results
        let results = try? context.executeFetchRequest(request)
        
        if results != nil {
            return results!.count
        }
        else {
            return 0
        }
    }
    
    /*
     * Get totals for current week
     */
    func getWeeklyTotal()->Int {
        //Get current time dictionary
        var dateDict: Dictionary<String, Any> = TimeObj.getFormattedDate()
        
        //Current Hour
        let currHour: Int = ((dateDict["hour"] != nil) ? dateDict["hour"] : 0) as! Int

        //Current Minute
        let currMin: Int = ((dateDict["minute"] != nil) ? dateDict["minute"] : 0) as! Int
        
        //Current Second
        let currSec: Int = ((dateDict["seconds"] != nil) ? dateDict["seconds"] : 0) as! Int
        
        //Get current unix time
        let unixTime: NSNumber = ((dateDict["unixTime"] != nil) ? dateDict["unixTime"] : 0.0) as! NSNumber

        //Get the day of the week as an int
        //ex. Wed = 4, Sun = 1 ... etc
        let dayOfWeekAsInt = ((dateDict["dayOfWeekAsInt"] != nil) ? dateDict["dayOfWeekAsInt"] : 1) as! Int
        
        //We need to get all full days as secs plus all secs of today
        let secsInThisDay: Double = TimeObj.getNumberOfSecondsBasedOnTime(currHour, min: currMin, sec: currSec)
        
        //Get number of seconds in previous days of week
        var secsInPriorDaysOfWeek: Double = 0.0
        if dayOfWeekAsInt > 1 {
            secsInPriorDaysOfWeek = Double(SecInDay) * (Double(dayOfWeekAsInt) - 1.0)
        }
        
        //Total Number of Seconds Since Start of Current Week
        let totalSecsSinceBeginningOfWeek: Double = secsInThisDay + secsInPriorDaysOfWeek
        
        //Get Unix Time at Start of Week
        let unixTimeAtStartOfWeek: Double = Double(unixTime) - totalSecsSinceBeginningOfWeek
        
        //Get results from CoreData
        let results: Array<AnyObject> = getDataSinceUnixTime(unixTimeAtStartOfWeek, ignoreType: false)
        
        if results.count > 0 {
            
            return results.count
        }
        else {
            return 0
        }
    }
    
    //TODO: Redo weekly with UnixTime
    //Old version not being called any longer
    func getWeeklyTotal_Old()->Int {
print("\(self.DrinkType): Weekly: Bad")
        //Get Date Dict
        var dateDict: Dictionary = TimeObj.getFormattedDate()

        //Get Day of Week
        let currentDayOfWeek: NSNumber = ((dateDict["dayOfWeekAsInt"] != nil) ? dateDict["dayOfWeekAsInt"] : 0) as! NSNumber
        //Get Day of month
        let currentDayInMonth: NSNumber = ((dateDict["dayAsInt"] != nil) ? dateDict["dayAsInt"] : 0) as! NSNumber
        //Get Month
        let currentMonth: NSNumber = ((dateDict["month"] != nil) ? dateDict["month"] : 0) as! NSNumber
        //Get Year
        let currentYear: NSNumber = ((dateDict["year"] != nil) ? dateDict["year"] : 0) as! NSNumber
        
        //Determine if leap years
        let isLeapYear: Bool = TimeObj.isLeapYear(currentYear as Int)
        
        //Determine Number of days in month
        var numOfDaysInMonth: Int = TimeObj.getNumberOfDaysInMonth(currentMonth as Int, isLeapYear: isLeapYear) as Int
        
        var tempDayInMonth: Int = currentDayInMonth as Int
        
        //TODO: Move this to Time keeper as a method
        
        //Count back to beginning of week
        for var i: Int = currentDayOfWeek as Int; i > 1; i-- {
            tempDayInMonth--
        }
        
        //Month at start of week
        var monthAtStartOfWeek: Int = currentMonth as Int
        //Day in month on Sunday of current week
        var dayInMonthAtStartOfWeek = tempDayInMonth
        //Year at Beginning of Week
        var yearAtStartOfWeek: Int = currentYear as Int
        
        //If this is less than 0 it means we went back a month
        if tempDayInMonth <= 0 {
            //account for beginning of the year
            if monthAtStartOfWeek != 1 {
                monthAtStartOfWeek--
            }
            else {
                monthAtStartOfWeek = 12
                
                //back year off by 1 because it's January
                yearAtStartOfWeek--
            }
            
            let daysInPrevMonth: Int = TimeObj.getNumberOfDaysInMonth(monthAtStartOfWeek, isLeapYear: isLeapYear) as Int
            dayInMonthAtStartOfWeek = daysInPrevMonth + tempDayInMonth
        }
        
        //Set Up Request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Set up predicates
        let predDrinkType = NSPredicate(format: "drinkType == %@", self.DrinkType)
        let predMonth = NSPredicate(format: "month >= %@", monthAtStartOfWeek as NSNumber)
        let predDay = NSPredicate(format: "dayAsInt >= %@", dayInMonthAtStartOfWeek as NSNumber)
        let predYear = NSPredicate(format: "year >= %@", yearAtStartOfWeek as NSNumber)
        let allPreds = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predDrinkType, predMonth, predDay, predYear])
        
        request.predicate = allPreds

        //Get Results
        let results = try? context.executeFetchRequest(request)
        
        if results != nil {
            return results!.count
        }
        else {
            return 0
        }
    }
    
    /*
     *  Get the daily totals
     */
    func getDailyTotal()->Int {
        //Get formatted date dictionary
        var dateDict: Dictionary = TimeObj.getFormattedDate()
        
        let currDay: NSNumber = ((dateDict["dayAsInt"] != nil) ? dateDict["dayAsInt"]! : 0) as! NSNumber
        let currMonth: NSNumber = ((dateDict["month"] != nil) ? dateDict["month"]! : 0) as! NSNumber
        let currYear: NSNumber = ((dateDict["year"] != nil) ? dateDict["year"]! : 0) as! NSNumber
        
        let request = NSFetchRequest(entityName: self.EntityName)
        
        let predDrinkType = NSPredicate(format: "drinkType == %@", self.DrinkType)
        let predDay = NSPredicate(format: "dayAsInt == %@", currDay)
        let predMonth = NSPredicate(format: "month == %@", currMonth)
        let predYear = NSPredicate(format: "year == %@", currYear)
        let allPreds = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predDrinkType, predDay, predMonth, predYear])
        
        request.predicate = allPreds
        
        let results = try? context.executeFetchRequest(request)
        
        if results != nil {
            return results!.count
        }
        else {
            return 0
        }
    }
    
    /*
     *  Gets the total results for the current session
     */
    func getSessionTotal()->Int {
        //Get formatted date
        var dateDict: Dictionary = TimeObj.getFormattedDate()
        
        //Grab current unix time from dateDict
        let currUnixTime: NSNumber = ((dateDict["unixTime"] != nil) ? dateDict["unixTime"] : 0.0) as! NSNumber

        //Get start of current session unix time
        let sessStart: NSNumber = getStartUnixTimeOfSession(currUnixTime)

        //Get initial results since start of session IGNORE TYPE
        var results: Array<AnyObject> = getDataSinceUnixTime(sessStart, ignoreType: true)

        //If no results then we return 0
        if results.count > 0 {
            
            //Set total results count from initial run
            var totalResults: Int = results.count

            var earliestFoundTimeForAllDrinks = NSNumber()
            var stopLoop: Bool = false
            while stopLoop == false {

                //We need the earliest drink event from the first result set
                let earliestTime: Double = results[0].valueForKey("unixTime") as! Double
                
                //Then we need the session start of that event
                let newSessionStart: NSNumber = getStartUnixTimeOfSession(earliestTime)
                
                //Then we need the results set since this new session start time INGORE TYPE
                results = getDataSinceUnixTime(newSessionStart, ignoreType: true)
                
                //If this is true then that means we didn't get any new results and
                //we have our session total
                if results.count == totalResults {
                    earliestFoundTimeForAllDrinks = results[0].valueForKey("unixTime") as! NSNumber
                    stopLoop = true
                }
                else {
                    totalResults = results.count
                }
            }
print("earliest time for session: \(earliestFoundTimeForAllDrinks)")
            //Use the earliest time in the session while ignoring drink type to find the drink type specific count since that time
            let drinkTypeSpecificResults: Array<AnyObject> = getDataSinceUnixTime(earliestFoundTimeForAllDrinks, ignoreType: false)
            
            if drinkTypeSpecificResults.count > 0 {
                let drinkTypeTotal: Int = drinkTypeSpecificResults.count
print("type totals: \(drinkTypeTotal)")
                return drinkTypeTotal
            }
            else {
                return 0
            }
        }
        else {
            return 0
        }
    }
    
    /**
     *  Get totals from last session
     */
    func getLastSessionTotal()->Int {
        //Get time of
        
        //empty results
        var results = [AnyObject]?()
        
        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Get first result
        request.fetchLimit = 1
        
        //Sort by unixTime: most recent first
        let sortDesc = NSSortDescriptor(key: "unixTime", ascending: false)
        
        //Add sorting description
        request.sortDescriptors = [sortDesc]
        
        //Execute the fetch for results
        results = try? context.executeFetchRequest(request)
        
        //This is getting the most recent entry
        var totals: Int = 0
        var mostRecentEntry = NSNumber()
        if results != nil && results!.count > 0 {
            if results![0].valueForKey("unixTime") != nil {
                mostRecentEntry = results![0].valueForKey("unixTime")! as! NSNumber
            }
            
            //Get totals of last session
            totals = getSessionTotalsSinceUnixTime(mostRecentEntry) as Int
        }
        
        return totals
    }
    
    func getSessionTotalsSinceUnixTime(unixTime: NSNumber)->Int {
        
        //Get initial results since start of session IGNORE TYPE
        var results: Array<AnyObject> = getDataSinceUnixTime(unixTime, ignoreType: true)
        
        //If no results then we return 0
        if results.count > 0 {
            
            //Set total results count from initial run
            var totalResults: Int = results.count
            
            var earliestFoundTimeForAllDrinks = NSNumber()
            var stopLoop: Bool = false
            while stopLoop == false {
                
                //We need the earliest drink event from the first result set
                let earliestTime: Double = results[0].valueForKey("unixTime") as! Double
                
                //Then we need the session start of that event
                let newSessionStart: NSNumber = getStartUnixTimeOfSession(earliestTime)
                
                //Then we need the results set since this new session start time INGORE TYPE
                results = getDataSinceUnixTime(newSessionStart, ignoreType: true)
                
                //If this is true then that means we didn't get any new results and
                //we have our session total
                if results.count == totalResults {
                    earliestFoundTimeForAllDrinks = results[0].valueForKey("unixTime") as! NSNumber
                    stopLoop = true
                }
                else {
                    totalResults = results.count
                }
            }
            
            //Use the earliest time in the session while ignoring drink type to find the drink type specific count since that time
            let drinkTypeSpecificResults: Array<AnyObject> = getDataSinceUnixTime(earliestFoundTimeForAllDrinks, ignoreType: false)
            
            if drinkTypeSpecificResults.count > 0 {
                return drinkTypeSpecificResults.count
            }
            else {
                return 0
            }
        }
        else {
            return 0
        }
    }

    /*
     *  Gets data since a given unix time
     */
    func getDataSinceUnixTime(unixTime: NSNumber, ignoreType: Bool)->Array<AnyObject> {
        //Remove 1 second from unix time to give buffer
        let unixTimeMinusOneSec: Double = Double(unixTime) - 1.0
        
        //empty results
        var results = [AnyObject]?()
        
        //Set up request
        let request = NSFetchRequest(entityName: self.EntityName)
        
        //Drink Type Predicate
        var drinkTypePred = NSPredicate() //format: "drinkType == %@", self.DrinkType)
        if ignoreType == false {
            drinkTypePred = NSPredicate(format: "drinkType == %@", self.DrinkType)
        }
        
        //Session Predicate
        let sessPred = NSPredicate(format: "unixTime >= %@", unixTimeMinusOneSec as NSNumber)
        
        //Sorting Description
        let sortDesc = NSSortDescriptor(key: "unixTime", ascending: true)
        
        //Combine the Predicates into 1
        var allPreds = NSCompoundPredicate()
        if ignoreType == false {
            allPreds = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [drinkTypePred, sessPred])
        }

        //Add predicates to the request
        if ignoreType == false {
            request.predicate = allPreds
        }
        else {
            request.predicate = sessPred
        }

        //Add sort descriptors to the request
        request.sortDescriptors = [sortDesc]
        
        //Execute the fetch for results
        results = try? context.executeFetchRequest(request)

        return results!
    }
    
    /*
     *  Returns the start of a session based on a unix time stamp
     */
    func getStartUnixTimeOfSession(unixTime: NSNumber)-> NSNumber {
        var startAsDbl: Double = 0.0
        let ut: Double = unixTime as Double
        let sessAsDouble: Double = SessionDuration as Double
        let secsInHrAsDbl: Double = SecInHour as Double
        
        startAsDbl = ut - (sessAsDouble * secsInHrAsDbl)
        
        return startAsDbl as NSNumber
    }
}