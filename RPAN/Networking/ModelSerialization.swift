//
//  RequestDispatcher.swift
//  CarvanaCore
//
//  Created by Erik Villegas on 3/17/18.
//  Copyright © 2018 Carvana. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class RedditDecoder: JSONDecoder {
    override public init() {
        super.init()
        self.keyDecodingStrategy = .convertFromSnakeCase
    }
}

extension DataRequest {
    
    func responseDecodable<T: Decodable>(type: T.Type) -> Promise<T> {
        return Promise { seal in
            self.responseDecodable(of: T.self, decoder: RedditDecoder()) { result in
                switch result.result {
                case .success(let model):
                    seal.fulfill(model)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    func responseString() -> Promise<String> {
        return Promise { seal in
            self.responseString() { result in
                switch result.result {
                case .success(let string):
                    seal.fulfill(string)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}
