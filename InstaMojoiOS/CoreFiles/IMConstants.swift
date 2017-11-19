//
//  IMConstants.swift
//  LottieAnimation
//
//  Created by Shubhakeerti on 16/11/17.
//  Copyright © 2017 Shubhakeerti. All rights reserved.
//

import UIKit

struct IMConstants {
    struct NetworkHeaders{
        // Keys
        static let ContentType:String = "Content-Type"
        static let Authorization:String = "Authorization"
        static let ContentLen:String = "Content-Length"
        
        // Value
        static let ContentType_JSON:String = "application/json"
        static let ContentType_FormEncoded:String = "application/x-www-form-urlencoded"
    }
    
    static func getBaseURL() -> String {
        if IMConfiguration.sharedInstance.environment == .Production {
            return "https://api.instamojo.com"
        } else {
            return "https://test.instamojo.com"
        }
    }
    
    struct NetworkURL {
        static let GetAccessToken: String = "/oauth2/token/"
        static let GetPaymentRequest: String = "/v2/payment_requests/"
        static let GetOrderDetails: String = "/v2/gateway/orders/payment-request/"
        static let GetPaymentDetails: String = "/v2/payments/"
        static let GetPaymentDetails1: String = "/v2/payment-request/"
        static let GetPaymentDetails2: String = "/v2/gateway/orders/id:"
        static let RedirectURL: String = "https://test.instamojo.com/integrations/android/redirect/"
        static let WebHookURL: String = "http://your.server.com/webhook/"
    }
    
    struct NetworkUtility {
        static let timeout:TimeInterval = 60
    }
}

struct OrderObject {
    var order_id: String?
    let buyer_name: String
    let email: String
    let phone: String
    let amount: String
    let purpose: String
    var redirect_url: String
    let send_email: Bool
    let send_sms: Bool
    let webhook: String?
    let allow_repeated_payments: Bool
    init(order_id: String?, buyer_name: String, email: String, phone: String, amount: String, purpose: String, redirect_url: String, send_email: Bool = false, send_sms: Bool = false, webhook: String?, allow_repeated_payments: Bool = false) {
        self.order_id = order_id
        self.buyer_name = buyer_name
        self.email = email
        self.phone = phone
        self.amount = amount
        self.purpose = purpose
        self.redirect_url = redirect_url
        self.send_email = send_email
        self.send_sms = send_sms
        self.webhook = webhook
        self.allow_repeated_payments = allow_repeated_payments
    }
}
