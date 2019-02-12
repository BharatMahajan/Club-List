//
//  MemberTableViewCell.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var lblFirstName: UILabel!
    @IBOutlet weak var lblLastName: UILabel!
    @IBOutlet weak var lblAge: UILabel!
    @IBOutlet weak var lblMail: UILabel!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var imgFavorite: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateMemberCell(member:Member){
        if member.favorite
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
