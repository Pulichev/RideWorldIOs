//
//  ReadMoreTextView.swift
//  ReadMoreTextView
//
//  Created by Ilya Puchka on 06.04.15.
//  Copyright (c) 2015 - 2016 Ilya Puchka. All rights reserved.
//

import UIKit

extension UITextView {
    
    /**
     Calls provided `test` block if point is in gliph range and there is no link detected at this point.
     Will pass in to `test` a character index that corresponds to `point`.
     Return `self` in `test` if text view should intercept the touch event or `nil` otherwise.
     */
    public func hitTest(pointInGliphRange aPoint: CGPoint, event: UIEvent?, test: (Int) -> UIView?) -> UIView? {
        guard let charIndex = charIndexForPointInGlyphRect(point: aPoint) else {
            #if swift(>=3.0)
                return super.hitTest(aPoint, with: event)
            #else
                return super.hitTest(aPoint, withEvent: event)
            #endif
        }
        #if swift(>=3.0)
            guard textStorage.attribute(NSLinkAttributeName, at: charIndex, effectiveRange: nil) == nil else {
                return super.hitTest(aPoint, with: event)
            }
        #else
            guard textStorage.attribute(NSLinkAttributeName, atIndex: charIndex, effectiveRange: nil) == nil else {
                return super.hitTest(aPoint, withEvent: event)
            }
        #endif
        return test(charIndex)
    }
    
    /**
     Returns true if point is in text bounding rect adjusted with padding.
     Bounding rect will be enlarged with positive padding values and decreased with negative values.
     */
    public func pointIsInTextRange(point aPoint: CGPoint, range: NSRange, padding: UIEdgeInsets) -> Bool {
        var boundingRect = layoutManager.boundingRectForCharacterRange(range: range, inTextContainer: textContainer)
        boundingRect = boundingRect.offsetBy(dx: textContainerInset.left, dy: textContainerInset.top)
        boundingRect = boundingRect.insetBy(dx: -(padding.left + padding.right), dy: -(padding.top + padding.bottom))
        return boundingRect.contains(aPoint)
    }
    
    /**
     Returns index of character for glyph at provided point. Returns `nil` if point is out of any glyph.
     */
    public func charIndexForPointInGlyphRect(point aPoint: CGPoint) -> Int? {
        let point = CGPoint(x: aPoint.x, y: aPoint.y - textContainerInset.top)
        #if swift(>=3.0)
            let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
            let glyphRect = layoutManager.boundingRect(forGlyphRange: NSMakeRange(glyphIndex, 1), in: textContainer)
            if glyphRect.contains(point) {
                return layoutManager.characterIndexForGlyph(at: glyphIndex)
            } else {
                return nil
            }
        #else
            let glyphIndex = layoutManager.glyphIndexForPoint(point, inTextContainer: textContainer)
            let glyphRect = layoutManager.boundingRectForGlyphRange(NSMakeRange(glyphIndex, 1), inTextContainer: textContainer)
            if CGRectContainsPoint(glyphRect, point) {
                return layoutManager.characterIndexForGlyphAtIndex(glyphIndex)
            }
            else {
                return nil
            }
        #endif
    }
    
}

extension NSLayoutManager {
    
    /**
     Returns characters range that completely fits into container.
     */
    public func characterRangeThatFits(textContainer container: NSTextContainer) -> NSRange {
        #if swift(>=3.0)
            var rangeThatFits = self.glyphRange(for: container)
            rangeThatFits = self.characterRange(forGlyphRange: rangeThatFits, actualGlyphRange: nil)
        #else
            var rangeThatFits = self.glyphRangeForTextContainer(container)
            rangeThatFits = self.characterRangeForGlyphRange(rangeThatFits, actualGlyphRange: nil)
        #endif
        return rangeThatFits
    }
    
    /**
     Returns bounding rect in provided container for characters in provided range.
     */
    public func boundingRectForCharacterRange(range aRange: NSRange, inTextContainer container: NSTextContainer) -> CGRect {
        #if swift(>=3.0)
            let glyphRange = self.glyphRange(forCharacterRange: aRange, actualCharacterRange: nil)
            let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: container)
        #else
            let glyphRange = self.glyphRangeForCharacterRange(aRange, actualCharacterRange: nil)
            let boundingRect = self.boundingRectForGlyphRange(glyphRange, inTextContainer: container)
        #endif
        return boundingRect
    }
    
}
