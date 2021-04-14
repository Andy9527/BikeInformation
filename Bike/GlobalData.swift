//
//  GlobalData.swift
//  Bike
//
//  Created by CHIA CHUN LI on 2021/3/16.
//

import Foundation
import CommonCrypto
import GoogleMaps
import CoreLocation
import Network

class GlobalData{
    
   
    static func dateFormatterConvert(stringFMT:String,toConvertStringFMT:String,dateString:String) -> String{
        
        let dateFMT = DateFormatter()
        dateFMT.dateFormat = stringFMT
        let date = dateFMT.date(from: dateString)
        let newDateFMT = DateFormatter()
        newDateFMT.dateFormat = toConvertStringFMT
        let newDate = newDateFMT.string(from: date ?? Date())
        
        return newDate
        
    }
    
    
    enum CryptoAlgorithm {

        case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

        var HMACAlgorithm: CCHmacAlgorithm {
            var result: Int = 0
            switch self {
            case .MD5:      result = kCCHmacAlgMD5
            case .SHA1:     result = kCCHmacAlgSHA1
            case .SHA224:   result = kCCHmacAlgSHA224
            case .SHA256:   result = kCCHmacAlgSHA256
            case .SHA384:   result = kCCHmacAlgSHA384
            case .SHA512:   result = kCCHmacAlgSHA512
            }
            return CCHmacAlgorithm(result)
        }

        var digestLength: Int {
            var result: Int32 = 0
            switch self {
            case .MD5:      result = CC_MD5_DIGEST_LENGTH
            case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
            case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
            case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
            case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
            case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
            }
            return Int(result)
        }
    }
    
    static func getServerTime() -> String {
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
        dateFormater.locale = Locale(identifier: "en_US")
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        
        return dateFormater.string(from: Date())
    }
    
   
    
    
}

extension String {

    func hmac(algorithm: GlobalData.CryptoAlgorithm, key: String) -> String {

        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        let digestLen = algorithm.digestLength
        var result = [CUnsignedChar](repeating: 0, count: digestLen)
        CCHmac(algorithm.HMACAlgorithm, cKey!, strlen(cKey!), cData!, strlen(cData!), &result)
        let hmacData:Data = Data(bytes: result, count: digestLen)
        let hmacBase64 = hmacData.base64EncodedString(options: .lineLength64Characters)

        return String(hmacBase64)
    }
}
