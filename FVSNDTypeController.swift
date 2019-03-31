//
//  FVSNDTypeController.swift
//  ForkView
//
//  Created by Kevin Wojniak on 5/2/15.
//  Copyright (c) 2015 Kevin Wojniak. All rights reserved.
//

import Cocoa
import AudioToolbox
import AVKit
import AVFoundation

final class FVSNDTypeController: FVTypeController {
    let supportedTypes = ["snd "]

    func viewController(fromResourceData data: Data, type: String, errmsg: inout String) -> NSViewController? {
        if let asset = assetForSND(data: data, errmsg: &errmsg) {
            let playerView = AVPlayerView(frame: NSMakeRect(0, 0, 100, 100))
            playerView.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            playerView.autoresizingMask = [.width, .height]
            playerView.player!.play()
            let viewController = FVSNDViewController()
            viewController.view = playerView
            return viewController
        }
        return nil
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func assetForSND(data: Data, errmsg: inout String) -> AVAsset? {
        // See Sound.h in Carbon
        // Also see "Sound Manager" legacy PDF
        let firstSoundFormat: Int16  = 0x0001 /*general sound format*/
        let secondSoundFormat: Int16 = 0x0002 /*special sampled sound format (HyperCard)*/
        struct ModInit: OptionSet {
            var rawValue: Int32
            
            /// monophonic channel
            static var mono: ModInit {
                return ModInit(rawValue: 0x0080)
            }
            /// stereo channel
            static var stereo: ModInit {
                return ModInit(rawValue: 0x00C0)
            }
            /// MACE 3:1
            static var MACE3: ModInit {
                return ModInit(rawValue: 0x0300)
            }
            /// MACE 6:1
            static var MACE6: ModInit {
                return ModInit(rawValue: 0x0400)
            }
        }
        let nullCmd: UInt16   = 0
        let soundCmd: UInt16  = 80
        let bufferCmd: UInt16 = 81
        let stdSH: UInt8 = 0x00 /*Standard sound header encode value*/
        let extSH: UInt8 = 0xFF /*Extended sound header encode value*/
        let cmpSH: UInt8 = 0xFE /*Compressed sound header encode value*/
        struct ModRef {
            var modNumber: UInt16 = 0
            var modInit: ModInit = ModInit(rawValue: 0)
        }
        struct SndCommand {
            var cmd: UInt16 = 0
            var param1: Int16 = 0
            var param2: Int32 = 0
        }
        struct SndListResource {
            var format: Int16 = 0
            var numModifiers: Int16 = 0
            var modifierPart = ModRef()
            var numCommands: Int16 = 0
            var commandPart = SndCommand()
        }
        struct Snd2ListResource {
            var format: Int16 = 0
            var refCount: Int16 = 0
            var numCommands: Int16 = 0
            var commandPart = SndCommand()
        }
        struct SoundHeader {
            var samplePtr: UInt32 = 0
            var length: UInt32 = 0
            var sampleRate: UInt32 = 0
            var loopStart: UInt32 = 0
            var loopEnd: UInt32 = 0
            var encode: UInt8 = 0
            var baseFrequency: UInt8 = 0
        }

        let reader = FVDataReader(data)

        // Read the SndListResource or Snd2ListResource
        var format = Int16()
        if !reader.readInt16(.big, &format) {
            errmsg = "Missing header"
            return nil
        }
        if format == firstSoundFormat {
            var numModifiers = Int16()
            var modifierPart = ModRef()
            if !reader.readInt16(.big, &numModifiers) ||
                !reader.readUInt16(.big, &modifierPart.modNumber) ||
                !reader.readInt32(.big, &modifierPart.modInit) {
                errmsg = "Missing header"
                return nil
            }
            if numModifiers != 1 {
                errmsg = "Bad header"
                return nil
            }
            if modifierPart.modNumber != 5 {
                errmsg = "Unknown modNumber value \(modifierPart.modNumber)"
                return nil
            }
            if modifierPart.modInit.contains(.stereo) {
                errmsg = "Only mono channel supported"
                return nil
            }
            if modifierPart.modInit.contains(.MACE3) || modifierPart.modInit.contains(.MACE6) {
                errmsg = "Compression not supported"
                return nil
            }
        } else if format == secondSoundFormat {
            var refCount = Int16()
            if !reader.readInt16(.big, &refCount) {
                errmsg = "Missing header"
                return nil
            }
        } else {
            errmsg = "Unknown format \(format)"
            return nil
        }

        // Read SndCommands
        var headerOffset = Int()
        var numCommands = Int16()
        var commandPart = SndCommand()
        if !reader.readInt16(.big, &numCommands) {
            errmsg = "Missing header"
            return nil
        }
        if numCommands == 0 {
            errmsg = "Bad header"
            return nil
        }
        for _ in Int16(0) ..< numCommands {
            if !reader.readUInt16(.big, &commandPart.cmd) ||
                !reader.readInt16(.big, &commandPart.param1) ||
                !reader.readInt32(.big, &commandPart.param2) {
                    errmsg = "Missing command"
                    return nil
            }
            // "If soundCmd is contained within an 'snd ' resource, the high bit of the command must be set."
            // Apple docs says this for bufferCmd as well, so we clear the bit.
            commandPart.cmd &= ~0x8000
            switch commandPart.cmd {
            case soundCmd, bufferCmd:
                if headerOffset != 0 {
                    errmsg = "Duplicate commands"
                    return nil
                }
                headerOffset = Int(commandPart.param2)
            case nullCmd:
                break
            default:
                errmsg = "Unknown command \(commandPart.cmd)"
                return nil
            }
        }

        // Read SoundHeader
        var header = SoundHeader()
        if !reader.readUInt32(.big, &header.samplePtr) ||
            !reader.readUInt32(.big, &header.length) ||
            !reader.readUInt32(.big, &header.sampleRate) ||
            !reader.readUInt32(.big, &header.loopStart) ||
            !reader.readUInt32(.big, &header.loopEnd) ||
            !reader.readUInt8(&header.encode) ||
            !reader.readUInt8(&header.baseFrequency) {
            errmsg = "Missing header data"
            return nil
        }
        guard let sampleData = reader.read(Int(header.length)) else {
            errmsg = "Missing samples"
            return nil
        }
        guard header.encode == stdSH else {
            if header.encode == extSH {
                errmsg = "Extended encoding not supported"
            } else if header.encode == cmpSH {
                errmsg = "Compression not supported"
            } else {
                errmsg = String(format: "Unknown encoding 0x%02X", header.encode)
            }
            return nil
        }

        // Generate an AudioStreamBasicDescription for conversion
        var stream = AudioStreamBasicDescription()
        stream.mSampleRate = Float64(header.sampleRate) / Float64(1 << 16)
        stream.mFormatID = kAudioFormatLinearPCM
        stream.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger
        stream.mBytesPerPacket = 1
        stream.mFramesPerPacket = 1
        stream.mBytesPerFrame = 1
        stream.mChannelsPerFrame = 1
        stream.mBitsPerChannel = 8

        // Create a temporary file for storage
        let url = URL(fileURLWithPath: NSTemporaryDirectory().appendingFormat("%d-%f.aif", arc4random(), NSDate().timeIntervalSinceReferenceDate))
        var audioFileTmp: ExtAudioFileRef?
        let createStatus = ExtAudioFileCreateWithURL(url as CFURL, AudioFileTypeID(kAudioFileAIFFType), &stream, nil, AudioFileFlags.eraseFile.rawValue, &audioFileTmp)
        guard createStatus == noErr, let audioFile = audioFileTmp else {
            errmsg = "ExtAudioFileCreateWithURL failed with status \(createStatus)"
            return nil
        }

        // Configure the AudioBufferList
        let srcData = UnsafeMutableRawPointer(mutating: (sampleData as NSData).bytes.assumingMemoryBound(to: UInt8.self))
        var audioBuffer = AudioBuffer()
        audioBuffer.mNumberChannels = 1
        audioBuffer.mDataByteSize = header.length
        audioBuffer.mData = srcData
        guard let audioBufferData = UnsafeMutablePointer(mutating: audioBuffer.mData?.assumingMemoryBound(to: UInt8.self)) else {
            errmsg = "Failed to create buffer"
            return nil
        }
        for idx in 0 ..< Int(header.length) {
            audioBufferData[idx] ^= 0x80
        }
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: audioBuffer)

        // Write the data to the file
        let writeStatus = ExtAudioFileWrite(audioFile, header.length, &bufferList)
        if writeStatus != noErr {
            errmsg = "ExtAudioFileWrite failed with status \(writeStatus)"
            return nil
        }

        // Finish up
        let disposeStatus = ExtAudioFileDispose(audioFile)
        if disposeStatus != noErr {
            errmsg = "ExtAudioFileDispose failed with status \(disposeStatus)"
            return nil
        }

        // Generate an AVAsset
        return AVAsset(url: url)
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
}

final class FVSNDViewController: NSViewController {
    override func viewWillDisappear() {
        if let playerView = self.view as? AVPlayerView {
            playerView.player!.pause()
        }
    }
}
