//
//  Session+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/25/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import reddift

extension Session {
    
    @discardableResult
    func subredditRules(_ subredditName: String, completion: @escaping (Result<SubredditRules>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: "r/\(subredditName)/about/rules.json?api_type=json&raw_json=1", method: "GET", token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<SubredditRules> in
            return Result(from: reddift.Response(data: data, urlResponse: response), optional: error)
                .flatMap(reddift.response2Data)
                .flatMap(data2Json)
                .flatMap(json2Decodable)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func ban(_ name: String, from subreddit: String, banMessage: String, modNote: String?, reason: String, duration: Int?, comment: Comment, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameters = [
            "name": name,
            "type": "banned",
            "ban_message": banMessage,
            "ban_reason": reason,
            "ban_context": comment.name
        ]
        
        if let duration = duration {
            parameters["duration"] = String(duration)
        }
        
        if let modNote = modNote {
            parameters["note"] = modNote
        }
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: "r/\(subreddit)/api/friend", parameter: parameters, method: "POST", token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional: error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func remove(_ broadcast: Broadcast, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "id": broadcast.post.id, // t3_i1bmto
            "spam": "false"
        ]
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: "api/remove", parameter: parameters, method: "POST", token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional: error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func remove(_ comment: Comment, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "id": comment.name,
            "spam": "false"
        ]
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: "api/remove", parameter: parameters, method: "POST", token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional: error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func approve(_ comment: Comment, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "id": comment.name
        ]
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: "api/approve", parameter: parameters, method: "POST", token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional: error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func execute<T: Decodable>(path: String, parameters: [String: String]? = nil, method: String = "GET", completion: @escaping (Result<T>) -> Void) throws -> URLSessionDataTask {
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: path, parameter: parameters, method: method, token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<T> in
            if let error = error {
                return Result(error: error)
            }
            
            guard let data = data else {
                return Result(error: ReddiftError.unknown as NSError)
            }
            
            do {
                return Result(value: try RedditDecoder().decode(T.self, from: data))
            }
            catch {
                return Result(error: error as NSError)
            }
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func execute<T: Decodable>(path: String, data: Data, method: String = "POST", completion: @escaping (Result<T>) -> Void) throws -> URLSessionDataTask {
        
        guard var request = URLRequest.requestForOAuth(with: baseURL, path: path, data: data, method: method, token: token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<T> in
            if let error = error {
                return Result(error: error)
            }
            
            guard let data = data else {
                return Result(error: ReddiftError.unknown as NSError)
            }
            
            do {
                return Result(value: try RedditDecoder().decode(T.self, from: data))
            }
            catch {
                return Result(error: error as NSError)
            }
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}

func json2Decodable<T: Decodable>(from json: JSONAny) -> Result<T> {
    guard let data = try? JSONSerialization.data(withJSONObject: json) else {
        return Result(error: ReddiftError.failedToParseThingFromJsonObject as NSError)
    }
    
    guard let object = try? RedditDecoder().decode(T.self, from: data) else {
        return Result(error: ReddiftError.failedToParseThingFromJsonObject as NSError)
    }
    
    return Result(value: object)
}
