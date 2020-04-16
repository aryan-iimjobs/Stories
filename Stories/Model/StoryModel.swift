//
//  Story.swift
//  IGStories
//
//  Created by iim jobs on 21/03/20.
//  Copyright © 2020 iim jobs. All rights reserved.
//

import UIKit

public class StoryModel: NSObject, NSCoding {
    var storyId: String
    var storyType: Int
    
    var createdOn: Int
    var expiryOn: Int
    
    var totalViewCount: Int
    var totalClapCount: Int
    var thumbnailPath: String
    
    var s3Path: String
    
    var isSeen: Bool = false
    var isClapped: Bool = false
    
    init(storyId: String, storyType: Int, createdOn: Int, expiryOn: Int, totalViewCount: Int, totalClapCount: Int, thumbnailPath: String, s3Path: String) {
        self.storyId = storyId
        self.storyType = storyType
        self.createdOn = createdOn
        self.expiryOn = expiryOn
        self.totalViewCount = totalViewCount
        self.totalClapCount = totalClapCount
        self.thumbnailPath = thumbnailPath
        self.s3Path = s3Path
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(storyId, forKey: "storyId")
        aCoder.encode(storyType, forKey: "storyType")
        aCoder.encode(createdOn, forKey: "createdOn")
        aCoder.encode(expiryOn, forKey: "expiryOn")
        aCoder.encode(totalViewCount, forKey: "totalViewCount")
        aCoder.encode(totalClapCount, forKey: "totalClapCount")
        aCoder.encode(thumbnailPath, forKey: "thumbnailPath")
        aCoder.encode(s3Path, forKey: "s3Path")
        aCoder.encode(isSeen, forKey: "isSeen")
        aCoder.encode(isClapped, forKey: "isClapped")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let mstoryId = aDecoder.decodeObject(forKey: "storyId") as! String
        let mstoryType = aDecoder.decodeInt64(forKey: "storyType")
        let mcreatedOn = aDecoder.decodeInt64(forKey: "createdOn")
        let mexpiryOn = aDecoder.decodeInt64(forKey: "expiryOn")
        let mtotalViewCount = aDecoder.decodeInt64(forKey: "totalViewCount")
        let mtotalClapCount = aDecoder.decodeInt64(forKey: "totalClapCount")
        let mthumbnailPath = aDecoder.decodeObject(forKey: "thumbnailPath") as! String
        let ms3Path = aDecoder.decodeObject(forKey: "s3Path") as! String
        let misSeen = aDecoder.decodeBool(forKey: "isSeen")
        let misClapped = aDecoder.decodeBool(forKey: "isClapped")
        
        self.init(storyId: mstoryId, storyType: Int(mstoryType), createdOn: Int(mcreatedOn), expiryOn: Int(mexpiryOn), totalViewCount: Int(mtotalViewCount), totalClapCount: Int(mtotalClapCount), thumbnailPath: mthumbnailPath, s3Path: ms3Path)
        self.isSeen = misSeen
        self.isClapped = misClapped
    }
}
