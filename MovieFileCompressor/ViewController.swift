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
                print("Authorized")
            }
        }

    }
}

