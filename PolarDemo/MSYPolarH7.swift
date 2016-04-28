//
//  MSYPolarH7.swift
//  fbLogin
//
//  Created by Mahendra Yadav on 1/29/16.
//  Copyright © 2016 Appstudioz. All rights reserved.
//

//http://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor


import UIKit
import CoreBluetooth
import QuartzCore


protocol polarDeledate{
    
    func updateStatus(bpm:String)
    func updateBPM(status:String)
}


class MSYPolarH7: NSObject , CBCentralManagerDelegate, CBPeripheralDelegate {

    
    let POLARH7_HRM_DEVICE_INFO_SERVICE_UUID = "180A"
    let POLARH7_HRM_HEART_RATE_SERVICE_UUID = "180D"
    
    
    let POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID = "2A37"
    let POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID = "2A38"
    let POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID = "2A29"
    
    
    var polarDel:polarDeledate?
    
    
    //MARK:- Var Init
    
    var centralManager:CBCentralManager?
    var polarH7HRMPeripheral:CBPeripheral?
    
    //MARK:- Make Singleton
    class var sharedInstance: MSYPolarH7 {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: MSYPolarH7? = nil
        }
        dispatch_once(&Static.onceToken) {
            
            Static.instance = MSYPolarH7()
            
        }
        return Static.instance!
    }
    
    
    func startScanningDevice(){
        let cManager=CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        //cManager.delegate=self
        
       // cManager.scanForPeripheralsWithServices([CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID),CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID)], options: nil)
        cManager.scanForPeripheralsWithServices(nil, options: nil)
        self.centralManager=cManager
    }
    
    
    //MARK:- CBCentralManager Delagates
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate=self
        peripheral.discoverServices(nil)
        
        if peripheral.state == CBPeripheralState.Connected {
            print("Connected")
            if let msyPolar = polarDel {
                msyPolar.updateStatus("Connected")
            }
        }else{
            print("Not connected")
            if let msyPolar = polarDel {
                msyPolar.updateStatus("Not connected")
            }

        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("dis connected")
        if let msyPolar = polarDel {
            msyPolar.updateStatus("Disconnected")
        }
        self.centralManager?.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        print("Restored....")
    }
    

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let localName=advertisementData[CBAdvertisementDataLocalNameKey]
        if localName?.length > 0 {
            print("Found device is \(localName)")
            self.centralManager?.stopScan()
            peripheral.delegate=self
            self.centralManager?.connectPeripheral(peripheral, options: nil)
            self.polarH7HRMPeripheral=peripheral
        }
        
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        if(central.state == CBCentralManagerState.PoweredOff){
            print("CoreBluetooth BLE hardware is powered off")
        }else if(central.state == CBCentralManagerState.PoweredOn){
            print("CoreBluetooth BLE hardware is powered on and ready")
            self.centralManager?.scanForPeripheralsWithServices([CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID),CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID)], options: nil)
        }else if(central.state == CBCentralManagerState.Unauthorized){
            print("CoreBluetooth BLE state is unauthorized")
        }else if(central.state == CBCentralManagerState.Unknown){
            print("CoreBluetooth BLE state is unknown")
        }else if(central.state == CBCentralManagerState.Unsupported){
            print("CoreBluetooth BLE hardware is unsupported on this platform")
        }
        
        
    }
    
    
    
    //MARK:- CBPeripheralDelegate Delagates
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        for service:CBService in peripheral.services! {
            print("discover service \(service.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service)
        }
        
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        if service.UUID == CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID) {
            for aChar:CBCharacteristic in service.characteristics! {
                // Request heart rate notifications
                if aChar.UUID == CBUUID(string: POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID) {
                    self.polarH7HRMPeripheral?.setNotifyValue(true, forCharacteristic: aChar)
                    print("Found heart rate measurement characteristic")
                }else if aChar.UUID == CBUUID(string: POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID){
                     self.polarH7HRMPeripheral?.readValueForCharacteristic(aChar)
                    print("Found body sensor location characteristic")
                }
            }
        }
        
        
        
        // Retrieve Device Information Services for the Manufacturer Name
        
        if service.UUID == CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID) {
            for aChar:CBCharacteristic in service.characteristics! {
                // Request heart rate notifications
                if aChar.UUID == CBUUID(string: POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID) {
                     self.polarH7HRMPeripheral?.readValueForCharacteristic(aChar)
                    print("Found a device manufacturer name characteristic")
                }
            }
        }
        
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        // Updated value for heart rate measurement received
        if characteristic.UUID == CBUUID(string: POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID) {
            //print(characteristic)
            //self.getHeartBPMData(characteristic, error:error!)
            self.getHeartBPMData(characteristic)
        }
        
        
        // Retrieve the characteristic value for manufacturer name received
        if characteristic.UUID == CBUUID(string: POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID ) {
            getManufacturerName(characteristic)
        }
        
        
        // Retrieve the characteristic value for the body sensor location received
        else if characteristic.UUID == CBUUID(string: POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID ) {
            getBodyLocation(characteristic)
        }
        
        
    }
    
    
    //MARK:- CBCharacteristic helpers
    
   // func getHeartBPMData(characteristic:CBCharacteristic,error:NSError)
    func getHeartBPMData(characteristic:CBCharacteristic){
        
       //print("Hello")
       // print("characteristic \(characteristic)")
        
        if characteristic.value == nil {
            return
        }
        
        
        let data = characteristic.value
        let reportData = UnsafePointer<UInt8>(data!.bytes)
        var bpm : UInt16
        if (reportData[0] & 0x01) == 0 {
            bpm = UInt16(reportData[1])
        } else {
            bpm = UnsafePointer<UInt16>(reportData + 1)[0]
            bpm = CFSwapInt16LittleToHost(bpm)
        }
        
        let outputString = String(bpm)
        print("bpm is \(outputString)")
        
        if let msyPolar = polarDel {
            msyPolar.updateBPM(outputString)
        }
        
        //doHeartBeat()
        
        return
        
       // return outputString

    }
    
    func getManufacturerName(characteristic:CBCharacteristic){
        let manufacturerName=NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        print("Manufacturer is \(manufacturerName)")
        
        return
        
    }
    
    func getBodyLocation(characteristic:CBCharacteristic){
        
        
    }
    
    func doHeartBeat(){
        
        
    }
    
}
