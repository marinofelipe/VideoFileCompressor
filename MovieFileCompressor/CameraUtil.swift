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
    _ previewLayer: AVCaptureVideoPreviewLayer?) -> Void
public typealias CompressedFileURL = ((_ : URL) -> Void)

public class CameraUtil: NSObject {

    // MARK: - Private Properties
    private let KPathExtension: String                        = "mov"

    private var session: AVCaptureSession              = AVCaptureSession()
    private var input: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var output: AVCaptureStillImageOutput?    = AVCaptureStillImageOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?   = AVCaptureVideoPreviewLayer()
    private var movieOutput: AVCaptureMovieFileOutput      = AVCaptureMovieFileOutput()

    // MARK: - Methods
    public func setAVCaptureSessionCamera (completion: CameraSession) {

        let camera      = self.device(position: .front)
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)

        do {
            input          = try AVCaptureDeviceInput(device: camera)
            audioInput     = try AVCaptureDeviceInput(device: audioDevice)

        } catch { completion(nil, nil, nil) }

        if self.session.canAddInput(input) == true {
            session.addInput(self.input)
        }
        if self.session.canAddInput(audioInput) == true {
            session.addInput(self.audioInput)
        }

        output?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

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
        let devices: [AnyObject] = AVCaptureDevice.devices() as [AnyObject]

        for device in devices {
            guard let dev = device as? AVCaptureDevice else {
                continue
            }
            if dev.position == position { return dev }
        }
        return nil
    }

    public func tempPathMovie (fileName: String) -> URL? {

        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                                                                .appendingPathExtension(KPathExtension)
                                                                .absoluteString
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

    public func convertVideoToLowSize(withInputURL inputURL: URL, outputURL: URL, bitRate: Int, handler: @escaping CompressedFileURL) {
        let videoAsset = AVURLAsset(url: inputURL, options: nil)
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey: Int(bitRate)
        ]
        let videoWriterSettings: [String : AnyObject]? = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoCompressionPropertiesKey: videoWriterCompressionSettings as AnyObject,
            AVVideoWidthKey: Int(1280) as AnyObject,
            AVVideoHeightKey: Int(720) as AnyObject
        ]
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoWriterSettings)

        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = videoTrack.preferredTransform

        do {
            let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileTypeQuickTimeMovie)
            videoWriter.add(videoWriterInput)
            //setup video reader
            let videoReaderSettings: [String : AnyObject]? = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
            ]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            do {
                let videoReader = try AVAssetReader(asset: videoAsset)
                videoReader.add(videoReaderOutput)
                //setup audio writer
                let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
                audioWriterInput.expectsMediaDataInRealTime = false
                videoWriter.add(audioWriterInput)

                //setup audio reader
                let audioTrack = videoAsset.tracks(withMediaType: AVMediaTypeAudio)[0]
                let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                do {
                    let audioReader: AVAssetReader! = try AVAssetReader(asset: videoAsset)
                    audioReader.add(audioReaderOutput)
                    startReadingAndWriting(onOutputURL: outputURL, videoWriter: videoWriter, videoReader: videoReader, videoWriterInput: videoWriterInput,
                                           videoReaderOutput: videoReaderOutput, audioReader: audioReader, audioWriterInput: audioWriterInput,
                                           audioReaderOutput: audioReaderOutput, handler: { (compressedFileURL) in
                        handler(compressedFileURL)
                    })
                } catch {
                    print("error on Audio Reader")
                }
            } catch {
                print("error on VideoReader")
            }
        } catch {
            print("error on Video Writer")
        }
    }
    
    //FIXME: Too many parameters
    // swiftlint:disable function_parameter_count
    private func startReadingAndWriting(onOutputURL outputURL: URL, videoWriter: AVAssetWriter, videoReader: AVAssetReader,
                                        videoWriterInput: AVAssetWriterInput, videoReaderOutput: AVAssetReaderTrackOutput,
                                        audioReader: AVAssetReader, audioWriterInput: AVAssetWriterInput,
                                        audioReaderOutput: AVAssetReaderTrackOutput, handler:  @escaping CompressedFileURL) {
        videoWriter.startWriting()
        //start writing from video reader
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        let processingQueue = DispatchQueue(label: "processingQueue1")
        videoWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
            while videoWriterInput.isReadyForMoreMediaData {
                let sampleBuffer: CMSampleBuffer? = videoReaderOutput.copyNextSampleBuffer()
                if videoReader.status == .reading && sampleBuffer != nil {
                    if let sBuffer = sampleBuffer {
                        videoWriterInput.append(sBuffer)
                    }
                } else {
                    videoWriterInput.markAsFinished()
                    if videoReader.status == .completed {
                        //start writing from audio reader
                        audioReader.startReading()
                        videoWriter.startSession(atSourceTime: kCMTimeZero)
                        let processingQueue = DispatchQueue(label: "processingQueue2")
                        audioWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                            while audioWriterInput.isReadyForMoreMediaData {
                                let sampleBuffer: CMSampleBuffer? = audioReaderOutput.copyNextSampleBuffer()
                                if audioReader.status == .reading && sampleBuffer != nil {
                                    if let sBuffer = sampleBuffer {
                                        audioWriterInput.append(sBuffer)
                                    }
                                } else {
                                    audioWriterInput.markAsFinished()
                                    if audioReader.status == .completed {
                                        videoWriter.finishWriting(completionHandler: {() -> Void in
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
