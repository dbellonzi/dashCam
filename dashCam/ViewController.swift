//
//  ViewController.swift
//  dashCam
//
//  Created by Daniel Bellonzi on 1/13/18.
//  Copyright © 2018 Daniel Bellonzi. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation
import CoreMedia

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var gForceTrack: UILabel!
    
    // CoreMotion
    var motionManager = CMMotionManager()
    let opQueue = OperationQueue()
    
    // AVFoundation
    var session = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput()
	
	var outputFileLocation: URL?
	var videoOutput: AVCapturePhotoOutput?
	var cameraPreview: AVCaptureVideoPreviewLayer?
	var vidNum = 0
	
	// Data
	var plotA: [Double] = [0, 0, 0]
	var plotB: [Double] = [0, 0, 0]
	var check: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if motionManager.isAccelerometerAvailable {
            startAccelerometers()
			setupSession()
			setupCamera()
			setupIO()
			setupPreview()
			startRunningSession()
        } else {
            print("ERROR")
        }
    }
    
    @IBAction func toggleRec(_ sender: UIButton) {
        
        if self.movieOutput.isRecording {
            self.movieOutput.stopRecording()
            sender.setTitle("Rec", for: .normal)
        } else {

			self.movieOutput.connection(with: AVMediaType.video)?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
			self.movieOutput.maxRecordedDuration = self.maxRecordedDuration()
			self.movieOutput.startRecording(to: URL(fileURLWithPath:self.videoFileLocation()), recordingDelegate: self)
			sender.setTitle("Stop", for: .normal)
        }
    }
	
	func videoFileLocation() -> String {
		vidNum += 1
		print("Wrote file location")
		return NSTemporaryDirectory().appending("videoFile\(vidNum).mov")

	}
	
	func maxRecordedDuration() -> CMTime {
		let seconds: Int64 = 120
		let preferredTimeScale: Int32 = 1
		return CMTimeMake(seconds, preferredTimeScale)
	}
	
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		print("Finished Recording \(outputFileURL)")

		self.outputFileLocation = outputFileURL
	}
	
	func setupSession() {
		session.sessionPreset = AVCaptureSession.Preset.hd1280x720
	}
	
	func setupCamera() {
		let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
		let devices = deviceDiscoverySession.devices
		
		for device in devices{
			if device.position == AVCaptureDevice.Position.back{
				captureDevice = device
			}
		}
	}
	
	func setupIO () {
		do {
			let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
			session.addInput(captureDeviceInput)
			self.session.addOutput(movieOutput)
			videoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
		} catch {
			print(error)
		}
	}
	
	func setupPreview() {
		cameraPreview = AVCaptureVideoPreviewLayer(session: session)
		cameraPreview?.videoGravity = AVLayerVideoGravity.resizeAspectFill
		cameraPreview?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
		cameraPreview?.frame = self.view.frame
		self.view.layer.insertSublayer(cameraPreview!, at: 0)
	}
	
	func startRunningSession() {
		session.startRunning()
	}
    
    func startAccelerometers() {
        // Make sure the accelerometer hardware is available.
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data.
            let timer = Timer(fire: Date(), interval: (0.2),
                   repeats: true, block: { (timer) in
                    // Get the accelerometer data.
                    if let data = self.motionManager.accelerometerData {
                        let x = data.acceleration.x
                        let y = data.acceleration.y
                        let z = data.acceleration.z
                        self.gForceTrack.translatesAutoresizingMaskIntoConstraints = true
                        self.gForceTrack.frame.origin.x = CGFloat((y*50)+70)
                        self.gForceTrack.frame.origin.y = CGFloat((z*50)+200)
						if self.check {
							self.plotA = [x,y,z]
							self.check = false
						} else {
							self.plotB = [x,y,z]
							self.check = true
						}
						if self.plotB != [0.0,0.0,0.0] {
							let pass = self.accel(x: (self.plotA[0]-self.plotB[0]), y: (self.plotA[1]-self.plotB[1]), z: (self.plotA[2]-self.plotB[2]))
							if pass > 1  && self.movieOutput.isRecording {
								self.movieOutput.stopRecording()
								self.movieOutput.startRecording(to: URL(fileURLWithPath:self.videoFileLocation()), recordingDelegate: self)
							}
						}
					}
					})
            
            // Add the timer to the current run loop.
            RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        } else {
            print("accelerometer is not working")
        }
    }
    
    func accel(x: Double, y: Double, z:Double) -> Double {
        var acc = sqrt((y*y)+(x*x)+(z*z))
        acc = Double(Int(acc*1000))/1000
        accLabel.text = "acc:\(acc)"
        return acc
    }
// when incident occurs start editing video
//	func makeVideo() {
//
//	}
	
}
