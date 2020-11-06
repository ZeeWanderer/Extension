//
//  Fonts.swift
//  Extension
//
//  Created by Maksym Kulyk on 11/6/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

extension UIFont
{
    convenience init?(named fontName: String, fitting text: String, into targetSize: CGSize, with attributes: [NSAttributedString.Key: Any], options: NSStringDrawingOptions)
    {
        var attributes = attributes
        let fontSize = targetSize.height

        attributes[.font] = UIFont(name: fontName, size: fontSize)
        let size = text.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: fontSize),
                                     options: options,
                                     attributes: attributes,
                                     context: nil).size

        let heightSize = targetSize.height / (size.height / fontSize)
        let widthSize = targetSize.width / (size.width / fontSize)

        self.init(name: fontName, size: min(heightSize, widthSize))
    }
}

func adjustAttributesToFit(line: String, in rect : CGRect, m_attributes:inout [NSAttributedString.Key : Any], options: NSStringDrawingOptions, context: NSStringDrawingContext?)
{
    let s_font = m_attributes[.font] as! UIFont
    let s_font_size = rect.size.height

    m_attributes[.font] = s_font.withSize(s_font_size)
    let s_size = line.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: s_font_size),
                                 options: options,
                                 attributes: m_attributes,
                                 context: context).size

    let height_size = rect.size.height / (s_size.height / s_font_size)
    let width_size = rect.size.width / (s_size.width / s_font_size)
    
    m_attributes[.font] = s_font.withSize(min(height_size, width_size))
}
