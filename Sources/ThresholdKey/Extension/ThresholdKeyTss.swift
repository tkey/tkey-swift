//
//  File.swift
//  
//
//  Created by CW Lee on 19/07/2023.
//

import Foundation
#if canImport(lib)
    import lib
#endif
extension ThresholdKey {
    
    /// set tss tag
    ///
    ///
    public func set_tss_tag (tssTag : String) async throws {
        
        try await update_tss_pub_key(tssTag: tssTag)
        
        var errorCode: Int32 = -1
        var tss_tag_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tssTag).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_set_tss_tag(self.pointer, tss_tag_pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey set_tss_tag")
        }
    }
    
    /// set tss tag
    ///
    ///
    public func get_tss_tag () throws -> String{
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_tag(self.pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
        }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    /// fetch tss pub key and assigned to rust
    ///
    ///
    func update_tss_pub_key(tssTag:String?=nil, prefetch:Bool = false) async throws {
        guard let serviceProvider = self.serviceProvider else {
            throw ("service provider is not configured to tss mode")
        }
        if (!serviceProvider.useTss) {
            throw ("service provider is not configured to tss mode")
        }
        
        let tssTag = try tssTag ?? get_tss_tag()
        
        var errorCode: Int32 = -1
        let tss_tag_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tssTag).utf8String)
        var nonce = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_nonce(self.pointer, tss_tag_pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey updateTssPubKey")
        }
        errorCode = -1
        
        if (prefetch) { nonce += 1 }
        
        let nonceString = String(nonce)
        var noncePointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: nonceString).utf8String)
        print(nonceString)
        print("updating.....")
        let result = try await serviceProvider.getTssPubAddress(tssTag: tssTag, nonce: nonceString)
        print(result)
        let resultJson = try JSONEncoder().encode(result)
        guard let resultString = String(data: resultJson, encoding: .utf8) else {
            throw RuntimeError("update_tss_pub_key - Conversion Error - ResultString")
        }
        
        let result_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: resultString).utf8String)
        print(resultString)
        
        let tss_tag_pointer2: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tssTag).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_service_provider_assign_tss_public_key(self.pointer, tss_tag_pointer2, noncePointer, result_pointer, error)})

        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey update_tss_pub_key")
        }
    }
    
    /// Function to retrieve the metadata directly from the network, only used in very specific instances.
    ///
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func create_tagged_tss_share(deviceTssShare: String?, factorPub: String, deviceTssIndex: Int32) throws {
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        var deviceTssSharePointer: UnsafeMutablePointer<Int8>? = nil
        if let deviceTssShare = deviceTssShare {
            deviceTssSharePointer = UnsafeMutablePointer<Int8>(mutating: (deviceTssShare as NSString).utf8String)
        }
        let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (factorPub as NSString).utf8String)
        

        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_create_tagged_tss_share(self.pointer, deviceTssSharePointer, factorPubPointer, deviceTssIndex, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey create_tagged_tss_share")
        }
    }
    
    
    /// Function to retrieve tss share
    ///
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_tss_share(factorKey: String, threshold: Int32 = 0) throws -> (String, String) {
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
               
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_share(self.pointer, factorKeyPointer, threshold, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tss_share")
        }
        let string = String.init(cString: result!)
        string_free(result)
        let splitString = string.split(separator: ",", maxSplits: 2)
        return ( String(splitString[0]), String(splitString[1]))
    }
    
    /// copy tss share with new factor pub ( current factor key is required)
    ///
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func copy_factor_pub(newFactorPub:String, tss_index : Int32, factorKey: String, threshold: Int32 = 0) throws {
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
        let newFactorPubPointer = UnsafeMutablePointer<Int8>(mutating: (newFactorPub as NSString).utf8String)
               
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_copy_factor_pub(self.pointer, newFactorPubPointer, tss_index, factorKeyPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey copy_factor_pub")
        }

    }
    
    
    /// generate new tss share with factor pub
    /// moving from shares n / m -> n / m+1
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func generate_tss_share(input_tss_share: String, tss_input_index: Int32, auth_signatures: [String], new_factor_pub: String, new_tss_index: Int32, selected_servers: [Int32]?=nil) async throws {
        var errorCode: Int32 = -1
        try await update_tss_pub_key(prefetch: true)
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        
        let auth_signatures_json = try JSONSerialization.data(withJSONObject: auth_signatures)
        guard let auth_signatures_str = String(data: auth_signatures_json, encoding: .utf8) else {
            throw RuntimeError("auth signatures error")
        };
        let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (input_tss_share as NSString).utf8String)
        let newFactorPubPointer = UnsafeMutablePointer<Int8>(mutating: (new_factor_pub as NSString).utf8String)
        
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (auth_signatures_str as NSString).utf8String)
        
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selected_servers != nil {
            let selected_servers_json = try JSONSerialization.data(withJSONObject: selected_servers)
            let selected_servers_str = String(data: selected_servers_json, encoding: .utf8)!
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selected_servers_str as NSString).utf8String)
        }

        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_generate_tss_share(self.pointer, inputSharePointer, tss_input_index, new_tss_index, newFactorPubPointer, serversPointer, authSignaturesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_tss_share")
        }
    }
    
    /// delete tss share with factor pub
    /// moving from shares n / m -> n / m-1
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func delete_tss_share(input_tss_share: String, tss_input_index: Int32, auth_signatures: [String], factor_pub: String, selected_servers: [Int32]? = nil) async throws {
        var errorCode: Int32 = -1
        
        try await update_tss_pub_key(prefetch: true)
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        
        let auth_signatures_json = try JSONSerialization.data(withJSONObject: auth_signatures)
        guard let auth_signatures_str = String(data: auth_signatures_json, encoding: .utf8) else {
            throw RuntimeError("auth signatures error")
        };
        let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (input_tss_share as NSString).utf8String)
        let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (factor_pub as NSString).utf8String)
        
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (auth_signatures_str as NSString).utf8String)
        
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selected_servers != nil {
            let selected_servers_json = try JSONSerialization.data(withJSONObject: selected_servers)
            let selected_servers_str = String(data: selected_servers_json, encoding: .utf8)!
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selected_servers_str as NSString).utf8String)
        }
        
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_delete_tss_share(self.pointer, inputSharePointer, tss_input_index, factorPubPointer, serversPointer, authSignaturesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey create_tagged_tss_share")
        }
    }
}
