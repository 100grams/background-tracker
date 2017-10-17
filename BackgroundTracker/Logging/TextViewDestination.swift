//
//  TextViewDestination.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 03/05/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import Foundation
import XCGLogger

// MARK: - TextViewDestination
/// A logger destination that outputs log details to a UITextView

open class TextViewDestination : BaseQueuedDestination {

    private var _textView : UITextView?
    
    // MARK: - Life Cycle
    public init(owner: XCGLogger? = nil, identifier: String = "", textView: UITextView) {
        
        super.init(owner: owner, identifier: identifier)
        _textView = textView
    }

    open override func write(message: String) {
        if let textView = _textView {
            DispatchQueue.main.async {
                let text = textView.text ?? ""
                textView.text = text + "\n\n" + message
                
                // scroll to the bottom to show new message
                var offset = textView.contentOffset
                offset.y = textView.contentSize.height + textView.contentInset.bottom - textView.bounds.size.height
                textView.setContentOffset(offset, animated: true)
            }
        }
    }
    
}
