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

    @IBOutlet weak var recordingView: UIView!
    
    private var session: AVCaptureSession?
    private var movieOutput : AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Record Movie"
        
        setCamera()
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
                    
                    viewLayer.frame = self.recordingView.bounds

                    self.recordingView.layer.addSublayer(viewLayer)
                    self.movieOutput = output
                    self.session = session
                    
                    session.commitConfiguration()
                    session.startRunning()
                })
            }
        }

    }
}

