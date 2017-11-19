//
//  IMController.swift
//  InstaMojoiOS
//
//  Created by Shubhakeerti on 17/11/17.
//  Copyright © 2017 Shubhakeerti. All rights reserved.
//

import UIKit
import Instamojo

class IMController: NSObject {
    
    lazy var alertController: UIAlertController = {
        let alert = UIAlertController(title: "Initializing Payment", message: nil, preferredStyle: .alert)
        
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10,y: 5,width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        return alert
    }()
    lazy var networkManager: NetworkManager = NetworkManager()
    
    var paymentCompleted: Bool = false
    
    func initializeSDK() {
        let window: UIWindow? = UIApplication.shared.keyWindow
        let rootClass = window?.rootViewController
        let alert = self.alertController
        alert.title = "Initializing Payment"
        rootClass?.present(alertController, animated: true, completion: nil)
        networkManager.getAccessToken { (error) in
            DispatchQueue.main.async {
                if error.lowercased() == "success", let accessTokenUW = IMConfiguration.sharedInstance.accessToken, let orderObjectUW = IMConfiguration.sharedInstance.orderObject {
                    let request = Request(order: self.getOrder(accessToken: accessTokenUW, orderObject: orderObjectUW), orderRequestCallBack: self)
                    request.execute()
                } else {
                    IMConfiguration.sharedInstance.returnBlock?(false, error)
                }
            }
        }
    }
    
    func getOrder(accessToken: String, orderObject: OrderObject) -> Order {
        let order : Order = Order(authToken: accessToken, transactionID: self.getUniqueTransactionId(), buyerName: orderObject.buyer_name, buyerEmail: orderObject.email, buyerPhone: orderObject.phone, amount: orderObject.amount, description: orderObject.purpose, webhook: orderObject.webhook ?? "")
        order.id = orderObject.order_id
        return order
    }
    
    func getUniqueTransactionId() -> String {
        let uniqueId = UUID().uuidString
        IMConfiguration.sharedInstance.transactionId = uniqueId
        return uniqueId
    }
    
    func addNotificationToRecievePaymentCompletion(){
        NotificationCenter.default.addObserver(self, selector: #selector(paymentCompletionCallBack), name: NSNotification.Name("INSTAMOJO"), object: nil)
    }
    
    @objc func paymentCompletionCallBack() {
        if !self.paymentCompleted {
            if UserDefaults.standard.value(forKey: "USER-CANCELLED") != nil {
                IMConfiguration.sharedInstance.returnBlock?(false, "Transaction Cancelled By User")
            }
            if UserDefaults.standard.value(forKey: "ON-REDIRECT-URL") != nil {
                self.paymentCompleted = true
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5, execute: {
                    let window: UIWindow? = UIApplication.shared.keyWindow
                    let rootClass = window?.rootViewController
                    let alert = self.alertController
                    alert.title = "Finalizing Payment"
                    rootClass?.present(self.alertController, animated: true, completion: nil)
                    self.networkManager.checkPaymentStatus(completion: { (success, message) in
                        DispatchQueue.main.async {
                            self.paymentCompleted = false
                            self.alertController.dismiss(animated: false, completion: nil)
                            IMConfiguration.sharedInstance.returnBlock?(success, message)
                        }
                    })
                })
                
            }
            if UserDefaults.standard.value(forKey: "USER-CANCELLED-ON-VERIFY") != nil {
                IMConfiguration.sharedInstance.returnBlock?(false, "Transaction Cancelled before Verification")
            }
        }
    }
    
}

extension IMController: OrderRequestCallBack {
    public func onFinish(order: Order, error: String) {
        DispatchQueue.main.sync {
            self.alertController.dismiss(animated: true, completion: nil)
            IMConfiguration.sharedInstance.orderId = order.id
            Instamojo.invokePaymentOptionsView(order: order)
            
        }
    }
}
