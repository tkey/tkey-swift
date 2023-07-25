//
//  File.swift
//  
//
//  Created by CW Lee on 21/07/2023.
//

import Foundation


import Foundation
#if canImport(lib)
    import lib
#endif

public final class TssModule {
    var tss_tag = "default"
    var threshold_key : ThresholdKey
    
    init(threshold_key: ThresholdKey, tss_tag: String) async throws{
        self.tss_tag = tss_tag;
        self.threshold_key = threshold_key;
        try self.set_tss_tag(tss_tag: tss_tag)
        
        try await self.update_tss_pub_key()
    }

    /// set tss tag
    ///
    ///
    public func set_tss_tag ( tss_tag : String) throws {
        var errorCode: Int32 = -1
        var tss_tag_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tss_tag).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_set_tss_tag(threshold_key.pointer, tss_tag_pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey set_tss_tag")
        }
    }
    
    /// get tss tag
    ///
    ///
    public func get_tss_tag () throws -> String{
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_tag(threshold_key.pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
        }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    
    /// get all  tss tag
    ///
    ///
    public func get_all_tss_tag () throws -> [String]{
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_tag(threshold_key.pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
        }
        let string = String.init(cString: result!)
        string_free(result)
        guard let data = string.data(using: .utf8) else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }
        guard let result_vec = try JSONSerialization.jsonObject(with: data ) as? [String] else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }
        
        return result_vec
    }
    
    /// get tss pub key
    ///
    ///
    public func get_tss_pub_key () throws -> String{
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_public_key(threshold_key.pointer, error )})
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
    func update_tss_pub_key(prefetch:Bool = false) async throws {
        guard let serviceProvider = threshold_key.serviceProvider else {
            throw ("service provider is not configured to tss mode")
        }
        if (!serviceProvider.useTss) {
            throw ("service provider is not configured to tss mode")
        }
        
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        let tss_tag_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.tss_tag).utf8String)
        var nonce = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_nonce(threshold_key.pointer, tss_tag_pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey updateTssPubKey")
        }
        errorCode = -1
        
        if (prefetch) { nonce += 1 }
        
        let nonceString = String(nonce)
        let noncePointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: nonceString).utf8String)
        let result = try await serviceProvider.getTssPubAddress(tssTag: self.tss_tag, nonce: nonceString)
        let resultJson = try JSONEncoder().encode(result)
        guard let resultString = String(data: resultJson, encoding: .utf8) else {
            throw RuntimeError("update_tss_pub_key - Conversion Error - ResultString")
        }
        
        let result_pointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: resultString).utf8String)
        print(resultString)
        
        let tss_tag_pointer2: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.tss_tag).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_service_provider_assign_tss_public_key(threshold_key.pointer, tss_tag_pointer2, noncePointer, result_pointer, error)})

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
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        var deviceTssSharePointer: UnsafeMutablePointer<Int8>? = nil
        if let deviceTssShare = deviceTssShare {
            deviceTssSharePointer = UnsafeMutablePointer<Int8>(mutating: (deviceTssShare as NSString).utf8String)
        }
        let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (factorPub as NSString).utf8String)
        

        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_create_tagged_tss_share(threshold_key.pointer, deviceTssSharePointer, factorPubPointer, deviceTssIndex, curvePointer, error)
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
        if (factorKey.count > 66) {throw RuntimeError ("Invalid factor Key");}
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
               
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_share(threshold_key.pointer, factorKeyPointer, threshold, curvePointer, error)
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
    public func copy_factor_pub(factorKey: String,  newFactorPub:String, tss_index : Int32, threshold: Int32 = 0) throws {
        if (factorKey.count > 66) {throw RuntimeError ("Invalid factor Key");}
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
        let newFactorPubPointer = UnsafeMutablePointer<Int8>(mutating: (newFactorPub as NSString).utf8String)
               
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_copy_factor_pub(threshold_key.pointer, newFactorPubPointer, tss_index, factorKeyPointer, curvePointer, error)
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
        try self.set_tss_tag(tss_tag: self.tss_tag)
        
        var errorCode: Int32 = -1
        try await self.update_tss_pub_key(prefetch: true)
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        
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
            threshold_key_generate_tss_share(threshold_key.pointer, inputSharePointer, tss_input_index, new_tss_index, newFactorPubPointer, serversPointer, authSignaturesPointer, curvePointer, error)
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
    internal func delete_tss_share_internal(input_tss_share: String, tss_input_index: Int32, auth_signatures: [String], delete_factor_pub: String, selected_servers: [Int32]? = nil) throws {
        try self.set_tss_tag(tss_tag: self.tss_tag)
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        
        let auth_signatures_json = try JSONSerialization.data(withJSONObject: auth_signatures)
        guard let auth_signatures_str = String(data: auth_signatures_json, encoding: .utf8) else {
            throw RuntimeError("auth signatures error")
        };
        let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (input_tss_share as NSString).utf8String)
        let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (delete_factor_pub as NSString).utf8String)
        
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (auth_signatures_str as NSString).utf8String)
        
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selected_servers != nil {
            let selected_servers_json = try JSONSerialization.data(withJSONObject: selected_servers)
            let selected_servers_str = String(data: selected_servers_json, encoding: .utf8)!
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selected_servers_str as NSString).utf8String)
        }
        
        withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_delete_tss_share(threshold_key.pointer, inputSharePointer, tss_input_index, factorPubPointer, serversPointer, authSignaturesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey delete tss share")
        }
    }
    
    /// delete tss share with factor pub
    /// moving from shares n / m -> n / m-1
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func delete_tss_share(input_tss_share: String, tss_input_index: Int32, auth_signatures: [String], delete_factor_pub: String, selected_servers: [Int32]? = nil) async throws {

        try await self.update_tss_pub_key(prefetch: true)
        try self.delete_tss_share_internal(input_tss_share: input_tss_share, tss_input_index: tss_input_index, auth_signatures: auth_signatures, delete_factor_pub: delete_factor_pub, selected_servers: selected_servers)
        

    }
    
    
    /// add factor pub
    /// moving from shares n / m -> n / m+1
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func add_factor_pub( factor_key: String, auth_signatures: [String], new_factor_pub: String, new_tss_index: Int32, selected_servers: [Int32]?=nil) async throws {
        if (factor_key.count > 66) {throw RuntimeError ("Invalid factor Key");}
        try self.set_tss_tag(tss_tag: self.tss_tag)

        let (tss_index, tss_share) = try self.get_tss_share(factorKey: factor_key)
        try await self.generate_tss_share(input_tss_share: tss_share, tss_input_index: Int32(tss_index)!, auth_signatures: auth_signatures, new_factor_pub: new_factor_pub, new_tss_index: new_tss_index, selected_servers: selected_servers)
    }
    
    
    /// delete tss share with factor pub
    /// moving from shares n / m -> n / m-1
    /// - Parameters:
    ///
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func delete_factor_pub(factor_key: String, auth_signatures: [String], delete_factor_pub: String, selected_servers: [Int32]? = nil) async throws {
        threshold_key.tkeyQueue
        if (factor_key.count > 66) {throw RuntimeError ("Invalid factor Key");}
        try self.set_tss_tag(tss_tag: self.tss_tag)

        let (tss_index, tss_share) = try self.get_tss_share(factorKey: factor_key)
        try await self.delete_tss_share(input_tss_share: tss_share, tss_input_index: Int32(tss_index)!, auth_signatures: auth_signatures, delete_factor_pub: delete_factor_pub, selected_servers: selected_servers)
    }
}
