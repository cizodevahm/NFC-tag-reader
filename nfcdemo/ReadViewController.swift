//
//  ReadViewController.swift
//  nfcdemo
//
//  Created by Hitesh Thummar on 14/10/23.
//

import UIKit
import CoreNFC

class ReadViewController: UIViewController,NFCNDEFReaderSessionDelegate {

    var session: NFCNDEFReaderSession?
    @IBOutlet weak var lblData: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    @IBAction func btnScan(_ sender: UIButton) {
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

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        session?.begin()
        
    }
    
    
    // MARK: - NFCNDEFReaderSessionDelegate

    /// - Tag: processingTagData
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
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
                        DispatchQueue.main.async {
                            self.lblData.text = v
                        }
                    }
                }
            }
        }
    }

    /// - Tag: processingNDEFTag
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    return
                } else if nil != error {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = "Fail to read NDEF from tag"
                    } else {
                        statusMessage = "Found 1 NDEF message"
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            
                            for record in message!.records
                            {
                                DispatchQueue.main.async {
                                    switch record.typeNameFormat {
                                    case .nfcWellKnown:
                                        if let url = record.wellKnownTypeURIPayload() {
                                            self.lblData.text = url.absoluteString
                                        }
                                    case .absoluteURI:
                                        if let text = String(data: record.payload, encoding: .utf8) {
                                            self.lblData.text = text
                                        }
                                    case .media:
                                        if let type = String(data: record.type, encoding: .utf8) {
                                            self.lblData.text = type
                                        }
                                    case .nfcExternal, .empty, .unknown, .unchanged:
                                        fallthrough
                                    @unknown default:
                                        self.lblData.text = record.typeNameFormat.rawValue.description
                                    }
                                }
                            }
                        }
                    }
                    
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
    }
    
    /// - Tag: sessionBecomeActive
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "Session Invalidated",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }

        // To read new tags, a new session instance is required.
        self.session = nil
    }


}
