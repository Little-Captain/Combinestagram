/*
 * Copyright (c) 2016-present Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift

class MainViewController: UIViewController {

    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!

    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([])
    private var imageCache = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let imagesO = images
                .asObservable()
                .throttle(0.5, scheduler: MainScheduler.instance)
                .share()

        imagesO
                .subscribe(onNext: { [unowned self] photos in
                    self.imagePreview.image = UIImage.collage(images: photos, size: self.imagePreview.frame.size)
                })
                .disposed(by: bag)

        imagesO
                .subscribe(onNext: { [weak self] in self?.updateUI(photos: $0) })
                .disposed(by: bag)
    }

    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }

    private func updateNavigationIcon() {
        let icon = imagePreview.image?
                .scaled(CGSize(width: 22, height: 22))
                .withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                style: .done,
                target: nil,
                action: nil)
    }

    @IBAction func actionClear() {
        images.value = []
        imageCache = []
        updateNavigationIcon()
    }

    @IBAction func actionSave() {
        guard let image = imagePreview.image else {
            return
        }
        PhotoWriter.save(image)
                //            .asSingle()
                .subscribe(
                        onSuccess: { [weak self] in
                            self?.showMessage("Saved with id: \($0)")
                            self?.actionClear()
                        },
                        onError: { [weak self] error in
                            self?.showMessage("Error", description: error.localizedDescription)
                        })
                .disposed(by: bag)
    }

    @IBAction func actionAdd() {
//        images.value.append(UIImage(named: "IMG_1907.jpg")!)
        let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        let newPhotos = photosViewController.selectedPhotos.share()
        _ = newPhotos
                // 只取 6 张图片
                .takeWhile { [weak self] _ in
                    (self?.images.value.count ?? 0) < 6
                }
                // 过滤掉纵向图片
                .filter {
                    $0.size.width > $0.size.height
                }
                // 过滤掉重复图片
                .filter { [weak self] in
                    let len = UIImagePNGRepresentation($0)?.count ?? 0
                    guard self?.imageCache.contains(len) == false else {
                        return false
                    }
                    self?.imageCache.append(len)
                    return true
                }
                .subscribe(onNext: { [weak self] in
                    guard let images = self?.images else {
                        return
                    }
                    images.value.append($0)
                }, onDisposed: {
                    print("completed photo selected")
                })
        _ = newPhotos
                // 忽略所有 .next 事件
                .ignoreElements()
                .subscribe(onCompleted: { [weak self] in
                    self?.updateNavigationIcon()
                })
        navigationController?.pushViewController(photosViewController, animated: true)
    }

    func showMessage(_ title: String, description: String? = nil) {
        _ = alert(title: title, text: description).subscribe()
    }
}
