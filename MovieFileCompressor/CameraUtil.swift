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

        if let vidAsset = videoAsset {
            var videoTrack: AVAssetTrack?  = vidAsset.tracks(withMediaType: AVMediaTypeVideo)[0]

            var videoWriterCompressionSettings: Dictionary? = [
                AVVideoAverageBitRateKey: Int(bitRate)
            ]

            if let vidWritterCompressionSettings = videoWriterCompressionSettings {
                var videoWriterSettings: [String : AnyObject]? = [
                    AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
                    AVVideoCompressionPropertiesKey: vidWritterCompressionSettings as AnyObject,
                    AVVideoWidthKey: Int(1280) as AnyObject,
                    AVVideoHeightKey: Int(720) as AnyObject
                ]

                if let vidTrack = videoTrack {
                    var videoWriterInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoWriterSettings)

                    if let vidWriterInput = videoWriterInput {
                        vidWriterInput.expectsMediaDataInRealTime = true
                        vidWriterInput.transform = videoTrack!.preferredTransform

                        do {
                            var videoWriter: AVAssetWriter? = try AVAssetWriter(outputURL: outputURL, fileType: AVFileTypeQuickTimeMovie)

                            if let vidWriter = videoWriter {
                                vidWriter.add(videoWriterInput!)

                                //setup video reader
                                var videoReaderSettings: [String : AnyObject]? = [
                                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
                                ]

                                var videoReaderOutput: AVAssetReaderTrackOutput? = AVAssetReaderTrackOutput(track: vidTrack, outputSettings: videoReaderSettings)

                                if let vidReaderOutput = videoReaderOutput {
                                    do {
                                        var videoReader: AVAssetReader? = try AVAssetReader(asset: vidAsset)

                                        if let vidReader = videoReader {
                                            vidReader.add(vidReaderOutput)

                                            //setup audio writer
                                            var audioWriterInput: AVAssetWriterInput? = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)

                                            if let audWriterInput = audioWriterInput {
                                                audWriterInput.expectsMediaDataInRealTime = false
                                                vidWriter.add(audWriterInput)

                                                //setup audio reader
                                                var audioTrack: AVAssetTrack? = vidAsset.tracks(withMediaType: AVMediaTypeAudio)[0]

                                                if let audTrack = audioTrack {
                                                    var audioReaderOutput: AVAssetReaderTrackOutput? = AVAssetReaderTrackOutput(track: audTrack, outputSettings: nil)

                                                    if let audReaderOutput = audioReaderOutput {
                                                        do {
                                                            var audioReader: AVAssetReader? = try AVAssetReader(asset: vidAsset)

                                                            if let audReader = audioReader {
                                                                audReader.add(audReaderOutput)
                                                                vidWriter.startWriting()

                                                                //start writing from video reader
                                                                vidReader.startReading()
                                                                vidWriter.startSession(atSourceTime: kCMTimeZero)

                                                                let processingQueue = DispatchQueue(label: "processingQueue1")
                                                                vidWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                                                                    while vidWriterInput.isReadyForMoreMediaData {
                                                                        let sampleBuffer: CMSampleBuffer? = vidReaderOutput.copyNextSampleBuffer()
                                                                        if vidReader.status == .reading && sampleBuffer != nil {
                                                                            if let sBuffer = sampleBuffer {
                                                                                vidWriterInput.append(sBuffer)
                                                                            }
                                                                        } else {
                                                                            vidWriterInput.markAsFinished()

                                                                            if vidReader.status == .completed {
                                                                                //start writing from audio reader
                                                                                audReader.startReading()
                                                                                vidWriter.startSession(atSourceTime: kCMTimeZero)
                                                                                let processingQueue = DispatchQueue(label: "processingQueue2")
                                                                                audWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                                                                                    while audWriterInput.isReadyForMoreMediaData {
                                                                                        let sampleBuffer: CMSampleBuffer? = audReaderOutput.copyNextSampleBuffer()
                                                                                        if audReader.status == .reading && sampleBuffer != nil {
                                                                                            if let sBuffer = sampleBuffer {
                                                                                                audWriterInput.append(sBuffer)
                                                                                            }
                                                                                        } else {
                                                                                            audWriterInput.markAsFinished()
                                                                                            if audReader.status == .completed {

                                                                                                vidWriter.finishWriting(completionHandler: {() -> Void in
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
                                                        } catch {
                                                            print("error on Audio Reader")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        print("error on VideoReader")
                                    }
                                }
                            }
                        } catch {
                            print("error on Video Writer")
                        }
                    }
                }
            }
        }
    }
}
