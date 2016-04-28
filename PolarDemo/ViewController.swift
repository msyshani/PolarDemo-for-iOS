//
//  ViewController.swift
//  PolarDemo
//
//  Created by Mahendra Yadav on 4/26/16.
//  Copyright © 2016 App Engineer. All rights reserved.
//

import UIKit


class ViewController: UIViewController,polarDeledate{
    
    
    @IBOutlet var connectButton:UIButton?
    @IBOutlet var statusLabel:UILabel?
    @IBOutlet var hrLabel:UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
       // MSYPolarH7.sharedInstance.startScanningDevice()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectWithPolar(sender:AnyObject){
        MSYPolarH7.sharedInstance.startScanningDevice()
        MSYPolarH7.sharedInstance.polarDel = self
    }
    
    
    
   //MARK :- update BPM
    func updateBPM(bpm:String) {
        hrLabel?.text = bpm
    }

    //MARK :- update Status
    func updateStatus(status:String) {
        statusLabel?.text = status
    }
}

