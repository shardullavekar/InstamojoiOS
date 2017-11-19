//
//  NetworkManager.swift
//  LottieAnimation
//
//  Created by Shubhakeerti on 15/11/17.
//  Copyright © 2017 Shubhakeerti. All rights reserved.
//

import UIKit

class NetworkManager: NSObject {

    lazy var authorizationValue: String = {
        return "Bearer " + IMConfiguration.sharedInstance.accessToken!
    }()
    
    func getAccessToken(completion: @escaping (String) -> Void) {
        if let metaURL = Bundle.main.infoDictionary?["InstaMojoConfigURL"] as? String {
            let request = NSMutableURLRequest(url: NSURL(string: metaURL)! as URL)
            request.httpMethod = "GET"
            request.addValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
            request.addValue(IMConstants.NetworkHeaders.ContentType_JSON, forHTTPHeaderField: IMConstants.NetworkHeaders.ContentType)
            
            let session = URLSession.shared
            self.printBeforApi(request: request)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, _, error -> Void in
                if error == nil {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                            self.printAfterResponse(jsonResponse: jsonResponse)
                            if let accessToken = jsonResponse["access_token"] as? String {
                                IMConfiguration.sharedInstance.accessToken = accessToken
                                self.getPaymentRequest(completion: completion)
                            } else {
                                completion(jsonResponse["error"] as! String)
                            }
                        }
                    } catch {
                        completion("Unable to parse JSON")
                    }
                } else {
                    completion(error!.localizedDescription)
                }
            })
            task.resume()
        } else {
            completion("Please Provide valid Meta URL")
        }
    }
    
    private func queryURLString(_ dict:[String:String]) -> String{
        var count:Int = 0
        var queryString:String = ""
        for (key, value) in dict{
            if count == 0 {
                queryString = String(format: "%@%@=%@", queryString, key, value)
            }else{
                queryString = String(format: "%@&%@=%@", queryString, key, value)
            }
            count += 1
        }
        return queryString
    }
    
    func getPaymentRequest(completion: @escaping (String) -> Void) {
        let request = NSMutableURLRequest(url: NSURL(string: IMConstants.getBaseURL() + IMConstants.NetworkURL.GetPaymentRequest)! as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: self.getPaymentRequestBody(), options: JSONSerialization.WritingOptions.prettyPrinted)
        request.addValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.addValue(IMConstants.NetworkHeaders.ContentType_JSON, forHTTPHeaderField: IMConstants.NetworkHeaders.ContentType)
        request.addValue(self.authorizationValue, forHTTPHeaderField: IMConstants.NetworkHeaders.Authorization)
        let session = URLSession.shared
        self.printBeforApi(request: request as NSURLRequest)

        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, _, error -> Void in
            if error == nil {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                        self.printAfterResponse(jsonResponse: jsonResponse)
                        if let success = jsonResponse["success"] as? String , success.lowercased() == "false"{
                            completion(jsonResponse["message"].debugDescription)

                        } else {
                            if let paymentId = jsonResponse["id"] as? String {
                                IMConfiguration.sharedInstance.paymentId = paymentId
                                self.getOrderDetails(completion: completion)
                            } else {
                                completion(jsonResponse["message"].debugDescription)
                            }
                        }
                    }
                } catch {
                    completion("Unable to parse JSON")

                }
            } else {
                completion(error!.localizedDescription)
            }
        })
        task.resume()
    }
    
    func getPaymentRequestBody() -> [String: String] {
        var returnDict: Dictionary = [String: String]()
        if let orderObjectUW = IMConfiguration.sharedInstance.orderObject {
            returnDict["purpose"] = orderObjectUW.purpose
            returnDict["amount"] = orderObjectUW.amount
            returnDict["buyer_name"] = orderObjectUW.buyer_name
            returnDict["email"] = orderObjectUW.email
            returnDict["phone"] = orderObjectUW.phone
            returnDict["redirect_url"] = orderObjectUW.redirect_url
            returnDict["send_email"] = orderObjectUW.send_email.description
            returnDict["send_sms"] = orderObjectUW.send_sms.description
            returnDict["webhook"] = orderObjectUW.webhook ?? ""
            returnDict["allow_repeated_payments"] = orderObjectUW.allow_repeated_payments.description
            return returnDict
        }
        return returnDict
    }
    
    func getOrderDetails(completion: @escaping (String) -> Void) {
        let request = NSMutableURLRequest(url: NSURL(string: IMConstants.getBaseURL() + IMConstants.NetworkURL.GetOrderDetails)! as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["id": IMConfiguration.sharedInstance.paymentId!], options: JSONSerialization.WritingOptions.prettyPrinted)
        request.addValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.addValue(IMConstants.NetworkHeaders.ContentType_JSON, forHTTPHeaderField: IMConstants.NetworkHeaders.ContentType)
        request.addValue(self.authorizationValue, forHTTPHeaderField: IMConstants.NetworkHeaders.Authorization)
        let session = URLSession.shared
        self.printBeforApi(request: request)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, _, error -> Void in
            if error == nil {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                        self.printAfterResponse(jsonResponse: jsonResponse)
                        if let success = jsonResponse["success"] as? String , success.lowercased() == "false" {
                            completion(jsonResponse["message"].debugDescription)
                        } else {
                            if let orderId = jsonResponse["order_id"] as? String {
                                IMConfiguration.sharedInstance.orderId = orderId
                                var orderObject: OrderObject
                                if let orderObjectUW = IMConfiguration.sharedInstance.orderObject {
                                    orderObject = orderObjectUW
                                    orderObject.order_id = orderId
                                    IMConfiguration.sharedInstance.orderObject = orderObject
                                } else {
                                    orderObject = OrderObject(order_id: orderId, buyer_name: jsonResponse["name"] as? String ?? "", email: jsonResponse["email"] as? String ?? "", phone: jsonResponse["phone"] as? String ?? "", amount: jsonResponse["amount"] as? String ?? "", purpose: "", redirect_url: IMConstants.NetworkURL.RedirectURL, webhook: IMConstants.NetworkURL.WebHookURL)
                                    IMConfiguration.sharedInstance.orderObject = orderObject
                                }
                                completion("Success")
                            } else {
                                completion(jsonResponse.debugDescription)
                            }
                        }
                    }
                } catch {
                    completion("Unable to parse JSON")
                }
            } else {
                completion(error!.localizedDescription)
            }
        })
        task.resume()
    }
    
    func getUserAgent() -> String {
        let versionName: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)! + ";"
        let versionCode: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
        let appID = Bundle.main.bundleIdentifier! + ";"
        return  "Instamojo IOS SDK;" + UIDevice.current.model + ";" + "Apple;" + UIDevice.current.systemVersion + ";" + appID + versionName + versionCode
    }
    
    func checkPaymentStatus(completion: @escaping(Bool, String) -> Void) {
        let requestURL = URL(string: IMConstants.getBaseURL() + IMConstants.NetworkURL.GetPaymentDetails2 + IMConfiguration.sharedInstance.orderId! + "/")!
        let request = NSMutableURLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.addValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.addValue(IMConstants.NetworkHeaders.ContentType_JSON, forHTTPHeaderField: IMConstants.NetworkHeaders.ContentType)
        request.addValue(self.authorizationValue, forHTTPHeaderField: IMConstants.NetworkHeaders.Authorization)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, _, error -> Void in
            if error == nil {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                    let payments = jsonResponse["payments"] as! [[String :Any]]
                        let status = (payments[0]["status"] as? String)?.lowercased()
                        if status == "successful"{
                            var successMessage = "Transaction successful \n"
                            let id = payments[0]["id"] as? String
                            successMessage = successMessage + "Transaction Id : " + "\(id!)"
                            completion(true, successMessage)
                        } else if status == "failed" {
                            var failureMessage = "Transaction failed"
                            if let failureDict = payments[0]["failure"] as? [String: Any], let failureReason = failureDict["reason"] as? String {
                                failureMessage = failureMessage + "\n" + "Reason : " + "\(failureReason)"
                            }
                            completion(false, failureMessage)
                        } else {
                            completion(false, "Transaction Pending")
                        }
                    }
                } catch {
                    completion(false, "Unable to Parse JSON")
                }
            } else {
                completion(false, error!.localizedDescription)
            }
        })
        task.resume()
    }
    
    func printBeforApi(request: NSURLRequest) {
        print("============= API Request ===============\n")
        print(request.url?.absoluteString ?? "URL is nil")
        print("\n =========== API Request ===============\n")
    }
    
    func printAfterResponse(jsonResponse: [String:Any]) {
        print("============= API Response ===============\n")
        print(jsonResponse.description)
        print("\n =========== API Response ===============\n")
    }
}

extension String {
    func addingPercentEncodingForURLQueryValue() -> String? {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        
        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
    
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = map { key, value -> String in
            let percentEscapedKey = (key as! String).addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
}
