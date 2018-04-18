//
//  NSScriptCommand+Evergreen.swift
//  Evergreen
//
//  Created by Olof Hellman on 3/4/18.
//  Copyright © 2018 Olof Hellman. All rights reserved.
//

import Foundation
import Account

extension NSScriptCommand {
    func property(forKey key:String) -> Any? {
        if let evaluatedArguments = self.evaluatedArguments  {
            if let props = evaluatedArguments["KeyDictionary"] as? [String: Any] {
                return props[key] 
            }
        }
        return nil
    }
    
    func isCreateCommand(forClass whatClass:String) -> Bool {
        guard let arguments = self.arguments else {return false}
        guard let newObjectClass = arguments["ObjectClass"] as? Int else {return false}
        guard (newObjectClass.FourCharCode() == whatClass.FourCharCode()) else {return false}
        return true
    }

    func accountAndFolderForNewChild() -> (Account, Folder?) {
        let appleEvent = self.appleEvent
        var account = AccountManager.shared.localAccount
        var folder:Folder? = nil
        if let appleEvent = appleEvent {
            var descriptorToConsider:NSAppleEventDescriptor?
            if let insertionLocationDescriptor = appleEvent.paramDescriptor(forKeyword:keyAEInsertHere) {
                 print("insertionLocation : \(insertionLocationDescriptor)")
                 // insertion location can be a typeObjectSpecifier, e.g.  'in account "Acct"'
                 // or a typeInsertionLocation, e.g.   'at end of folder "
                 if (insertionLocationDescriptor.descriptorType == "insl".FourCharCode())  {
                     descriptorToConsider = insertionLocationDescriptor.forKeyword("kobj".FourCharCode())
                 } else if ( insertionLocationDescriptor.descriptorType == "obj ".FourCharCode())  {
                     descriptorToConsider = insertionLocationDescriptor
                 }
            } else if let subjectDescriptor = appleEvent.attributeDescriptor(forKeyword:"subj".FourCharCode()) {
                descriptorToConsider = subjectDescriptor
            }
            
            if let descriptorToConsider = descriptorToConsider {
                guard let newContainerSpecifier = NSScriptObjectSpecifier(descriptor:descriptorToConsider) else {return (account, folder)}
                let newContainer = newContainerSpecifier.objectsByEvaluatingSpecifier
                if let scriptableAccount = newContainer as? ScriptableAccount {
                    account = scriptableAccount.account
                } else if let scriptableFolder = newContainer as? ScriptableFolder {
                    if let folderAccount = scriptableFolder.folder.account {
                        folder = scriptableFolder.folder
                        account = folderAccount
                    }
                }
            }
        }
        return (account, folder)
    }
}
