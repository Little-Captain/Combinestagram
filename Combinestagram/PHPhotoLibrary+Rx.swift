//
//  PHPhotoLibrary+Rx.swift
//  Combinestagram
//
//  Created by qxxl007 on 2018/9/12.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
    
    // 授权的两条路径
    // 1. 已允许, .next(true) -> .completed
    // 2. 未允许, .next(false) -> 请求授权 -> .next(结果(true or false)) -> .completed
    static var authorized: Observable<Bool> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                if authorizationStatus() == .authorized {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    requestAuthorization { newStatus in
                        observer.onNext(newStatus == .authorized)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
    
}
