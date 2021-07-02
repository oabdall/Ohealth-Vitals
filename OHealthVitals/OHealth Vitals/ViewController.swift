//
//  ViewController.swift
//  OHealth Vitals
//
//  Created by Omar Abdalla on 7/1/21.
//

import UIKit
import CoreBluetooth
import Charts

var curPeripheral: CBPeripheral?
var txCharacteristic: CBCharacteristic?
var rxCharacteristic: CBCharacteristic?

class ViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var data = NSMutableData ()
    var rssiList = [NSNumber]()
    var peripheralList:[CBPeripheral] = []
    var characteristicList = [String: CBCharacteristic]()
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    
    let BLE_Service_UUID = CBUUID.init (string: "6e400001-b5a3-f393-e0a9-e50e24cca9e")
    let BLE_characteristic_uuid_Rx = CBUUID.init(string: "6e400003-b5a3-f393-e0a9-e50e24cca9e")
    let BLE_characteristic_uuid_Tx = CBUUID.init(string: "6e400002-b5a3-f393-e0a9-e50e24cca9e")
    
    var recievedData = [Int]()
    var showGraphIsOn = true
    
    @IBOutlet weak var showGraphLbl: UILabel!
    
    @IBOutlet weak var connectStatusLbl: UILabel!
    
    @IBOutlet weak var refreshBtn: UIImageView!
    
    @IBOutlet weak var showGraphBtn: UISwitch!
    
    @IBOutlet weak var chartBox: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connectStatusLbl.text = "Disconnected"
        connectStatusLbl.textColor = UIColor.red
        
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if curPeripheral != nil{
            centralManager?.cancelPeripheralConnection(curPeripheral!)
        }
        print("View Cleared")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Stop Scanning")
        
        centralManager?.stopScan()
            
        }
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        
        if central.state == CBManagerState.poweredOn {
            print("Bluetooth Enabled")
            startScan()
        }
        
        else{
            print("Bluetooth Disabled- make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "make sure that your blootooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: {(action: UIAlertAction) -> Void in self.dismiss(animated: true, completion: nil)})
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
            
        }

    }
    
    func startScan(){
        print("Now Scanning...")
        print("Service ID Search: \(BLE_Service_UUID)")
        
        peripheralList = []
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLE_Service_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) {_ in self.cancelScan()
            
        }
    }
    
    func cancelScan(){
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripheralList.count)")
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        curPeripheral = peripheral
        self.peripheralList.append(peripheral)
        self.rssiList.append(peripheral)
    }
    
}

    



