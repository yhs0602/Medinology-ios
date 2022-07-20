//
//  String+trim.swift
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

import Foundation

extension String {
    func trimmingLeadingAndTrailingSpaces(using characterSet: CharacterSet = .whitespacesAndNewlines) -> String {
        return trimmingCharacters(in: characterSet)
    }
}
