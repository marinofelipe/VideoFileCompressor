//
//  RecordingButton.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 23/06/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import UIKit

enum RecordingState: Int {
    case recording
    case stopped
}

class RecordingButton: UIButton {

    // MARK: Properties
    var color = UIColor.red
    private var circleLayer: CALayer!
    private var circleBorder: CALayer!
    var recordingState: RecordingState = .stopped {
        didSet {
            animateButtonBorder()
            animateButtonState()
        }
    }

    override func draw(_ rect: CGRect) {
        circleLayer = CALayer()
        circleLayer.backgroundColor = UIColor.red.cgColor
        circleLayer.bounds = CGRect(x: 0, y: 0, width: frame.size.width / 1.3, height: frame.size.height / 1.3)
        circleLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        circleLayer.cornerRadius = (frame.size.width / 1.3) / 2

        circleBorder = CALayer()
        circleBorder.backgroundColor = UIColor.clear.cgColor
        circleBorder.borderWidth = 1.5
        circleBorder.borderColor = UIColor.red.cgColor
        circleBorder.bounds = CGRect(x: 0, y: 0, width: bounds.size.width - 1.5, height: bounds.size.height - 1.5)
        circleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        circleBorder.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        circleBorder.cornerRadius = frame.size.width / 2

        layer.insertSublayer(circleLayer, at: 0)
        layer.insertSublayer(circleBorder, at: 0)
    }

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: State handlers
    private func animateButtonBorder() {
        self.circleLayer.contentsGravity    = "center"

        let borderColor: CABasicAnimation   = CABasicAnimation(keyPath: "borderColor")
        borderColor.duration                = 0.15
        borderColor.fillMode                = kCAFillModeForwards
        borderColor.isRemovedOnCompletion     = false

        let borderScale                     = CABasicAnimation(keyPath: "transform.scale")
        borderScale.fromValue               = recordingState == .recording ? 1.0 : 0.88
        borderScale.toValue                 = recordingState == .recording ? 0.88 : 1.0
        borderScale.duration                = 0.15
        borderScale.fillMode                = kCAFillModeForwards
        borderScale.isRemovedOnCompletion     = false

        let borderAnimations                    = CAAnimationGroup()
        borderAnimations.isRemovedOnCompletion    = false
        borderAnimations.fillMode               = kCAFillModeForwards
        borderAnimations.duration               = 0.15
        borderAnimations.animations             = [borderColor, borderScale]

        circleBorder.add(borderAnimations, forKey: "borderAnimations")
    }

    private func animateButtonState() {
        self.circleLayer.contentsGravity    = "center"

        let scale                   = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue             = recordingState == .recording ? 1.0 : 0.88
        scale.toValue               = recordingState == .recording ? 0.88 : 1
        scale.duration              = 0.15
        scale.fillMode              = kCAFillModeForwards
        scale.isRemovedOnCompletion   = false

        let color                   = CABasicAnimation(keyPath: "backgroundColor")
        color.duration              = 0.15
        color.fillMode              = kCAFillModeForwards
        color.isRemovedOnCompletion   = false
        color.toValue               = UIColor.red.cgColor

        var square: CAKeyframeAnimation!
        if recordingState == .recording {

            scale.fromValue             = recordingState == .recording ? 1.0 : 0.68
            scale.toValue               = recordingState == .recording ? 0.68 : 1

            square                       = CAKeyframeAnimation(keyPath: "cornerRadius")
            square.duration              = 0.15
            square.fillMode              = kCAFillModeForwards
            square.isRemovedOnCompletion   = false
            square.path                  = recordingState == .recording ? squarePath(center: CGPoint.zero, side: 0).cgPath : circlePath(center: CGPoint.zero, radius: 90).cgPath
        } else {

            square                       = CAKeyframeAnimation(keyPath: "pathGuide")
            square.duration              = 0.15
            square.fillMode              = kCAFillModeForwards
            square.isRemovedOnCompletion   = false
            square.path                  = circlePath(center: CGPoint(x: 0, y: 0), radius: 90).cgPath
        }

        let circleAnimations                    = CAAnimationGroup()
        circleAnimations.isRemovedOnCompletion    = false
        circleAnimations.fillMode               = kCAFillModeForwards
        circleAnimations.duration               = 0.15
        circleAnimations.animations             = [scale, color, square]

        self.circleLayer.add(circleAnimations, forKey: "circleAnimations")
    }

    func squarePath(center: CGPoint, side: CGFloat) -> UIBezierPath {
        let squarePath = UIBezierPath()
        let startX = center.x - side / 2
        let startY = center.y - side / 2
        squarePath.move(to: CGPoint(x: startX, y: startY))
        squarePath.addLine(to: squarePath.currentPoint)
        squarePath.addLine(to: CGPoint(x: startX + side, y: startY))
        squarePath.addLine(to: squarePath.currentPoint)
        squarePath.addLine(to: CGPoint(x: startX + side, y: startY + side))
        squarePath.addLine(to: squarePath.currentPoint)
        squarePath.addLine(to: CGPoint(x: startX, y: startY + side))
        squarePath.addLine(to: squarePath.currentPoint)
        squarePath.close()
        return squarePath
    }

    func circlePath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let circlePath = UIBezierPath()
        circlePath.addArc(withCenter: center, radius: radius, startAngle: -CGFloat.pi, endAngle: -CGFloat(M_PI/2), clockwise: true)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: -CGFloat(M_PI/2), endAngle: 0, clockwise: true)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI/2), clockwise: true)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: CGFloat(M_PI/2), endAngle: CGFloat.pi, clockwise: true)
        circlePath.close()
        return circlePath
    }
}
