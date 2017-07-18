//
//  VideoAssetManager.swift
//  MovieFileCompressor
//
//  Created by Felipe Marino on 06/07/17.
//  Copyright © 2017 Felipe Marino. All rights reserved.
//

import Foundation
import AVFoundation

struct VideoAssetManager {
    
    var videoWriter: AVAssetWriter
    var videoReader: AVAssetReader
    var videoWriterInput: AVAssetWriterInput
    var videoReaderOutput: AVAssetReaderTrackOutput
    var audioReader: AVAssetReader
    var audioWriterInput: AVAssetWriterInput
    var audioReaderOutput: AVAssetReaderTrackOutput
    
    init(videoWriter: AVAssetWriter, videoReader: AVAssetReader,
         videoWriterInput: AVAssetWriterInput, videoReaderOutput: AVAssetReaderTrackOutput,
         audioReader: AVAssetReader, audioWriterInput: AVAssetWriterInput,
         audioReaderOutput: AVAssetReaderTrackOutput) {
        self.videoWriter = videoWriter
        self.videoReader = videoReader
        self.videoWriterInput = videoWriterInput
        self.videoReaderOutput = videoReaderOutput
        self.audioReader = audioReader
        self.audioWriterInput = audioWriterInput
        self.audioReaderOutput = audioReaderOutput
    }
}
