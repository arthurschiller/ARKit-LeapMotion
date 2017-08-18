//
//  Peripheral.swift
//  Mac App
//
//  Created by Arthur Schiller on 28.07.17.
//

import CoreBluetooth

class LeapMotionGesturePeripheral: NSObject {
    private let manager: CBPeripheralManager
    private let services: [CBMutableService]
    private let peripheralName: String
    private var subscribers: [CBUUID:[CBCentral]] = [:]
    private var servicesAdded = false
    
    init(name: String, manager: CBPeripheralManager, services: [CBMutableService]) {
        self.peripheralName = name
        self.manager = manager
        self.services = services
        super.init()
        self.manager.delegate = self
    }
    
    private var lhDataString: String = "" {
        didSet {
            updateValue(forCharacteristic: LeapMotionGestureService.lhData)
        }
    }
    
    private var leapHandData: Data? = nil {
        didSet {
            guard leapHandData != nil else {
                return
            }
            updateValue(forCharacteristic: LeapMotionGestureService.leapHandData)
        }
    }
    
    func set(lhDataString: String) {
        self.lhDataString = lhDataString
    }
    
    func set(leapHandData: Data) {
        self.leapHandData = leapHandData
    }
    
    private func updateValue(forCharacteristic uuid: CBUUID) {
        guard let centrals = subscribers[uuid],
            !centrals.isEmpty,
            let value = value(forCharacteristic: uuid),
            let characteristic = (myBluetoothService?.characteristics?.filter { $0.uuid == uuid })?.last as? CBMutableCharacteristic
        else { return }
        manager.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
        print("updating value: \(value)")
    }
    
    func startAdvertising() {
        manager.stopAdvertising()
        let UUIDs: [CBUUID] = services.map { $0.uuid }
        let advData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: UUIDs,
                                      CBAdvertisementDataLocalNameKey: peripheralName,
                                      CBAdvertisementDataIsConnectable: NSNumber(value: true)]
        manager.startAdvertising(advData)
    }
    
    func stopAdvertising() {
        print("Advertising stopped")
        manager.stopAdvertising()
    }
    
    func value(forCharacteristic uuid: CBUUID) -> Data? {
        switch uuid {
        case LeapMotionGestureService.leapHandData:
            return leapHandData
        case LeapMotionGestureService.lhData:
            return lhDataString.data(using: .utf8)
        default:
            return nil
        }
    }
    
    convenience init(name: String = "LeapMotionGestureService preferences") {
        let service = CBMutableService(type: LeapMotionGestureService.uuid, primary: true)
        let characteristics = LeapMotionGestureService.characteristics.map {
            CBMutableCharacteristic(type: $0, properties: [.read, .notify], value: nil, permissions: .readable)
        }
        service.characteristics = characteristics
        let serialQueue = DispatchQueue(label: "io.swifting.bluetooth.queue", attributes: [])
        let manager = CBPeripheralManager(delegate: nil, queue: serialQueue)
        self.init(name: name, manager: manager, services: [service])
    }
    
    var myBluetoothService: CBMutableService? {
        return services.filter { $0.uuid == LeapMotionGestureService.uuid }.last
    }
}

extension LeapMotionGesturePeripheral: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let state = peripheral.state
        guard state == .poweredOn,
            !servicesAdded
            else { return }
        services.forEach { manager.add($0) }
        servicesAdded = true
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else { return }
        print("Advertising started")
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\nSubscribed \(central) to change notification of \(characteristic) ")
        var centrals = subscribers[characteristic.uuid] ?? []
        centrals.append(central)
        subscribers[characteristic.uuid] = centrals
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("\nSubscribed \(central) was removed from change notification of \(characteristic)")
        guard
            var centrals = subscribers[characteristic.uuid],
            let index = centrals.index(of: central)
        else { return }
        centrals.remove(at: index)
        subscribers[characteristic.uuid] = centrals
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        var error: CBATTError.Code = CBATTError.insufficientResources
        
        if let data = self.value(forCharacteristic: request.characteristic.uuid) {
            if request.offset > data.count {
                error = CBATTError.invalidOffset
            } else {
                let range: Range<Int> = request.offset..<data.count
                request.value = data.subdata(in: range)
                error = CBATTError.success
            }
        }
        print("\n\n READ REQUEST: \n\(request.characteristic.description) \n\(error)\n\n")
        peripheral.respond(to: request, withResult: error)
    }
}
