//
//  WebViewController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
  
  @IBOutlet weak var textView: UITextView!
  var fileNameString: String = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    switch fileNameString {
    case "Contacts info":
      textView.text = NSLocalizedString("Contacts info", comment: "")
      break
    case "ToU":
      openRtf(withName: NSLocalizedString("ToU", comment: ""))
      break
    case "PP":
      openRtf(withName: NSLocalizedString("PP", comment: ""))
      break
    default:
      break
    }
  }
  
  private func openRtf(withName name: String) {
    if let rtfPath = Bundle.main.url(forResource: name, withExtension: "rtf") {
      do {
        let attributedStringWithRtf: NSAttributedString =
          try NSAttributedString(url: rtfPath,
                                 options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
                                 documentAttributes: nil)
        
        self.textView.attributedText = attributedStringWithRtf
      } catch let error {
        print("Got an error \(error)")
      }
    }
  }
}
