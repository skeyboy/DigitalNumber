//
//  ViewController.swift
//  DigitalNumber
//
//  Created by 李雨龙 on 2020/5/19.
//  Copyright © 2020 李雨龙. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
class ViewController: UIViewController {
    //数字输入
    @IBOutlet weak var inputFieldView: UITextField!
    
    //数字变化
    var behavior = BehaviorRelay(value: UInt64(0))
    
    //质数结果存储
    var valueContainer = ReplaySubject<UInt64>.create(bufferSize: 100)
    
    //结果显示UI
    @IBOutlet weak var valueShowView: UITextView!
    var disposable:Disposable?
    let bang = DisposeBag()
    
    //转换为 UInt64
    func digitalEvent(_ value:String)-> Observable<UInt64?>{
        return Observable.create{ on in
            on.onNext(UInt64(value))
            on.onCompleted()
            return Disposables.create()
        }
    }
    
    @IBAction func clearResultView(_ sender: Any) {
        self.valueShowView.text = "";
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.valueContainer.map({ (a:UInt64) -> String in
            return self.valueShowView.text + "\(a)\t"
        }).startWith("展示结果:").bind(to: self.valueShowView.rx.text).disposed(by: bang)
      
        
        self.behavior.filter({ (value:UInt64) -> Bool in
            return value >= 2
        }).subscribe(onNext: { [weak self](value:UInt64) in
            // 有新的消息则取消释放之前消息
            if (self?.disposable != nil) {
                self?.disposable?.dispose()
                self?.disposable = nil
            }
            self?.disposable =  Observable<Int>.interval(RxTimeInterval.milliseconds(100), scheduler: MainScheduler()).subscribe(onNext: { [weak self](state) in
                if value == 2 {
                    print("2")
                    self?.valueContainer.onNext(value)
                    if (self?.disposable != nil) {
                        self?.disposable?.dispose()
                        self?.disposable = nil
                    }
                }else{
                let rev =    self?.isPrime(aNum: value).filter({ (nextValue:UInt64) -> Bool in
                        return value > 2
                    })
                    
                        
                    rev?.bind(to: self!.behavior)
                        .disposed(by: self!.bang)
                    
                   
                }
                
            })
        }).disposed(by: bang)
        
        
        
        inputFieldView.rx.text.orEmpty
            .filter({ (value:String) -> Bool in
                //进行数据过滤
                guard let digital = UInt64(value) else {
                    return false
                }
                if digital < 2 {
                    return false
                }
                
                return true && (value.count >= 1 )
            }).distinctUntilChanged()
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)//防止输入过快的操作
            .flatMapLatest { [weak self] value  in
                return self!.digitalEvent(value).asDriver(onErrorJustReturn: 0)//进行转换
        }.map({ (digital:UInt64?) -> UInt64 in
            return digital ?? UInt64(0)
        }).bind(to: self.behavior).disposed(by: bang)
        
        
    }
    
    
    
    
}

extension ViewController{
    //质数判断
    func isPrime(aNum:UInt64)-> Observable<UInt64>{
        
        var result = true
        for i in 2 ...   max(2, Int(sqrt(Double(aNum)))) { // max 防止 rang报错问题
            if i >= 2 && aNum %   UInt64(i) == 0  && i != aNum {
                //                       print("\(aNum)不是   \(i)")
                result  = false
                break
            }
        }
        if result {
            print("\(aNum)")
            self.valueContainer.onNext(aNum)

        }
        return  Observable.create { ob  in
            
            ob.onNext(aNum-UInt64(1))
            ob.onCompleted()
            return Disposables.create {
                
            }
        }
    }
}
