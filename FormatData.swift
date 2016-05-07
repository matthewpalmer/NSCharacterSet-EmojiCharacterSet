// This is a script that reformats the data from https://github.com/iamcal/emoji-data into a single file

let url = NSBundle.mainBundle().URLForResource("emoji", withExtension: "json")!
        let data = NSData(contentsOfURL: url)!
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        guard let array = json as? NSArray else { return }
        
        let unifiedStrings = NSMutableSet()
        
        for entry in array {
            guard let obj = entry as? NSDictionary else { fatalError() }
            
            // unified - The Unicode codepoint, as 4-5 hex digits. Where an emoji needs 2 or more codepoints, they are specified like 1F1EA-1F1F8.
            guard let unified = obj["unified"] as? NSString else { fatalError() }
            unifiedStrings.addObject(unified)
            
            if let variations = obj["variations"] as? NSArray {
                for variation in variations {
                    if let variation = variation as? NSString {
                        unifiedStrings.addObject(variation)
                    }
                }
            }
            
            if let skinVariations = obj["skin_variations"] as? NSDictionary {
                let keys = skinVariations.allKeys
                for key in keys {
                    if let key = key as? NSString,
                        dict = skinVariations[key] as? NSDictionary,
                        skinVariationUnified = dict["unified"] as? NSString {
                        unifiedStrings.addObject(skinVariationUnified)
                    }
                }
            }
        }
        
        let actualStrings = NSMutableSet()
        
        for string in unifiedStrings {
            if let string = string as? NSString {
                let components = string.componentsSeparatedByString("-")
                
                let intComponents: [UInt32] = components.map {
                    let scanner = NSScanner(string: $0)
                    var hexInt: UInt32 = 0
                    scanner.scanHexInt(&hexInt)
                    return hexInt
                }
                
                let unicodeScalars = intComponents.map { UnicodeScalar($0) }
                var str = ""
                unicodeScalars.forEach { str.append($0) }
                actualStrings.addObject(str)
            }
        }
        
        let all = (actualStrings.allObjects as! [String]).joinWithSeparator("")
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = paths.first!
        let file = NSString(string: docsDir).stringByAppendingPathComponent("emoji.txt")
        try! all.writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding)
        print("Saved to \(file)")
