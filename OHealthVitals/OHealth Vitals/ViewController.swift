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
    
    let BLE_Service_UUID = CBUUID.init(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    let BLE_Characteristic_uuid_Rx = CBUUID.init(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    let BLE_Characteristic_uuid_Tx  = CBUUID.init(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    
    var receivedData = [Int]()
    var showGraphIsOn = true
    
    @IBOutlet weak var showGraphLbl: UILabel!
    
    @IBOutlet weak var connectStatusLbl: UILabel!
    
    @IBOutlet weak var chartBox: LineChartView!
    
    @IBAction func refreshBtn(_ sender: Any) {
        receivedData.removeAll()
        clearGraph()
        if (curPeripheral != nil) {
            centralManager?.cancelPeripheralConnection(curPeripheral!)
        }
        usleep(1000000)
        startScan()
    }
    
    @IBAction func showGraphBtn(_ sender: Any) {
        if (showGraphIsOn) {
            clearGraph()
            showGraphIsOn = false
        }
        else {
            showGraphIsOn = true
        }
    }
    
    
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
        self.rssiList.append(RSSI)
        peripheral.delegate = self
        
        if curPeripheral != nil{
            centralManager?.connect(curPeripheral!, options: nil)
        }
        
    }
    
    func restoreCentralManager() {
        centralManager?.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        
        print("-------------------------------------------------------")
        print("Connection complete")
        print("Peripheral info \(String(describing: curPeripheral))")
        
        cancelScan()
        
        peripheral.delegate = self
        
        peripheral.discoverServices([BLE_Service_UUID])
    }
    // Called when the central manager fails to connect to a peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        // Print error message to console for debugging purposes
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    // Called when the central manager disconnects from the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        connectStatusLbl.text = "Disconnected"
        connectStatusLbl.textColor = UIColor.red
    }
    
    // Called when the correct peripheral's services are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-------------------------------------------------------")
        
        // Check for any errors in discovery
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        // Store the discovered services in a variable. If no services are there, return
        guard let services = peripheral.services else {
            return
        }
        
        // Print to console for debugging purposes
        print("Discovered Services: \(services)")

        // For every service found...
        for service in services {
            
            // If service's UUID matches with our specified one...
            if service.uuid == BLE_Service_UUID {
                print("Service found")
                connectStatusLbl.text = "Connected!"
                connectStatusLbl.textColor = UIColor.blue
                
                // Search for the characteristics of the service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // Called when the characteristics we specified are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("-------------------------------------------------------")
        
        // Check if there was an error
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        // Store the discovered characteristics in a variable. If no characteristics, then return
        guard let characteristics = service.characteristics else {
            return
        }
        
        // Print to console for debugging purposes
        print("Found \(characteristics.count) characteristics!")
        
        // For every characteristic found...
        for characteristic in characteristics {
            // If characteritstic's UUID matches with our specified one for Rx...
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                // Subscribe to the this particular characteristic
                // This will also call didUpdateNotificationStateForCharacteristic
                // method automatically
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            
            // If characteritstic's UUID matches with our specified one for Tx...
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            
            // Find descriptors for each characteristic
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // Sets up notifications to the app from the Feather
    // Calls didUpdateValueForCharacteristic() whenever characteristic's value changes
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")

        // Check if subscription was successful
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")

        } else {
            print("Characteristic's value subscribed")
        }

        // Print message for debugging purposes
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    // Called when peripheral.readValue(for: characteristic) is called
    // Also called when characteristic value is updated in
    // didUpdateNotificationStateFor() method
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        // If characteristic is correct, read its value and save it to a string.
        // Else, return
        guard characteristic == rxCharacteristic,
        let characteristicValue = characteristic.value,
        let receivedString = NSString(data: characteristicValue,
                                      encoding: String.Encoding.utf8.rawValue)
        else { return }
        
        for i in 0..<receivedString.length {
            // Print for debugging purposes
            print(receivedString.character(at: i))
            let number:Int = Int(receivedString.character(at: i))
            receivedData.append(number)
        }
        
        if (receivedData.count > 100) {
            receivedData.removeFirst(receivedData.count-100)
        }
        if (showGraphIsOn && receivedData.count > 0) {
            displayGraph(dataDisplaying: receivedData)
        }
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: self)
    }
    
    // Called when app wants to send a message to peripheral
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }

    // Called when descriptors for a characteristic are found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
        // Print for debugging purposes
        print("*******************************************************")
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        
        // Store descriptors in a variable. Return if nonexistent.
        guard let descriptors = characteristic.descriptors else { return }
            
        // For every descriptor, print its description for debugging purposes
        descriptors.forEach { descript in
            print("function name: DidDiscoverDescriptorForChar \(String(describing: descript.description))")
            print("Rx Value \(String(describing: rxCharacteristic?.value))")
            print("Tx Value \(String(describing: txCharacteristic?.value))")
        }
    }
    
    // Graph the dataset to storyboard
    func displayGraph(dataDisplaying: [Int]) {
        
        // Array that will eventually be displayed on the graph.
        var lineChartEntry  = [ChartDataEntry]()
        
        // For every element in given dataset
        // Set the X and Y status in a data chart entry
        // and add to the entry object
        for i in 0..<dataDisplaying.count {
            let value = ChartDataEntry(x: Double(i), y: Double(dataDisplaying[i]))
            lineChartEntry.append(value)
        }

        // Convert lineChartEntry to a LineChartDataSet
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "EXG Data")
        
        // Customize graph settings to your liking
        line1.drawCirclesEnabled = false
        line1.colors = [NSUIColor.white]

        // Make object that will be added to the chart
        // and set it to the variable in the Storyboard
        let lineData = LineChartData(dataSet: line1)
        
        //chartBox.dragEnabled = true
        chartBox.setScaleEnabled(true)
        chartBox.pinchZoomEnabled = true
        
        chartBox.data = lineData

        // Settings for the chartBox
        chartBox.chartDescription?.text = "Retrieving Data..."
    }
    
    // Clear the graph by displaying a dataset with no elements
    func clearGraph() {
        let nullGraph = [Int]()
        displayGraph(dataDisplaying: nullGraph)
    }
}

    



