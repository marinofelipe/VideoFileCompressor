//
//  ViewController.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 22/06/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private var mainView: MainView {
        return self.view as! MainView
    }
    private var session: AVCaptureSession?
    internal var movieOutput : AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Record Movie"
        
        setCamera()
        mainView.videoDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: CAMERA
    private func setCamera() {
        
        
        CameraStatus.checkIfCameraIsAuthorized { (cameraStatus) in
            
            if cameraStatus == .authorized {
                CameraUtil().settingAVCaptureSessionCamera(completion: { (session, movieOutput, previewLayer) in
                    
                    guard let viewLayer = previewLayer else { return }
                    guard let session   = session else { return }
                    guard let output    = movieOutput else { return }
                    
                    viewLayer.frame = self.mainView.cameraView.bounds

                    self.mainView.cameraView.layer.addSublayer(viewLayer)
                    self.movieOutput = output
                    self.session = session
                    
                    session.commitConfiguration()
                    session.startRunning()
                })
            }
        }
    }
}

extension ViewController: VideoDelegate {
    
    func willStartRecording() {
        let name = "Video\(arc4random_uniform(100))"
        if let url = CameraUtil().tempPathMovie(fileName: name) {
            movieOutput.startRecording(toOutputFileURL: url, recordingDelegate: self)
        }
    }
    
    func didFinishRecording() {
        print("didFinishRecroding")
        movieOutput.stopRecording()
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("didStartRecordingToOutputFile")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("didFinishRecordingToOutputFile")
    }
}

