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
    internal var movieOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    internal weak var cameraUtil = CameraUtil()

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
                CameraUtil().setAVCaptureSessionCamera(completion: { (session, movieOutput, previewLayer) in

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
        print("didStartRecordingToOutputFile \(fileURL)")
    }

    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("didFinishRecordingToOutputFile")

        if let url = outputFileURL {
            guard let data = NSData(contentsOf: url) else {
                return
            }
            print("\nFile size before compression: \(Double(data.length / 1048576)) mb")

            let compressedURL = NSURL.fileURL(withPath: url.path.replacingOccurrences(of: ".mov", with: ".mp4"))

            //Using bit rate 900000. Value should be changed to find better file size versus frame quality
            CameraUtil().convertVideoToLowQuality(withInputURL: url, outputURL: compressedURL, bitRate: 900000, handler: { (compressedURL) in
                do {
                    let compressedData = try Data(contentsOf: compressedURL)

                    //remove .mov
                    if FileManager.default.fileExists(atPath: url.path) {
                        do {
                            try FileManager.default.removeItem(at: url)
                            print("\nfile removed at url \(url.path)")
                        } catch {
                            print("\nerror on removing file at url \(url.path)")
                        }
                    } else {
                        print("\nthere are no files at \(url.path)")
                    }

                    print("\nFile size after compression: \(Double(compressedData.count / 1048576)) mb")
                    UISaveVideoAtPathToSavedPhotosAlbum(compressedURL.path, nil, nil, nil)

                    DispatchQueue.main.async {
                        self.showToast(message: "Original file size: \(Double(data.length / 1048576)) mb\nCompressed file size: \(Double(compressedData.count / 1048576)) mb", frame: CGRect(x: self.view.frame.size.width/2 - 150, y: self.view.frame.size.height/2 - 100, width: 300, height: 200), lines: 2)
                    }
                } catch {
                    print("\nerror converting video to low quality")
                }
            })
        }
    }
}

// MARK: Toast extension
extension UIViewController {

    func showToast(message: String, frame: CGRect, lines: Int) {

        let toastLabel = UILabel(frame: frame)
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = lines

        self.view.addSubview(toastLabel)

        UIView.animate(withDuration: 6.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(_) in
            toastLabel.removeFromSuperview()
        })
    }
}
