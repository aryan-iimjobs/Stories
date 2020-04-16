//
//  CompanyModel.swift
//  IGStories
//
//  Created by iim jobs on 21/03/20.
//  Copyright © 2020 iim jobs. All rights reserved.
//

import Foundation

public class CompanyModel: NSObject, NSCoding {
    var companyName: String
    var companyId: Int
    var storyCompanyId: String
    
    var storyCount: Int
    var storyUpdatedOn: Int
    var stories: [StoryModel]
    
    var companyLogo: String
    
    var showcaseDetail: ShowCaseModel
    
    enum Key:String { // not used right now
        case companyName = "companyName"
        case companyId = "companyId"
        case storyCompanyId = "storyCompanyId"
        case storyCount = "storyCount"
        case storyUpdatedOn = "storyUpdatedOn"
        case stories = "stories"
        case companyLogo = "CompanyLogo"
    }
    
    init(companyName: String, companyId: Int, storyCompanyId: String ,storyCount: Int, storyUpdatedOn: Int, stories: [StoryModel], companyLogo: String, showcaseDetail: ShowCaseModel) {
        self.companyName = companyName
        self.companyId = companyId
        self.storyCompanyId = storyCompanyId
        self.storyCount = storyCount
        self.storyUpdatedOn = storyUpdatedOn
        self.stories = stories
        self.companyLogo = companyLogo
        self.showcaseDetail = showcaseDetail
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(companyName, forKey: "companyName")
        aCoder.encode(self.companyId, forKey: "companyId")
        aCoder.encode(storyCompanyId, forKey: "storyCompanyId")
        aCoder.encode(storyCount, forKey: "storyCount")
        aCoder.encode(storyUpdatedOn, forKey: "storyUpdatedOn")
        aCoder.encode(stories, forKey: "stories")
        aCoder.encode(companyLogo, forKey: "companyLogo")
        aCoder.encode(showcaseDetail, forKey: "showcaseDetail")
    }
       
    public required convenience init?(coder aDecoder: NSCoder) {
        let mcompanyName = aDecoder.decodeObject(forKey: "companyName") as! String
        let mcompanyId = aDecoder.decodeInt64(forKey: "companyId")
        let mstoryCompanyId = aDecoder.decodeObject(forKey: "storyCompanyId") as! String
        let mstoryCount = aDecoder.decodeInt64(forKey: "storyCount")
        let mstoryUpdatedOn = aDecoder.decodeInt64(forKey: "storyUpatedOn")
        let mstories = aDecoder.decodeObject(forKey: "stories") as! [StoryModel]
        let mcompanyLogo = aDecoder.decodeObject(forKey: "companyLogo") as! String
        let mshowcaseDetail = aDecoder.decodeObject(forKey: "showcaseDetail") as! ShowCaseModel
        
        self.init(companyName: mcompanyName, companyId: Int(mcompanyId), storyCompanyId: mstoryCompanyId ,storyCount: Int(mstoryCount), storyUpdatedOn: Int(mstoryUpdatedOn), stories: mstories, companyLogo: mcompanyLogo, showcaseDetail: mshowcaseDetail)
    }
}
