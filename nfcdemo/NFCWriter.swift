//
//  NFCWriter.swift
//  nfcdemo
//
//  Created by Hitesh Thummar on 09/10/23.
//

import SwiftUI
import CoreNFC

struct NFCWriter: View {
    @State var writeData = ""
    @State private var readData = ""

    var body: some View {
        VStack{
            TextField("Text to write", text: $writeData)
                .textFieldStyle(.roundedBorder)
                .padding()
            Button {
                NFCReadWrite().scan(withData: writeData)
            } label: {
                Text("Write")
            }
        } .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NFCDataReceived"))) { notification in
            if let data = notification.userInfo?["data"] as? String {
                self.readData = data
            }
        }
    }
       
}

struct NFCWriter_Previews: PreviewProvider {
    static var previews: some View {
        NFCWriter()
    }
}






class NFCReadWrite: NSObject,NFCNDEFReaderSessionDelegate{
    
    var dataToWrite = ""
    var nfcSession:NFCNDEFReaderSession?
    var dataFromNFC = ""
    func scan(withData:String){
        
        guard NFCReaderSession.readingAvailable else {
            return
        }
                
        nfcSession = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false // set true if read mode
        )
        nfcSession?.alertMessage = "Hold NFC card near iPhone"
        nfcSession?.begin()
    }
    
    
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        print("Detected tags with \(messages.count) messages")
        
        for message in messages
        {
            for record in message.records
            {
                if record.typeNameFormat == .nfcWellKnown
                {
                    let val = record.wellKnownTypeTextPayload()
                    print(val)
                    if let s = val.0,!s.isEmpty,let v = val.0
                    {
                        dataFromNFC = v
                        NotificationCenter.default.post(name: Notification.Name("NFCDataReceived"), object: nil, userInfo: ["data": dataFromNFC])

                    }
                }
            }
        }
        session.invalidate()
    }

    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        
        // 1
        guard tags.count == 1 else {
            session.invalidate(errorMessage: "Cannot Write More Than One Tag in NFC")
            return
        }
        let currentTag = tags.first!
        
        // 2
        session.connect(to: currentTag) { error in
            
            guard error == nil else {
                session.invalidate(errorMessage: "cound not connect to NFC card")
                return
            }
            
            // 3
            currentTag.queryNDEFStatus { status, capacity, error in
                
                guard error == nil else {
                    session.invalidate(errorMessage: "Write error")
                    return
                }
                
                switch status {
                case .notSupported: session.invalidate(errorMessage: "")
                case .readOnly:     session.invalidate(errorMessage: "")
                case .readWrite:
                    
                    let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                        string: self.dataToWrite,
                        locale: Locale.init(identifier: "en")

                    )!
                    
                    let uriPayloadFromURL = NFCNDEFPayload.wellKnownTypeURIPayload(
                        url: URL(string: "http://www.google.com")!
                    )!
                    
                    let messge = NFCNDEFMessage.init(
                        records: [
                            uriPayloadFromURL,
                            textPayload
                        ]
                    )
                    currentTag.writeNDEF(messge) { error in
                        
                        if error != nil {
                            session.invalidate(errorMessage: "Fail to write nfc card")
                        } else {
                            session.alertMessage = "Successfully writtern"
                            session.invalidate()
                        }
                    }
                    
                @unknown default:   session.invalidate(errorMessage: "unknown error")
                }
            }
        }
    }
}


