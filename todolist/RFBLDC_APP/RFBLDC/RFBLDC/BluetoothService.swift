//
//  BluetoothService.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/11/11.
//

import Foundation
import CoreBluetooth

enum ConnectionStatus{
    case connected
    case disconnected
    case scanning
    case connecting
    case error
}

let BT_device_UUI:CBUUID = CBUUID(string: "123")

class BluetoothService: NSObject,  ObservableObject{
    private var centralManager: CBCentralManager!
    var hallSensorPeripheral: CBPeripheral?
    @Published var peripheralStatus: ConnectionStatus = .disconnected
    
    override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeriipherals(){
        peripheralStatus =  .scanning
        centralManager.scanForPeripherals(withServices: [BT_device_UUI])//to fill your BT UUID in
        
    }
    
}

extension BluetoothService: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
 //           scanForPeripherals()
        }
    }
    
    
}
