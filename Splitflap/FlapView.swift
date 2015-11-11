/*
 * Splitflap
 *
 * Copyright 2015-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit
import QuartzCore

/**
 A Flap view aims to display given tokens with by rotating its tiles to show the
 desired character or graphic.
*/
final class FlapView: UIView {
  private var topTicTile    = Tile(position: .Top)
  private var bottomTicTile = Tile(position: .Bottom)
  private var topTacTile    = Tile(position: .Top)
  private var bottomTacTile = Tile(position: .Bottom)

  private enum AnimationTime {
    case Tic
    case Tac
  }

  private var animationTime = AnimationTime.Tac

  var tokens: [String] = [] {
    didSet {
      tokenGenerator = TokenGenerator(tokens: tokens)
    }
  }
  private var tokenGenerator = TokenGenerator(tokens: [])
  private var targetToken: String?

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupViews()
    setupAnimations()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    setupViews()
    setupAnimations()
  }

  // MARK: - Initializing the Flap View

  private func setupViews() {
    addSubview(topTicTile)
    addSubview(bottomTicTile)
    addSubview(topTacTile)
    addSubview(bottomTacTile)

    topTicTile.layer.anchorPoint    = CGPointMake(0.5, 1.0)
    bottomTicTile.layer.anchorPoint = CGPointMake(0.5, 0)
    topTacTile.layer.anchorPoint    = CGPointMake(0.5, 1.0)
    bottomTacTile.layer.anchorPoint = CGPointMake(0.5, 0)

    updateWithToken(tokenGenerator.firstToken, animated: false)
  }

  // MARK: - Settings the Animations

  private let topAnim    = CABasicAnimation(keyPath: "transform")
  private let bottomAnim = CABasicAnimation(keyPath: "transform")

  private func setupAnimations() {
    // Set perspective
    let zDepth: CGFloat         = 1000
    var skewedIdentityTransform = CATransform3DIdentity
    skewedIdentityTransform.m34 = 1 / -zDepth

    // Predefine the animation
    topAnim.fromValue = NSValue(CATransform3D: skewedIdentityTransform)
    topAnim.toValue   = NSValue(CATransform3D: CATransform3DRotate(skewedIdentityTransform, -CGFloat(M_PI_2), 1, 0, 0))
    topAnim.removedOnCompletion = false
    topAnim.fillMode            = kCAFillModeForwards
    topAnim.timingFunction      = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)

    bottomAnim.fromValue = NSValue(CATransform3D: CATransform3DRotate(skewedIdentityTransform, CGFloat(M_PI_2), 1, 0, 0))
    bottomAnim.toValue   = NSValue(CATransform3D: skewedIdentityTransform)
    bottomAnim.delegate            = self
    bottomAnim.removedOnCompletion = true
    bottomAnim.fillMode            = kCAFillModeBoth
    bottomAnim.timingFunction      = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let topLeafFrame    = CGRectMake(0, 0, bounds.width, bounds.height / 2)
    let bottomLeafFrame = CGRectMake(0, bounds.height / 2, bounds.width, bounds.height / 2)

    topTicTile.frame    = topLeafFrame
    bottomTicTile.frame = bottomLeafFrame
    topTacTile.frame    = topLeafFrame
    bottomTacTile.frame = bottomLeafFrame
  }

  func displayToken(token: String?, rotationDuration: Double) {
    let sanitizedToken = token ?? tokenGenerator.firstToken

    if rotationDuration > 0 {
      topAnim.duration    = rotationDuration / 4 * 3
      bottomAnim.duration = rotationDuration / 4

      targetToken = sanitizedToken

      displayNextToken()
    }
    else {
      tokenGenerator.currentElement = sanitizedToken
      
      updateWithToken(sanitizedToken, animated: false)
    }
  }

  private func displayNextToken() {
    guard tokenGenerator.currentElement != targetToken else {
      return
    }

    if let token = tokenGenerator.next() {
      updateWithToken(token, animated: true)
    }
  }

  private func updateWithToken(token: String, animated: Bool) {
    let topBack     = animationTime == .Tic ? topTicTile : topTacTile
    let bottomBack  = animationTime == .Tic ? bottomTicTile : bottomTacTile
    let topFront    = animationTime == .Tic ? topTacTile : topTicTile
    let bottomFront = animationTime == .Tic ? bottomTacTile : bottomTicTile

    topBack.symbol    = token
    bottomBack.symbol = token

    topBack.layer.removeAllAnimations()
    bottomBack.layer.removeAllAnimations()
    topFront.layer.removeAllAnimations()
    bottomFront.layer.removeAllAnimations()

    if animated {
      bringSubviewToFront(topFront)
      bringSubviewToFront(bottomBack)

      // Animation
      topAnim.beginTime = CACurrentMediaTime()
      topFront.layer.addAnimation(topAnim, forKey: "topDownFlip")

      bottomAnim.beginTime = topAnim.beginTime + topAnim.duration
      bottomBack.layer.addAnimation(bottomAnim, forKey: "bottomDownFlip")
    }
    else {
      bringSubviewToFront(topBack)
      bringSubviewToFront(bottomBack)

      animationTime = animationTime == .Tic ? .Tac : .Tic
    }
  }

  // MARK: - CAAnimation Delegate Methods

  override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
    animationTime = animationTime == .Tic ? .Tac : .Tic
    
    displayNextToken()
  }
}