//
//  MainView.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 22/06/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import UIKit

protocol VideoDelegate {
    func willStartRecording()
    func didFinishRecording()
}

class MainView: UIView {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordingView: UIView!

    // MARK: - Properties
    private var recordingButton: RecordingButton!
    var videoDelegate: VideoDelegate?

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        recordingButton = RecordingButton.init(frame: CGRect.init(x: frame.width/2, y: frame.height/2, width: 60.0, height: 60.0))
        drawRecordingButton()

        addSubview(recordingButton)
    }

    private func drawRecordingButton() {
        recordingButton.center = recordingView.center
        recordingButton.addTarget(self, action: #selector(record), for: .touchDown)
    }

    @objc private func record() {
        print("record")
        recordingButton.recordingState = .recording
        recordingButton.removeTarget(self, action: #selector(record), for: .touchDown)
        recordingButton.addTarget(self, action: #selector(stop), for: .touchDown)

        if let delegate = videoDelegate {
            delegate.willStartRecording()
        }
    }

    @objc private func stop() {
        print("stop")
        recordingButton.recordingState = .stopped

        if let delegate = videoDelegate {
            delegate.didFinishRecording()
        }

        recordingButton.removeTarget(self, action: #selector(stop), for: .touchDown)
        recordingButton.addTarget(self, action: #selector(record), for: .touchDown)
    }

}
