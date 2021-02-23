//
//  ViewController.swift
//  what-flower
//
//  Created by Paweł Kozioł on 02/01/2021.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                
                fatalError("Cannot convert to CIImage.")
            }
            
            detect(image: convertedCIImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            
            fatalError("Cannot import model.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
            
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).response { (response) in
            
            switch response.result {
            case .success( _):
                print("Got the wikipedia info.")
                do {
                    let flowerJSON : JSON = try JSON(data: response.result.get()!)
                    let pageid = flowerJSON["query"]["pageids"][0].stringValue
                    let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                    let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                    
                    self.label.text! = flowerDescription
                    self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                    self.imageView.layer.masksToBounds = true
                    self.imageView.layer.borderWidth = 2
                    self.imageView.layer.cornerRadius = self.imageView.bounds.width / 2
                    
                } catch {
                    print(error)
                }
            
            case .failure( _):
                print("Error getting the wikipedia info.")
            }
        }
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

