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
    
    public func convertVideoToLowQuality(withInputURL inputURL: URL, outputURL: URL, bitRate: Int, handler: @escaping (_ compressedURL: URL) -> Void) {
        var videoAsset: AVURLAsset? = AVURLAsset(url: inputURL, options: nil)
        var videoTrack: AVAssetTrack?  = videoAsset!.tracks(withMediaType: AVMediaTypeVideo)[0]
        //        let videoSize = videoTrack.naturalSize
        var videoWriterCompressionSettings: Dictionary? = [
            AVVideoAverageBitRateKey : Int(bitRate)
        ]
        
        var videoWriterSettings :[String : AnyObject]? = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoCompressionPropertiesKey : videoWriterCompressionSettings! as AnyObject,
            AVVideoWidthKey : Int(1280) as AnyObject,
            AVVideoHeightKey : Int(720) as AnyObject
        ]
        
        var videoWriterInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoWriterSettings)
        videoWriterInput!.expectsMediaDataInRealTime = true
        videoWriterInput!.transform = videoTrack!.preferredTransform
        var videoWriter: AVAssetWriter? = try! AVAssetWriter(outputURL: outputURL, fileType: AVFileTypeQuickTimeMovie)
        videoWriter!.add(videoWriterInput!)
        //setup video reader
        var videoReaderSettings:[String : AnyObject]? = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
        ]
        
        var videoReaderOutput: AVAssetReaderTrackOutput? = AVAssetReaderTrackOutput(track: videoTrack!, outputSettings: videoReaderSettings)
        var videoReader: AVAssetReader? = try! AVAssetReader(asset: videoAsset!)
        videoReader!.add(videoReaderOutput!)
        //setup audio writer
        var audioWriterInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
        audioWriterInput!.expectsMediaDataInRealTime = false
        videoWriter!.add(audioWriterInput!)
        //setup audio reader
        var audioTrack: AVAssetTrack? = videoAsset!.tracks(withMediaType: AVMediaTypeAudio)[0]
        var audioReaderOutput: AVAssetReaderTrackOutput? = AVAssetReaderTrackOutput(track: audioTrack!, outputSettings: nil)
        var audioReader: AVAssetReader? = try! AVAssetReader(asset: videoAsset!)
        audioReader!.add(audioReaderOutput!)
        videoWriter!.startWriting()
        
        //start writing from video reader
        videoReader!.startReading()
        videoWriter!.startSession(atSourceTime: kCMTimeZero)
        let processingQueue = DispatchQueue(label: "processingQueue1")
        videoWriterInput!.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
            while videoWriterInput!.isReadyForMoreMediaData {
                let sampleBuffer:CMSampleBuffer? = videoReaderOutput!.copyNextSampleBuffer();
                if videoReader!.status == .reading && sampleBuffer != nil {
                    videoWriterInput!.append(sampleBuffer!)
                }
                else {
                    videoWriterInput!.markAsFinished()
                    
                    if videoReader!.status == .completed {
                        //start writing from audio reader
                        audioReader!.startReading()
                        videoWriter!.startSession(atSourceTime: kCMTimeZero)
                        let processingQueue = DispatchQueue(label: "processingQueue2")
                        audioWriterInput!.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                            while audioWriterInput!.isReadyForMoreMediaData {
                                let sampleBuffer:CMSampleBuffer? = audioReaderOutput!.copyNextSampleBuffer()
                                if audioReader!.status == .reading && sampleBuffer != nil {
                                    audioWriterInput!.append(sampleBuffer!)
                                }
                                else {
                                    audioWriterInput!.markAsFinished()
                                    if audioReader!.status == .completed {
                                        
                                        videoWriter!.finishWriting(completionHandler: {() -> Void in
                                            videoAsset = nil
                                            videoReader = nil
                                            videoWriter = nil
                                            videoWriterInput = nil
                                            videoReaderOutput = nil
                                            videoTrack = nil
                                            videoWriterCompressionSettings = nil
                                            videoReaderSettings = nil
                                            videoWriterSettings = nil
                                            audioReader = nil
                                            audioWriterInput = nil
                                            audioTrack = nil
                                            audioReaderOutput = nil
                                            
                                            handler(outputURL)
                                        })
                                    }
                                }
                            }
                        })
                    }
                }
            }
        })
    }
}
