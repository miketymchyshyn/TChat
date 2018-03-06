//
//  MessageTableViewCell.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/20/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageBackground: UIView!
    @IBOutlet weak var messageTextLabel: UILabel!

    @IBOutlet weak var leadingForBackground: NSLayoutConstraint!
    @IBOutlet weak var trailingForBackground: NSLayoutConstraint!
    
    @IBOutlet weak var textLeading: NSLayoutConstraint!
    @IBOutlet weak var textTrailing: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
