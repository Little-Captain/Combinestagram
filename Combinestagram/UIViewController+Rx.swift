//
//  UIViewController+Rx.swift
//  Combinestagram
//
//  Created by qxxl007 on 2018/9/11.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    
    func alert(title: String, text: String? = nil) -> Completable {
        return Completable.create { [weak self] completable in
            let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Close", style: .default) { _ in completable(.completed) })
            self?.present(alertVC, animated: true)
            return Disposables.create { self?.dismiss(animated: true) }
        }
    }
    
}
