//
//  ViewController.swift
//  nfcdemo
//
//  Created by Hitesh Thummar on 03/10/23.
//

import UIKit
import CoreNFC

class WriteViewController: UIViewController {

    @IBOutlet weak var txtWrite: UITextField!
    
    @IBOutlet weak var btnWrite: UIButton!
    var textToWrite = ""
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func btnWrite(_ sender: UIButton) {
        textToWrite = txtWrite.text!
        
        guard NFCReaderSession.readingAvailable else {
            return
        }
        
        
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false // set true if read mode
        )
        
        // 2
        session.alertMessage = "Hold NFC card near iPhone"
        
        // 3
        session.begin()
        
    }
    
    @IBAction func btnReadNFC(_ sender: UIButton) {
        guard NFCNDEFReaderSession.readingAvailable else {
                let alertController = UIAlertController(
                    title: "Scanning Not Supported",
                    message: "This device doesn't support tag scanning.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }

      
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session.alertMessage = "Hold your iPhone near the item to learn more about it."
        session.begin()
    }
}


@available(iOS 13.0, *)
extension WriteViewController:NFCNDEFReaderSessionDelegate{
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        print("Detected tags with \(messages.count) messages")
        

//        session.invalidate()
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
                        string: self.textToWrite,
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

