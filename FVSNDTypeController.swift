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
        if let asset = assetForSND(data, errmsg: &errmsg) {
            let playerView = AVPlayerView(frame: NSMakeRect(0, 0, 100, 100))
            playerView.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            playerView.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
            playerView.player!.play()
            let viewController = FVSNDViewController()
            viewController.view = playerView
            return viewController
        }
        return nil
    }

    func assetForSND(_ data: Data, errmsg: inout String) -> AVAsset? {
        // See Sound.h in Carbon
        // Also see "Sound Manager" legacy PDF
        let firstSoundFormat: Int16  = 0x0001 /*general sound format*/
        let secondSoundFormat: Int16 = 0x0002 /*special sampled sound format (HyperCard)*/
        let _/*initMono*/:   Int32 = 0x0080 /*monophonic channel*/
        let initStereo: Int32 = 0x00C0 /*stereo channel*/
        let initMACE3:  Int32 = 0x0300 /*MACE 3:1*/
        let initMACE6:  Int32 = 0x0400 /*MACE 6:1*/
        let nullCmd: UInt16   = 0
        let soundCmd: UInt16  = 80
        let bufferCmd: UInt16 = 81
        let stdSH: UInt8 = 0x00 /*Standard sound header encode value*/
        let extSH: UInt8 = 0xFF /*Extended sound header encode value*/
        let cmpSH: UInt8 = 0xFE /*Compressed sound header encode value*/
        struct ModRef {
            var modNumber: UInt16 = 0
            var modInit: Int32 = 0
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
        if !reader.readInt16(endian: .big, &format) {
            errmsg = "Missing header"
            return nil
        }
        if format == firstSoundFormat {
            var numModifiers = Int16()
            var modifierPart = ModRef()
            if !reader.readInt16(endian: .big, &numModifiers) ||
                !reader.readUInt16(endian: .big, &modifierPart.modNumber) ||
                !reader.readInt32(endian: .big, &modifierPart.modInit) {
                errmsg = "Missing header"
                return nil
            }
            if numModifiers != 1 {
                errmsg = "Bad header"
                return nil
            }
            if modifierPart.modNumber != 5  {
                errmsg = "Unknown modNumber value \(modifierPart.modNumber)"
                return nil
            }
            if modifierPart.modInit & initStereo == 1 {
                errmsg = "Only mono channel supported"
                return nil
            }
            if modifierPart.modInit & initMACE3 == 1 || modifierPart.modInit & initMACE6 == 1 {
                errmsg = "Compression not supported"
                return nil
            }
        } else if format == secondSoundFormat {
            var refCount = Int16()
            if !reader.readInt16(endian: .big, &refCount) {
                errmsg = "Missing header"
                return nil
            }
        } else {
            errmsg = "Unknown format \(format)"
            return nil
        }
        
        // Read SndCommands
        var header_offset = Int()
        var numCommands = Int16()
        var commandPart = SndCommand()
        if !reader.readInt16(endian: .big, &numCommands) {
            errmsg = "Missing header"
            return nil
        }
        if numCommands == 0 {
            errmsg = "Bad header"
            return nil
        }
        for _ in Int16(0) ..< numCommands {
            if !reader.readUInt16(endian: .big, &commandPart.cmd) ||
                !reader.readInt16(endian: .big, &commandPart.param1) ||
                !reader.readInt32(endian: .big, &commandPart.param2) {
                    errmsg = "Missing command"
                    return nil
            }
            // "If soundCmd is contained within an 'snd ' resource, the high bit of the command must be set."
            // Apple docs says this for bufferCmd as well, so we clear the bit.
            commandPart.cmd &= ~0x8000
            switch commandPart.cmd {
            case soundCmd, bufferCmd:
                if header_offset != 0 {
                    errmsg = "Duplicate commands"
                    return nil
                }
                header_offset = Int(commandPart.param2)
            case nullCmd:
                break
            default:
                errmsg = "Unknown command \(commandPart.cmd)"
                return nil
            }
        }
        
        // Read SoundHeader
        var header = SoundHeader()
        if !reader.readUInt32(endian: .big, &header.samplePtr) ||
            !reader.readUInt32(endian: .big, &header.length) ||
            !reader.readUInt32(endian: .big, &header.sampleRate) ||
            !reader.readUInt32(endian: .big, &header.loopStart) ||
            !reader.readUInt32(endian: .big, &header.loopEnd) ||
            !reader.readUInt8(&header.encode) ||
            !reader.readUInt8(&header.baseFrequency) {
            errmsg = "Missing header data"
            return nil
        }
        let sampleData = reader.read(Int(header.length))
        if sampleData == nil {
            errmsg = "Missing samples"
            return nil
        }
        if header.encode != stdSH {
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
        stream.mSampleRate = Float64(header.sampleRate >> 16)
        stream.mFormatID = AudioFormatID(kAudioFormatLinearPCM)
        stream.mFormatFlags = AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger)
        stream.mBytesPerPacket = 1
        stream.mFramesPerPacket = 1
        stream.mBytesPerFrame = 1
        stream.mChannelsPerFrame = 1
        stream.mBitsPerChannel = 8
        
        // Create a temporary file for storage
        let url = URL(fileURLWithPath: NSTemporaryDirectory().appendingFormat("%d-%f.aif", arc4random(), Date().timeIntervalSinceReferenceDate))
        var audioFile: ExtAudioFileRef? = nil
        let createStatus = ExtAudioFileCreateWithURL(url as NSURL, AudioFileTypeID(kAudioFileAIFFType), &stream, nil, AudioFileFlags.eraseFile.rawValue, &audioFile)
        if createStatus != noErr {
            errmsg = "ExtAudioFileCreateWithURL failed with status \(createStatus)"
            return nil
        }
        
        // Configure the AudioBufferList
        let srcData = ((sampleData! as NSData).bytes).assumingMemoryBound(to: UInt8.self)
        var audioBuffer = AudioBuffer()
        audioBuffer.mNumberChannels = 1
        audioBuffer.mDataByteSize = header.length
        audioBuffer.mData = UnsafeMutableRawPointer(mutating: srcData)
        let audioBufferData = audioBuffer.mData?.assumingMemoryBound(to: UInt8.self)
        for i in 0 ..< Int(header.length) {
            audioBufferData?[i] ^= 0x80
        }
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: audioBuffer)
        
        // Write the data to the file
        let writeStatus = ExtAudioFileWrite(audioFile!, header.length, &bufferList)
        if writeStatus != noErr {
            errmsg = "ExtAudioFileWrite failed with status \(writeStatus)"
            return nil
        }
        
        // Finish up
        let disposeStatus = ExtAudioFileDispose(audioFile!)
        if disposeStatus != noErr {
            errmsg = "ExtAudioFileDispose failed with status \(disposeStatus)"
            return nil
        }
        
        // Generate an AVAsset
        return AVAsset(url: url)
    }
}

final class FVSNDViewController: NSViewController {
    override func viewWillDisappear() {
        if let playerView = self.view as? AVPlayerView {
            playerView.player!.pause()
        }
    }
}
