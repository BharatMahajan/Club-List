//
//  CompanyTableViewCell.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit

class CompanyTableViewCell: UITableViewCell {

    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblWebsite: UILabel!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var imgFollow: UIImageView!
    @IBOutlet weak var imgFavorite: UIImageView!
    @IBOutlet weak var activityIndicatorCompanyLogo: UIActivityIndicatorView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCompanyCell(company:Company){
        if company.follow
        {
            self.imgFollow.image = #imageLiteral(resourceName: "follow_yes")
        }
        else
        {
            self.imgFollow.image = #imageLiteral(resourceName: "follow_no")
        }
        
        if company.favorite
        {
            self.imgFavorite.image = #imageLiteral(resourceName: "favorite_yes")
        }
        else
        {
            self.imgFavorite.image = #imageLiteral(resourceName: "favorite_no")
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
