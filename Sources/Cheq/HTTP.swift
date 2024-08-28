import Foundation
import os

enum HTTP {
    
    static var log: Logger {
        return Logger(subsystem: "com.cheq", category: "HTTP")
    }
    
    static func logRequest(request:URLRequest) {
        // Log Request
        log.debug("--- REQUEST ---")
        log.debug("\tURL: \(request.url?.absoluteString ?? "N/A", privacy: .public)")
        log.debug("\tMethod: \(request.httpMethod ?? "N/A", privacy: .public)")
        log.debug("\tUUID: \(SST.getUUID() ?? "N/A", privacy: .public)")
        
        // Log Request Headers
        log.debug("Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            log.debug("\t\(key, privacy: .public): \(value, privacy: .public)")
        }
        
        // Log Request Body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            log.debug("Request Body:")
            log.debug("\t\(bodyString, privacy: .public)")
        }
    }
    
    static func logResponse(response: HTTPURLResponse, responseData: Data?) {
        // Log Response
        log.debug("--- RESPONSE ---")
        log.debug("\tStatus Code: \(response.statusCode, privacy: .public)")
        
        // Log Response Headers
        log.debug("Response Headers:")
        response.allHeaderFields.forEach { key, value in
            log.debug("\t\(key, privacy: .public): \(String(describing: value), privacy: .public)")
        }
        
        // Log Response Body
        if (response.statusCode != 204) {
            if let responseData = responseData, let responseString = String(data: responseData, encoding: .utf8) {
                log.debug("Response Body:")
                log.debug("\t\(responseString, privacy: .public)")
            }
        }
    }
    
    static func sendHttpPost(userAgent: String?, url: URL, jsonString: String, debug: Bool) async -> Int? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let userAgent = userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        if (debug) {
            logRequest(request: request)
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                log.error("Invalid response")
                return nil
            }
            if (debug) {
                logResponse(response: httpResponse, responseData: data)
            }
            return httpResponse.statusCode
        } catch {
            log.error("Error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
