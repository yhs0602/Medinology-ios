//
//  DrugDetail.swift
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

import Foundation

struct DrugDetail {
    var need_prescription: Bool = false
    var danger_pregnant: Bool = false
    var danger_children: Bool = false
    var danger_elderly: Bool = false
    var should_consult: Bool {
        get {
            return need_prescription || danger_pregnant || danger_elderly || danger_children
        }
    }
}
