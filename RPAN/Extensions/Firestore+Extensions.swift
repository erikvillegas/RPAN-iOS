//
//  Firestore+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import FirebaseFirestore
import PromiseKit

extension DocumentReference {
    func setData(_ documentData: [String : Any], merge: Bool = false) -> Promise<Void> {
        return Promise { seal in
            self.setData(documentData, merge: merge) { error in
                if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func delete() -> Promise<Void> {
        return Promise { seal in
            self.delete() { error in
                if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func getDocument() -> Promise<DocumentSnapshot> {
        return Promise { seal in
            self.getDocument() { snapshot, error in
                if let snapshot = snapshot {
                    seal.fulfill(snapshot)
                }
                else if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.reject(SettingsServiceError.unknown)
                }
            }
        }
    }

}

extension CollectionReference {
    func getDocuments() -> Promise<[QueryDocumentSnapshot]> {
        return Promise { seal in
            self.getDocuments() { snapshot, error in
                if let snapshot = snapshot {
                    seal.fulfill(snapshot.documents)
                }
                else if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.reject(SettingsServiceError.unknown)
                }
            }
        }
    }
}
