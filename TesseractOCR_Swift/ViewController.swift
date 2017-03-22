//
//  ViewController.swift
//  TesseractOCR_Swift
//
//  Created by ivc on 3/14/17.
//  Copyright © 2017 ivc. All rights reserved.
//

import UIKit
import TesseractOCR

class ViewController: UIViewController , G8TesseractDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var selectLanguage: UISegmentedControl!
    
    var langSelected: String = "ja"
    var viewTextTranslated: UIView! = nil
    var screenSize = UIScreen.main.bounds
    var arrTextLine: [Any]!
    var tesseract: G8Tesseract!
    var loading: UIActivityIndicatorView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tesseract = G8Tesseract(language: "eng")!
        if (tesseract != nil){
            tesseract.delegate = self
            
            //let screenSize = UIScreen.main.bounds
            
            let scaleImage = self.scaleImage(UIImage(named: "eng_text.jpg")!, maxDimension:640)
            
            tesseract.image = scaleImage.g8_blackAndWhite()
            tesseract.recognize()
            
            arrTextLine = tesseract.recognizedBlocks(by: G8PageIteratorLevel.textline)
            let scaleImage2 = self.scaleImage(UIImage(named: "eng_text.jpg")!, maxDimension: screenSize.width)
            
            
            var imageView : UIImageView
            imageView  = UIImageView(frame:CGRect(x: 0, y: 150, width: scaleImage2.size.width, height: scaleImage2.size.height))
            
            imageView.image = scaleImage2
            self.view.addSubview(imageView)
            
            let labelBackground = UILabel(frame: CGRect(x: 0, y: 0, width: self.screenSize.width, height: self.screenSize.height))
            labelBackground.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            self.view.addSubview(labelBackground)
            
            loading = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            loading.center = self.view.center
            loading.hidesWhenStopped = true
            loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            
            self.view.addSubview(loading)
            
            translate(tesseract)
            
            }
    }
    @IBAction func changeLanguage(_ sender: Any) {
        if(selectLanguage.selectedSegmentIndex == 0){
            langSelected = "en"
        }
        else if(selectLanguage.selectedSegmentIndex == 1){
            langSelected = "ja"
        }
        else
        {
            langSelected = "vi"
        }
        
        viewTextTranslated.removeFromSuperview()
        
        translate(tesseract)
        
    }
    
    func translate(_ tesseract: G8Tesseract) -> Void {
        translateText(tesseract.recognizedText, completion: { (translatedText) in
            
            
            self.viewTextTranslated = UIView(frame: CGRect(x: 0, y: 0, width: self.screenSize.width, height: self.screenSize.height))
            
            var number: Int = 0
            for item in self.arrTextLine! {
                if(number < (self.arrTextLine?.count)!){
                    let line1 = item as? G8RecognizedBlock
                    
                    var translatedTextArr = translatedText.components(separatedBy: "|")
                    
                    let label = UILabel(frame: CGRect(x: ((line1?.boundingBox.origin.x)! * self.screenSize.width), y: 150 + ((line1?.boundingBox.origin.y)! * self.screenSize.width), width: (line1?.boundingBox.width)! * self.screenSize.width, height: (line1?.boundingBox.height)! * self.screenSize.width))
                    if(translatedTextArr[number].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty){
                        label.text = translatedTextArr[number + 1]
                        number = number + 2
                    }
                    else{
                        label.text = translatedTextArr[number]
                        number = number + 1
                    }
                    label.adjustsFontSizeToFitWidth = true
                    label.textColor = UIColor.white
                    //label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                    self.viewTextTranslated.addSubview(label)
                    //let textdata = NSCharacterSet(charactersInString: (line1 as? String)!)
                }
            }
            self.loading.stopAnimating()
            self.view.addSubview(self.viewTextTranslated)
            
        })

    }

    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("\(tesseract.progress)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage
    {
        var scaleSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height{
            scaleFactor = image.size.height/image.size.width
            scaleSize.width = maxDimension
            scaleSize.height = scaleSize.width * scaleFactor
        }else{
            scaleFactor = image.size.width/image.size.height
            scaleSize.height = maxDimension
            scaleSize.width = scaleSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaleSize)
        image.draw(in: CGRect(x: 0, y: 0, width: scaleSize.width, height: scaleSize.height))
        let scaleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaleImage!
    }
    
    func translateText(_ textToTranslate: String, completion: @escaping (_ resultText: String)->()) -> Void
    {
        loading.startAnimating()
        let textChanged = textToTranslate.replacingOccurrences(of: "\n", with: " | ")
        if(langSelected == "en")
        {
            completion(textChanged)
            return
        }
        
        let urlwithPercentEscapes = textChanged.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as String
        let urlString = "https://www.googleapis.com/language/translate/v2?key=AIzaSyC8C-yszNljGKMZR9_hFl4zIXql_ATopTA&q=\(urlwithPercentEscapes)&source=en&target=\(langSelected)"
        
        
        let config = URLSessionConfiguration.default // Session Configuration
        let session = URLSession(configuration: config) // Load configuration into Session
        let url = URL(string: urlString)!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                
                print(error!.localizedDescription)
                
            } else {
                
                do {
                    
                    if let data = data {
                        if let json = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            if let jsonData = json["data"] as? [String : Any] {
                                if let translations = jsonData["translations"] as? [NSDictionary] {
                                    if let translation = translations.first as? [String : Any] {
                                        if let translatedText = translation["translatedText"] as? String {                                            completion(translatedText)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch {
                    
                    print("error in JSONSerialization")
                    
                }
                
            }
            
        })
        task.resume()
    }
    
    
}

