//
//  CameraStatus.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 22/06/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import Foundation
import AVFoundation

public typealias CameraActiveStatus = (_ cameraStatus: AVAuthorizationStatus) -> Void

class CameraStatus {

    static func checkIfCameraIsAuthorized (completion: @escaping CameraActiveStatus) {

        let cameraMediaType             = AVMediaTypeVideo
        let cameraAuthorizationStatus   = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)

        switch cameraAuthorizationStatus {

        case .authorized:
            completion(.authorized)
            break

        case .restricted:
            completion(.restricted)
            break

        case .denied:
            completion(.denied)
            break

        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { (result) in
                if result {
                    DispatchQueue.main.async {
                        completion(.authorized)
                    }
                } else { completion(.notDetermined) }
            })
        }
    }
}
