//
//  CameraViewController.swift
//  CoreML-AllinOne
//
//  Created by Sam Witteveen on 27/7/17.
//  Copyright © 2017 Sam Witteveen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum VoiceState {
    case off
    case on
}

class CameraViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    
    var voiceControlState: VoiceState = .on

    
    @IBOutlet weak var tempImage: RoundedShadowImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var satayResultImage: RoundedShadowImageView!
    //@IBOutlet weak var roundedLblView: RoundedShadowView!
    //@IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //cameraView.autoresizesSubviews = true
        //cameraView.clipsToBounds = false
        
        previewLayer.frame = cameraView.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        notSatay()
        speechSynthesizer.delegate = self
        spinner.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
                
            }
        } catch {
            debugPrint(error)
        }
    
        notSatay()
    }
    
    /*
    @IBAction func flashPressed(_ sender: Any) {
    }
    */
    @objc func didTapCameraView() {
        self.satayResultImage.isHidden = true
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        
        let settings = AVCapturePhotoSettings()
        
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        /*if flashControlState == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }*/
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
    }
 
    
    
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results {
            if classification.confidence < 0.97 {
                let unknownObjectMessage = "It's Not Satay"//"I'm not sure what this is. Please try again."
                notSatay()
                //self.classLbl.text = unknownObjectMessage
                synthesizeSpeech(fromString: unknownObjectMessage)
                //self.confidenceLbl.text = ""
                break
            } else {
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                //self.classLbl.text = identification
                //self.confidenceLbl.text = "CONFIDENCE: \(confidence)%"
                print(identification)
                if identification == "satay" {
                    itsSatay()
                    let completeSentence = "This looks like a \(identification) and I'm \(confidence) percent sure."
                    synthesizeSpeech(fromString: completeSentence)
                } else {
                    notSatay()
                    let completeSentence = "It's Not Satay."
                    synthesizeSpeech(fromString: completeSentence)
                }
                break
            }
        }
    }
 
    func notSatay(){
        self.satayResultImage.isHidden = false
        self.satayResultImage.image = #imageLiteral(resourceName: "not-red-rec")
    }
    
    func itsSatay(){
        self.satayResultImage.isHidden = false
        self.satayResultImage.image = #imageLiteral(resourceName: "satay-green-rec")
    }
    
    func synthesizeSpeech(fromString string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    
    /*
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            //flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            //flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
     */
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                // Instantiate the CoreML Model
                //let model = try VNCoreMLModel(for: SqueezeNet().model)
                //let model = try VNCoreMLModel(for: Inceptionv3().model)
                let model = try VNCoreMLModel(for: satay_01().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.tempImage.image = image
        }
    }
}

extension CameraViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}

