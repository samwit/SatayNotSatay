//
//  RoundedShadowImageView.swift
//  SatayNotSatay
//
//  Created by Sam Witteveen on 17/8/17.
//  Copyright © 2017 Sam Witteveen. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowImageView: UIImageView {
    
    override func prepareForInterfaceBuilder() {
        customizeView()
    }
    
    override func awakeFromNib() {
        customizeView()
    }
    
    func customizeView(){
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }
}

