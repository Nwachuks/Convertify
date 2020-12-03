//
//  Currency.swift
//  Convertify
//
//  Created by Nwachukwu Ejiofor on 29/11/2020.
//

import Foundation
import RealmSwift

class Currency: Object {
	@objc dynamic var name = ""
	@objc dynamic var rate = 0.0
}
