//
//  CustomButton.swift
//  tedst
//
//  Created by MyMac on 10/02/24.
//

import UIKit

class CustomButton: UIButton {

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let superRect = super.titleRect(forContentRect: contentRect)
        return CGRect(
            x: 0,
            y: contentRect.height - superRect.height,
            width: contentRect.width,
            height: superRect.height
        )
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let superRect = super.imageRect(forContentRect: contentRect)
        return CGRect(
            x: contentRect.width / 2 - superRect.width / 2,
            y: (contentRect.height - titleRect(forContentRect: contentRect).height) / 2 - superRect.height / 2,
            width: superRect.width,
            height: superRect.height
        )
    }
    
    override var intrinsicContentSize: CGSize {
        _ = super.intrinsicContentSize
        guard let image = imageView?.image else { return super.intrinsicContentSize }
        let size = titleLabel?.sizeThatFits(contentRect(forBounds: bounds).size) ?? .zero
        let spacing: CGFloat = 12
        return CGSize(width: max(size.width, image.size.width), height: image.size.height + size.height + spacing)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        titleLabel?.textAlignment = .center
        titleLabel?.font =  UIFont(name: "SFProText-Regular", size: 14)
        titleLabel?.textColor = UIColor(red: 0.0, green: 0.004, blue: 0.502, alpha: 1.0)

    }
}