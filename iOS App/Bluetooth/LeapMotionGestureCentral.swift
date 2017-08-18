//
//  LeapMotionGestureCentral.swift
//  Mac App
//
//  Created by Arthur Schiller on 28.07.17.
//

import CoreBluetooth
import UIKit

protocol LeapMotionGestureCentralDelegate: class {
    func central(_ central: LeapMotionGestureCentral, didPerformAction action: LeapMotionGestureCentral.Action)
}

class LeapMotionGestureCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    weak var delegate: LeapMotionGestureCentralDelegate?
    
    let central: CBCentralManager
    
    override init() {
        //TODO: queue + manager
        let queue = DispatchQueue(label: "com.arthurschiller.bluetooth")
        central = CBCentralManager(delegate: nil, queue: queue)
        
        super.init()
        
        //TODO: delegate
        central.delegate = self
        
        //TODO: scan
        scanServices()
    }
    
    func scanServices() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [LeapMotionGestureService.uuid], options: nil)
    }
    
    //TODO: state updated
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanServices()
    }
    
    //TODO: peripheral found + stop + store + delegate + connect
    var peripheral: CBPeripheral?
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }
    
    //TODO: failed + un-store + scan + Main - Action.connectPeripheral(true)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error.debugDescription)
        self.peripheral = nil
        scanServices()
        DispatchQueue.main.async {
            self.delegate?.central(self, didPerformAction: Action.connectPeripheral(false))
        }
    }
    
    //TODO: connected: discover services + Main - Action.connectPeripheral(false)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([LeapMotionGestureService.uuid])
        DispatchQueue.main.async {
            self.delegate?.central(self, didPerformAction: Action.connectPeripheral(true))
        }
    }
    
    //TODO: disconnected + un-store + scan + Main - Action.disconnectPeripheral(Bool)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(error.debugDescription)
        self.peripheral = nil
        scanServices()
        DispatchQueue.main.async {
            self.delegate?.central(self, didPerformAction: LeapMotionGestureCentral.Action.disconnectPeripheral)
        }
    }
    
    //TODO: services discovererd + discover characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        guard let service = (peripheral.services?.filter { $0.uuid == LeapMotionGestureService.uuid })?.first else { return }
        peripheral.discoverCharacteristics(LeapMotionGestureService.characteristics, for: service)
    }
    
    //TODO: characteristics discovererd + read + subscribe + store
    var leapHandData: CBCharacteristic?
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        
        service.characteristics?.forEach {
            peripheral.readValue(for: $0)
            peripheral.setNotifyValue(true, for: $0)
            switch $0.uuid {
            case LeapMotionGestureService.leapHandData:
                leapHandData = $0
            default:
                return
            }
        }
    }
    
    //TODO: value updated + Main - Action.read(Value)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        guard let data = characteristic.value else { return }
        let response: Value
        
        switch characteristic.uuid {
        case LeapMotionGestureService.leapHandData:
            response = .leapHandData(data)
        default:
            return
        }
        DispatchQueue.main.async {
            self.delegate?.central(self, didPerformAction: .read(response))
        }
    }
    
}
extension LeapMotionGestureCentral {
    enum Action {
        case connectPeripheral(Bool)
        case disconnectPeripheral
        case read(Value)
    }
    
    enum Value {
        case leapHandData(Data)
    }
}

