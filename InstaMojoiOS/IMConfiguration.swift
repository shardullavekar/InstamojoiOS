//
//  IMConfiguration.swift
//  LottieAnimation
//
//  Created by Shubhakeerti on 16/11/17.
//  Copyright © 2017 Shubhakeerti. All rights reserved.
//

import UIKit
import Instamojo

@objc public enum Environment: Int {
    case Test
    case Production
}

public class IMConfiguration: NSObject {
    public static let sharedInstance = IMConfiguration()
    var accessToken: String?
    var orderId: String?
    var paymentId: String?
    var transactionId: String?
    var orderObject: OrderObject?
    var returnBlock: ((Bool, String) -> Void)?
    var environment: Environment = .Test
    let imController: IMController = IMController()
    
    public func setupOrder(purpose: String, buyerName: String, emailId: String, mobile: String, amount: String, environment: Environment, on viewController: UIViewController?, completion: @escaping (Bool, String) -> Void) {
        self.environment = environment
        self.orderObject = OrderObject(order_id: nil, buyer_name: buyerName, email: emailId, phone: mobile, amount: amount, purpose: purpose, redirect_url: IMConstants.NetworkURL.RedirectURL, send_email: false, send_sms: false, webhook: IMConstants.NetworkURL.WebHookURL, allow_repeated_payments: false)
        
        Instamojo.setup()
        Instamojo.setBaseUrl(url: IMConstants.getBaseURL())
        Instamojo.enableLog(option: true)
        returnBlock = completion
        imController.addNotificationToRecievePaymentCompletion()
        let validationTuple = self.validateInputData()
        if validationTuple.0 == false {
            returnBlock?(validationTuple.0, validationTuple.1)
        } else {
            imController.initializeSDK()
        }
    }
    
    private func validateInputData() -> (Bool, String) {
        if let orderObjectUW = self.orderObject {
            var returnMessage: String = ""
            if orderObjectUW.purpose.characters.count <= 0 {
                returnMessage.append("\u{2022}  Purpose cannot be empty.")
            }
            
            if orderObjectUW.buyer_name.characters.count <= 0 {
                if returnMessage.characters.count > 0 {
                    returnMessage.append("\n")
                }
                returnMessage.append("\u{2022}  Buyer name cannot be empty.")
            }
            
            if orderObjectUW.email.characters.count <= 0 {
                if returnMessage.characters.count > 0 {
                    returnMessage.append("\n")
                }
                returnMessage.append("\u{2022}  Email Id cannot be empty.")
            } else {
                if !self.validateEmail(email: orderObjectUW.email) {
                    if returnMessage.characters.count > 0 {
                        returnMessage.append("\n")
                    }
                    returnMessage.append("\u{2022}  Email Id is Invalid.")
                }
            }
            
            if orderObjectUW.phone.characters.count <= 0 {
                if returnMessage.characters.count > 0 {
                    returnMessage.append("\n")
                }
                returnMessage.append("\u{2022}  Mobile number cannot be empty.")
            } else {
                if !self.validateMobile(phone: orderObjectUW.phone) {
                    if returnMessage.characters.count > 0 {
                        returnMessage.append("\n")
                    }
                    returnMessage.append("\u{2022}  Mobile number is Invalid.")
                }
            }
            
            if let amountIntegerValue = Float(orderObjectUW.amount) {
                if amountIntegerValue <= 0 {
                    if returnMessage.characters.count > 0 {
                        returnMessage.append("\n")
                    }
                    returnMessage.append("\u{2022}  Amount cannot be '0'")
                }
            } else {
                if returnMessage.characters.count > 0 {
                    returnMessage.append("\n")
                }
                returnMessage.append("\u{2022}  Amount is Invalid.")
            }
            
            if returnMessage.characters.count > 0 {
                return (false, returnMessage)
            }
            return (true, returnMessage)
        } else {
            return (false, "Order details were nil")
        }
    }
    
    private func validateEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    private func validateMobile(phone: String) -> Bool {
        let phoneWithoutSpecialCharacters = (phone.components(separatedBy: CharacterSet.decimalDigits.inverted)).joined(separator: "")
        if phoneWithoutSpecialCharacters.characters.count > 10 {
            if phoneWithoutSpecialCharacters.hasPrefix("0") {
                return true
            } else if phoneWithoutSpecialCharacters.hasPrefix("91") {
                let index = phoneWithoutSpecialCharacters.index(phoneWithoutSpecialCharacters.startIndex, offsetBy: 2)
                let phoneWithoutCountryCode = phoneWithoutSpecialCharacters.substring(from: index)
                if phoneWithoutCountryCode.characters.count != 10 {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        } else if phoneWithoutSpecialCharacters.characters.count == 10 {
            return true
        } else {
            return false
        }
    }
    
    func getAuthorizationValue() -> String {
        return "Bearer " + self.accessToken!
    }
}
