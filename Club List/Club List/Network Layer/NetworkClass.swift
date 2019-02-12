//
//  NetworkClass.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit

public class NetworkClass: NSObject {

    var session: URLSession!
    var cache:NSCache<AnyObject, AnyObject>!
    static let sharedInstance = NetworkClass()

   class func fetchCompanyList(completion: @escaping (Any?, Bool) -> Void)
   {
    let url = URL(string: Constants.baseUrl)
    let dataTask = sharedInstance.session.dataTask(with: url!) { (data, response, error) in
        
        guard error == nil else {
            completion(nil,false)
            return
        }
        
        guard let content = data else {
            completion(nil,false)
            return
        }
        do
        {
            let decoder = JSONDecoder()
            let dataCompanyList = try decoder.decode(Companies.self, from: content)
            completion(dataCompanyList.companies,true)
        }
        catch
        {
            completion(nil,false)
        }
    }
    dataTask.resume()
    }
    
    class func fetchCompanyLogoFor(strLogo:String, completion: @escaping (Any?, Bool) -> Void)
    {
        let url:URL! = URL(string: strLogo)
        let task = sharedInstance.session.dataTask(with: url! as URL) { (data, response, error) in
            if error != nil || response == nil || (response as! HTTPURLResponse).statusCode != 200
            {
                completion(nil,false)
            }
            else
            {
                completion(data,true)
            }
        }
        task.resume()
    }
}
