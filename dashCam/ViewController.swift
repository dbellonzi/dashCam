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

class ViewController: UIViewController {
    
    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var coordLabel: UILabel!

    
    // CoreMotion
    var motionManager = CMMotionManager()
    let opQueue = OperationQueue()
    
    // AVFoundation
    var session = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput()
	
	// Data
	var plotA: [Double] = [0, 0, 0]
	var plotB: [Double] = [0, 0, 0]
	var check: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if motionManager.isAccelerometerAvailable {
            startAccelerometers()
//            startReadingMotionData()
        } else {
            print("ERROR")
        }
    }
    
    @IBAction func toggleRec(_ sender: UIButton) {
        
        if self.movieOutput.isRecording {
//            self.movieOutput.stopRecording()
            sender.setTitle("Rec", for: .normal)
        } else {
//            self.movieOutput.connection(with: video)?.videoOrientation = self.videoOrientation
            sender.setTitle("Stop", for: .normal)
        }
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
						if self.check {
							self.plotA = [x,y,z]
							self.check = false
						} else {
							self.plotB = [x,y,z]
							self.check = true
						}
						if self.plotB != [0.0,0.0,0.0] {
							print(self.plotA, self.plotB)
							let pass = self.accel(x: (self.plotA[0]-self.plotB[0]), y: (self.plotA[1]-self.plotB[1]), z: (self.plotA[2]-self.plotB[2]))
							if pass > 1 {
								self.view.backgroundColor = UIColor.red
//								self.makeVideo()
								print("Dead")
							} else {
								self.view.backgroundColor = UIColor.green
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
        coordLabel.text = "x: \(x) y: \(y) z:\(z)"
        accLabel.text = "acc:\(acc)"
        return acc
    }
// when incident occurs start editing video
//	func makeVideo() {
//
//	}
	
}
