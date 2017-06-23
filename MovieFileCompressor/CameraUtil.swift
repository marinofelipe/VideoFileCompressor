//
//  CameraUtil.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 22/06/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CameraSession = (
    _ session: AVCaptureSession?,
    _ movieOutput: AVCaptureMovieFileOutput?,
    _ previewLayer:AVCaptureVideoPreviewLayer?) -> ()

public class CameraUtil: NSObject {
    
    //MARK: - Private Properties
    private let KTempPathMovie  : String                        = "movie"
    private let KPathExtension  : String                        = "mov"
    
    private var session         : AVCaptureSession              = AVCaptureSession()
    private var input           : AVCaptureDeviceInput?         = nil
    private var audioInput      : AVCaptureDeviceInput?         = nil
    private var output          : AVCaptureStillImageOutput?    = AVCaptureStillImageOutput()
    private var previewLayer    : AVCaptureVideoPreviewLayer?   = AVCaptureVideoPreviewLayer()
    private var movieOutput     : AVCaptureMovieFileOutput      = AVCaptureMovieFileOutput()
    
    //MARK: - Methods
    public func settingAVCaptureSessionCamera (completion: CameraSession) {
        
        let camera      = self.device(position: .front)
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {
            input          = try AVCaptureDeviceInput(device: camera)
            audioInput     = try AVCaptureDeviceInput(device: audioDevice)
            
        } catch { completion(nil, nil, nil) }
        
        if self.session.canAddInput(self.input) == true {
            
            session.addInput(self.input)
            session.addInput(self.audioInput)
        }
        
        output?.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        if session.canAddOutput(output) == true {
            
            session.sessionPreset = AVCaptureSessionPresetHigh
            session.addOutput(movieOutput)
            session.addOutput(output)
        }
        
        previewLayer                               = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity                 = AVLayerVideoGravityResizeAspectFill
        previewLayer?.connection.videoOrientation  = .portrait
        
        completion(session, movieOutput, previewLayer)
    }
    
    private func device(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices:[AnyObject] = AVCaptureDevice.devices() as [AnyObject]
        
        for device in devices {
            
            let dev = device as! AVCaptureDevice
            if dev.position == position { return dev }
        }
        return nil
    }
    
    public func tempPathMovie (fileName: String) -> URL? {
        
        let path = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(KPathExtension).absoluteString
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
                
            } catch { print("") }
        }
        
        if let url = URL(string: path) {
            return url
        }
        
        return nil
    }
}
