// Copyright (c) 2015 Rocket Town Ltd
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

let TimberjackRequestHandledKey = "Timberjack"
let TimberjackRequestTimeKey = "TimberjackRequestTime"

public enum Style {
    case verbose
    case light
}

open class Timberjack: URLProtocol {
    var connection: NSURLConnection?
    var data: NSMutableData?
    var response: URLResponse?
    var newRequest: NSMutableURLRequest?
    
    open static var logStyle: Style = .verbose
    
    open class func register() {
        URLProtocol.registerClass(self)
    }
    
    open class func unregister() {
        URLProtocol.unregisterClass(self)
    }
    
    open class func defaultSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses?.insert(Timberjack.self, at: 0)
        return config
    }
    
    //MARK: - NSURLProtocol
    
    open override class func canInit(with request: URLRequest) -> Bool {
        guard self.property(forKey: TimberjackRequestHandledKey, in: request) == nil else {
            return false
        }
        
        return true
    }
    
    open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    open override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }

    open override func startLoading() {
        guard let req = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest , newRequest == nil else { return }
        
        self.newRequest = req
        
        Timberjack.setProperty(true, forKey: TimberjackRequestHandledKey, in: newRequest!)
        Timberjack.setProperty(Date(), forKey: TimberjackRequestTimeKey, in: newRequest!)
        
        connection = NSURLConnection(request: newRequest! as URLRequest, delegate: self)
        
        logRequest(newRequest! as URLRequest)
    }
    
    open override func stopLoading() {
        connection?.cancel()
        connection = nil
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(_ connection: NSURLConnection!, didReceiveResponse response: URLResponse!) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        
        self.response = response
        self.data = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection!, didReceiveData data: Data!) {
        client?.urlProtocol(self, didLoad: data)
        self.data?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection!) {
        client?.urlProtocolDidFinishLoading(self)
        
        if let response = response {
            logResponse(response, data: data as Data?)
        }
    }
    
    func connection(_ connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.urlProtocol(self, didFailWithError: error)
        logError(error)
    }
    
    //MARK: - Logging
    
    open func logError(_ error: NSError) {
        
        Logger.log.error("Error: \(error.localizedDescription)")
        
        if Timberjack.logStyle == .verbose {
            if let reason = error.localizedFailureReason {
                Logger.log.error("Reason: \(reason)")
            }
            
            if let suggestion = error.localizedRecoverySuggestion {
                Logger.log.error("Suggestion: \(suggestion)")
            }
        }
    }
    
    open func logRequest(_ request: URLRequest) {
        
        var requestString = ""

        if let url = request.url?.absoluteString {
            requestString += "Request: \(request.httpMethod!) \(url)"
        }
        
        if Timberjack.logStyle == .verbose {
            if let headers = request.allHTTPHeaderFields {
                requestString += logHeaders(headers as [String : AnyObject])
            }
            
            guard let data = request.body() else {
                Logger.log.debug(requestString)
                return
            }
            
            if let string = json(fromData: data) {
                requestString += "\nJSON: \(string)"
            }
        }
        
        
        Logger.log.debug(requestString)

    }
    
    open func logResponse(_ response: URLResponse, data: Data? = nil) {
        
        var responseString = ""
        
        if let url = response.url?.absoluteString {
            responseString += "Response: \(url)"
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            responseString += " Status: \(httpResponse.statusCode) - \(localisedStatus)"
        }

        if Timberjack.logStyle == .verbose {
            if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
                responseString += logHeaders(headers)
            }
            
            if let startDate = Timberjack.property(forKey: TimberjackRequestTimeKey, in: newRequest! as URLRequest) as? Date {
                let difference = fabs(startDate.timeIntervalSinceNow)
                responseString += "\nDuration: \(difference)s"
            }

            guard let data = data else {
                Logger.log.debug(responseString)
                return
            }
            
            if let string = json(fromData: data) {
                responseString += "\nJSON: \(string)"
            }
            
            Logger.log.debug(responseString)
        }
    }
    
    open func logHeaders(_ headers: [String: AnyObject]) -> String {
        var headersString = "\nHeaders: [\n"
        for (key, value) in headers {
            headersString += "  \(key) : \(value)\n"
        }
        headersString += "]"
        return headersString
    }
    
    private func json(fromData data: Data) -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: pretty, encoding: .utf8)
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }
}


// source: https://github.com/andysmart/Timberjack/issues/7

private extension URLRequest {
    
    func body() -> Data? {
        var data: Data?
        
        if let body = self.httpBody {
            data = body
        } else if let stream = self.httpBodyStream {
            stream.open()
            data = stream.readData()
            stream.close()
        }
        
        return data
    }
}

private extension InputStream {
    
    func readData() -> Data {
        let maxLength = 4096
        var data = Data()
        var buffer = Array<UInt8>(repeating: 0, count:maxLength)
        
        var bytesRead = self.read(&buffer, maxLength: maxLength)
        while bytesRead > 0 {
            data.append(&buffer, count: bytesRead)
            bytesRead = self.read(&buffer, maxLength: maxLength)
        }
        
        return data
    }
}
