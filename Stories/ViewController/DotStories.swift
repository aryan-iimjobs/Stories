//
//  DotStories.swift
//  Stories
//
//  Created by iim jobs on 11/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//
import UIKit
import Alamofire
import SwiftyJSON
import CoreData

class DotStories: UIView {
    
    let minimumLineSpacingForSection: CGFloat = 10.0 //right space between cells
    let numberOfCellsInView: CGFloat = 5.1 //cells visible at startup
    let numberOfFullVisibleCells:CGFloat = 5 // fully visible cells at startup
    
    var parentVC: HomeVC!
    var getDataUrl: String = ""
    
    var managedObjectContext: NSManagedObjectContext?
    var arrayCompanies: [CompanyModel] = []
    
    let cellReuseIdentifier = "CompanyIconCell"
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout();
        layout.scrollDirection = .horizontal;
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout);
        cv.register(CompanyIconCell.self, forCellWithReuseIdentifier: "CompanyIconCell")
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .white
        return cv;
    }();
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func initializeStories(parentVC: HomeVC) {
        self.parentVC = parentVC
        self.getDataUrl = "https://angel.hirist.com/api7/stories?en_cookie=YfQPsWVCWD2_PLUS_jMqXVYtI1IBJJNpBjdt5LAXzVToFgzdfmcpNVboBZoOb9cHPfl6nO9a59AvIZNir00EB26b0aA_EQUALS__EQUALS_&debug=1"
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedObjectContext = appDelegate.persistentContainer.viewContext
        
        //get data from API
        requestData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        addSubview(collectionView)
        collectionView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        collectionView.delegate = self
        collectionView.dataSource = self

        //handel moving to background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
           print("MainVC: vc moved to background")
           saveToCoreData(companies: self.arrayCompanies)
       }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Helper Methods
    func requestData() {
        AF.request(self.getDataUrl).responseJSON { response in
            switch response.result {
            case .success:
                if response.data != nil {
                    do {
                        let json = try JSON(data: response.data!)
                        if(json["success"].int! == 1) {
                            if let companyArray = json["companyStories"].array {
                                for company in companyArray {
                                    
                                    let storiesObjArray: [StoryModel] = self.getParsedStoriesObjArray(company: company)
                                    
                                    
                                    let showcaseDetailObj: ShowCaseModel = self.getParsedShowcaseDetailObj(company: company)

                                    let companyObj = CompanyModel(companyName: company["companyName"].string!,
                                                           companyId: company["companyId"].int!,
                                                           storyCompanyId: company["storyCompanyId"].string!,
                                                           storyCount: company["storyCount"].int!,
                                                           storyUpdatedOn: company["storyUpdatedOn"].int!,
                                                           stories: storiesObjArray,
                                                           companyLogo: company["companyLogo"].string!,
                                                           showcaseDetail: showcaseDetailObj)
                                    self.arrayCompanies.append(companyObj)
                                }
                                
                                self.prepareArrayCompanies()
                                
                                self.sortAndAppendSeenCompany()
                                
                                self.saveToCoreData(companies: self.arrayCompanies)
                                
                                self.removeExpiredCacheData() // remove expired story's cached data from directory
                                
                                print("MainVC: number of companies = \(companyArray.count)")
                            }
                        } else {
                            print("MainVC: fetchData error - success != 1")
                            self.arrayCompanies = self.getFromCoreData()
                        }
                    } catch {
                        print("MainVC: Error parsing fetched json")
                        self.arrayCompanies = self.getFromCoreData()
                    }
                }
            case let .failure(error):
                print("MainVC: AF error = \(error)")
                self.arrayCompanies = self.getFromCoreData()
            }
            self.collectionView.reloadData()
        }
    }
    
    func getParsedStoriesObjArray(company: JSON) -> [StoryModel] {
        var storiesObjArray: [StoryModel] = []
        if let storiesArray = company["stories"].array {
            for story in storiesArray {
                let obj = StoryModel(storyId: story["storyId"].string!,
                                   storyType: story["storyType"].int!,
                                   createdOn: story["createdOn"].int!,
                                   expiryOn: story["expiryOn"].int!,
                                   totalViewCount: story["totalViewCount"].int!,
                                   totalClapCount: story["totalClapCount"].int!,
                                   thumbnailPath: story["thumbnailPath"].string!,
                                   s3Path: story["s3Path"].string!)
                storiesObjArray.append(obj)
            }
        }
        return storiesObjArray
    }
    
    func getParsedShowcaseDetailObj(company: JSON) -> ShowCaseModel {
        var showcaseDetailObj: ShowCaseModel?
        
        if company["showcaseDetail"].exists() {
            let showcaseDetail = company["showcaseDetail"]
            showcaseDetailObj = ShowCaseModel(v2companyId: showcaseDetail["v2companyId"].string!,
            v2bannerUrl: showcaseDetail["v2bannerUrl"].string!,
            v2jsonFilePath: showcaseDetail["v2jsonFilePath"].string!,
            v2templateType: showcaseDetail["v2templateType"].string!,
            v2showcaseId: showcaseDetail["v2showcaseId"].string!,
            v2companyName: showcaseDetail["v2companyName"].string!,
            v2bannerBtnTxt: showcaseDetail["v2bannerBtnTxt"].string!)
        }
        
        if showcaseDetailObj == nil {
            showcaseDetailObj = ShowCaseModel(v2companyId: "", v2bannerUrl: "", v2jsonFilePath: "", v2templateType: "", v2showcaseId: "", v2companyName: "", v2bannerBtnTxt: "")
        }
        
        return showcaseDetailObj!
    }
    
    func prepareArrayCompanies() {
        //sort stories based on created date
        for company in self.arrayCompanies {
            company.stories.sort { $0.createdOn > $1.createdOn }
        }
        self.arrayCompanies.sort {
            $0.stories[0].createdOn > $1.stories[0].createdOn
        }
        
        print("array count \(arrayCompanies.count)")
        
        //add seen info into new arrayCompanies
        for company in self.getFromCoreData() {
            for newCompany in self.arrayCompanies {
                if newCompany.companyId == company.companyId {
                    for story in company.stories {
                        for newStory in newCompany.stories {
                            if newStory.storyId == story.storyId {
                                newStory.isSeen = story.isSeen
                                newStory.isClapped = story.isClapped
                                break
                            }
                        }
                    }
                    break
                }
            }
        }
    }
    
    func sortAndAppendSeenCompany() {
        var seenCompanyArray: [CompanyModel] = []
        var unSeenCompanyArray: [CompanyModel] = []
        
        for company in self.arrayCompanies {
            var allSeen = true
            for story in company.stories {
                if !story.isSeen {
                    allSeen = false
                    break
                }
            }
            if allSeen {
                seenCompanyArray.append(company)
            } else {
                unSeenCompanyArray.append(company)
            }
        }
        
        seenCompanyArray.sort {$0.stories[0].createdOn > $1.stories[0].createdOn}
        
        for company in seenCompanyArray {
            unSeenCompanyArray.append(company)
        }
        
        self.arrayCompanies = unSeenCompanyArray
    }
    
    func removeExpiredCacheData() {
        var arrayStoryIds: [String] = []
        for stories in arrayCompanies {
            for story in stories.stories {
                arrayStoryIds.append(story.storyId)
            }
        }
        
        let presentItems = listItems()
        
        for item in arrayStoryIds {
            if presentItems.contains(where: {$0 == item}) {
            } else {
                removeLocalPath(localPathName: item)
            }
        }
    }
    
    func isStoriesSeen(indexPath: IndexPath) -> Bool {
        //check if all stories are seen in a company
        var allSeenFlag = true
        for snap in arrayCompanies[indexPath.item].stories {
            if !snap.isSeen {
                allSeenFlag = false
                break
            }
        }
        return allSeenFlag
    }
}

//MARK:- CollectionView DataSource
extension DotStories: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        arrayCompanies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CompanyIconCell

        cell.icon.layer.borderColor = isStoriesSeen(indexPath: indexPath) ? UIColor.gray.cgColor : UIColor(displayP3Red: 20/255, green: 144/255, blue: 117/255, alpha: 1).cgColor // green
        cell.icon.layer.borderWidth = isStoriesSeen(indexPath: indexPath) ? 0 : 1
        
        cell.companyId = arrayCompanies[indexPath.item].storyCompanyId
        cell.companyTitle.text = arrayCompanies[indexPath.item].companyName
        
        //get images
        cell.getImage(address: arrayCompanies[indexPath.item].companyLogo)
        
        return cell
    }
}

//MARK:- CollectionView Delegate
extension DotStories: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = StoryVC(arrayCompanies: arrayCompanies, selectedStoryIndex: indexPath.item)
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        parentVC.isDarkStatusBar.toggle()
        parentVC.present(vc, animated: true, completion: nil)
    }
}

extension DotStories: StoryVCProtocol {
    func reloadIconCollectionView(arrayCompanies: [CompanyModel]) {
        self.arrayCompanies = arrayCompanies
        self.collectionView.layoutIfNeeded()
        self.collectionView.reloadData()
    }
}

//MARK:- CollectionView FlowLayout Delegate
extension DotStories: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spaceForCells = (self.collectionView.frame.width - (self.minimumLineSpacingForSection * self.numberOfFullVisibleCells))
        let spaceForCellsWithInsets = spaceForCells - 10 // left inset
        let widthOfCell = spaceForCellsWithInsets / self.numberOfCellsInView
        return CGSize(width:  widthOfCell, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.minimumLineSpacingForSection
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
}

//MARK:- CoreData
extension DotStories {
    func saveToCoreData(companies objectArray: [CompanyModel]) {
        
        purgeCoreData()
        
        for object in objectArray {
            let entity = NSEntityDescription.entity(forEntityName: "Company", in: managedObjectContext!)!
            let company = NSManagedObject(entity: entity, insertInto: managedObjectContext!)
            company.setValue(object, forKey: "company")
            do {
                try managedObjectContext?.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        print("MainVC: saved into coreData")
    }
    
    func getFromCoreData() -> [CompanyModel] {
        print("MainVC: fetch from core data started")
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Company")
        var arrayCompanies: [CompanyModel] = []
        do {
            let result = try managedObjectContext!.fetch(fetchRequest)
            print("MainVC: fetching from core data, size = \(result.count)")
            for obj in result {
                let companyObj = obj.value(forKey: "company") as! CompanyModel
                arrayCompanies.append(companyObj)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return arrayCompanies
    }
    
    func purgeCoreData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managedObjectContext!.executeAndMergeChanges(using: batchDeleteRequest)
        } catch let error as NSError {
            print("Could not purge. \(error), \(error.userInfo)")
        }
    }
}

extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}

//MARK:- operations on cachesDirectory
extension DotStories {
    func listItems() -> [String] {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentDirectory = paths[0]
        
        if let allItems = try? FileManager.default.contentsOfDirectory(atPath:
            documentDirectory) {
            return allItems
        }
        return [""]
    }
    
    func removeLocalPath(localPathName:String) {
        let filemanager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0] as NSString
        let destinationPath = documentsPath.appendingPathComponent(localPathName)
        if FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try filemanager.removeItem(atPath: destinationPath)
                print("Local path removed successfully")
            } catch let error as NSError {
                print("------Error",error.debugDescription)
            }
        }
    }
}

////get data
//let shared = IJModel()
//var cookie = ""
//if shared.loggedInUser.cookie != nil {
//    cookie = shared.loggedInUser.cookie
//}
//self.getDataUrl = "https://angel.iimjobs.com/api7/stories?en_cookie=\(cookie)&debug=1"

////clap
//let shared = IJModel()
//var cookie = ""
//if shared.loggedInUser.cookie != nil {
//    cookie = shared.loggedInUser.cookie
//}
//
//let parameters = [
//    "en_cookie": "\(cookie)",
//    "payload": "[{\"storyId\":\"\(self.stories[currentSnap].storyId)\",\"count\":\"\(clapNumber)\"}]"
//]


//let shared = IJModel()
//var cookie = ""
//if shared.loggedInUser.cookie != nil {
//    cookie = shared.loggedInUser.cookie
//}
//
//let parameters = [
//    "en_cookie": "\(cookie)",
//    "blockCompany": "\(self.arrayCompanies[self.currentStoryIndex].companyId)"
//]
