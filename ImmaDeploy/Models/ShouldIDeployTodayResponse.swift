//
//  ShouldIDeployTodayResponse.swift
//  ImmaDeploy
//
//  Created by Erick Matheus on 19/01/26.
//

import Foundation

struct ShouldIDeployTodayResponse: Decodable {
    let timezone: String
    let date: String
    let shouldideploy: Bool
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case timezone
        case date
        case shouldideploy
        case message
    }
}
