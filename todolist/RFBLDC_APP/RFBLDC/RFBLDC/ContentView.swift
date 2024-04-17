//
//  ContentView.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/8/26.
//

import SwiftUI
import CoreBluetooth
import UIKit
import Charts

let DeviceService: CBUUID = CBUUID(string: "0x9ECADC24-0EE5-A9E0-93F3-A3B50100406E")
let DeviceWrite: CBUUID = CBUUID(string: "0x9ECADC24-0EE5-A9E0-93F3-A3B50200406E")
let DeviceCharacteristic: CBUUID = CBUUID(string: "9ECADC24-0EE5-A9E0-93F3-A3B50300406E")

enum ConnectionStatus: String{
    case connected
    case disconnected
    case scaning
    case connecting
    case error
}

enum BTDeviceName: String{
    case GoKart
    case EWagon
    case Drone
    case Default
}

var BTName: BTDeviceName = .Default



var GLBPeripheral : CBPeripheral?
var GLBCharacteristic : CBCharacteristic!
var GlobalVoltage = "000"
var GlobalSpeed = "000"
var GlobalMessage = "000"
var GramValue : Int  = 100
var PWMValue  : Int = 10

/*class GlobalData: ObservableObject {
    @Published var Speed:String = GlobalSpeed
    @Published var Voltage:String = GlobalVoltage
    @Published var Message:String = GlobalMessage
}*/

class BluetoothViewModel: NSObject, ObservableObject{
    private var centralManager: CBCentralManager?
//    @state var BTobservedData : GlobalData?
    @Published var Speed:String = ""
    @Published var Voltage:String = ""
    @Published var Message:String = ""
    
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var bluetoothState = ""
    @Published var PeripheralStatus: ConnectionStatus = .disconnected
//    @Published var Messagebox = "1"
    var sendCharacteristic: [CBCharacteristic]?
//    @Published var Speedvalue = ""
    var BTmodule: CBPeripheral?
    
    
    override init(){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
//        super.init(){

 //       }
    }

}


extension BluetoothViewModel: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case . unknown:
            break
        case . resetting:
            bluetoothState = "Bluetooth Resetting"
            break
        case . unsupported:
            bluetoothState = "Bluetooth Unsupported"
            break
        case . unauthorized:
            bluetoothState = "Bluetooth Unauthorized"
            break
        case . poweredOff:
            bluetoothState = "Bluetooth Off"
            break
        case . poweredOn:
            self.centralManager? .scanForPeripherals(withServices: nil)
            PeripheralStatus = .scaning
            bluetoothState = "Bluetooth On"
            break
        @unknown default:
            break;
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let deviceName = advertisementData [CBAdvertisementDataLocalNameKey] as? String, deviceName.contains("E-WAGON")||deviceName.contains("KEVIN BLE"){
            if(deviceName.contains("022191"))
            {
                print("found")
            }
            if(deviceName.contains("942"))
            {
                BTName = .GoKart
            }
            else if(deviceName.contains("E-WAGON")||(deviceName.contains("KEVIN BLE")))
            {
                BTName = .EWagon
            }
            else if(deviceName.contains("Drone"))
            {
                BTName = .Drone
            }
            else
            {
                BTName = .Default
            }
            self.BTmodule = peripheral
            self.centralManager?.stopScan()
            self.centralManager?.connect(peripheral,options: nil)
            PeripheralStatus = .connecting
            self.peripheralNames.removeAll();
            self.peripherals.removeAll();
            print("Found BLE")
        }
        if !peripherals.contains(peripheral)
        {
            self.peripherals.insert(peripheral, at: 0)
            self.peripheralNames.insert((peripheral.name ?? "unnamed device"), at: 0)
        }
        /*   if self.peripherals.count == 30{
         self.peripheralNames.removeAll();
         self.peripherals.removeAll();
         }*/
        else{
            // if NSNumber
        }
        
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        
        print("Connected")
        PeripheralStatus = .connected
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        centralManager?.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error?.localizedDescription ?? "no error")
        PeripheralStatus = .error
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral")
        PeripheralStatus = .disconnected
    }
}

extension BluetoothViewModel: CBPeripheralDelegate{

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services{
            for service in services{
                print("Discovered service: \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
        }
    }
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            peripheral.setNotifyValue(true, for: characteristic)
            print("found characteristic\(characteristic), Ready for data")
//            let bytes:String = "0X13MOne"
 //           let APPdata = Data(bytes : bytes, count: bytes.count)
            if characteristic.properties.rawValue == 0x04{          // if the characteristic is the write service
             //   peripheral.writeValue(APPdata, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
             //   print("write sucess")
                GLBPeripheral = peripheral
                GLBCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard let data = characteristic.value else {
            print("No data received for \(characteristic.uuid.uuidString)")
            return
        }
     
        let bluetoothdata = data
        if let bufferString:String = String(data: bluetoothdata, encoding: .utf8)
        {
            //        buffer.append(data)
                if let prefixRange = bufferString.range(of: "0x14")
                {
                    let messagrString0 = bufferString[prefixRange.upperBound...]
                    if let sepratorRange = messagrString0.range(of: "\n"){
                        let messageString = messagrString0[..<sepratorRange.lowerBound]
                        print("Received: \(messageString)")
                        if let temp = Int(messageString)
                        {
                            GramValue = temp
                        }
                        else
                        {
                            print("Unrapping error")
                        }
                    }
            }
            else if let prefixRange = bufferString.range(of: "PWM")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("PWM: \(messageString)")
                    if let temp = Int(messageString)
                    {
                        PWMValue = temp
                    }
                    else
                    {
                        print("Unrapping error")
                    }
                }
            }
            else if let prefixRange = bufferString.range(of: "VBat")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("BAT: \(messageString)")
                    Voltage = String(messageString)
                }
            }
            else if let prefixRange = bufferString.range(of: "0x13")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("MessageBox: \(messageString)")
                    GlobalMessage = String(messageString)
                    Message = String(messageString)
//                    self.BTobservedData.Message = GlobalMessage
//                    BTobservedData.Message = GlobalMessage
                    
                }
            }
        }
        else
        {
            print("failed to convert string")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil)
        {
            print("data sending failed:\(String(describing: error))")
        }
    }
}

struct ContentView: View{
    @StateObject private var bluetoothViewModel = BluetoothViewModel()
    var body: some View{
        VStack{
            VStack{ //This Vstack contains the BLE info and device list
                NavigationView
                {
                    VStack{
                        List(bluetoothViewModel.peripheralNames, id: \.self) {
                            peripheral in
                            Text(peripheral)
                        }
                        .foregroundColor(.gray)
                        .navigationTitle("Devices list:")
                        Text("Message:\(bluetoothViewModel.Message)")
                            .frame(width: 380, height: 30,alignment: .leading)
                            .font(.headline)
                        NavigationLink(
                            destination: Linechart().frame(width: 380, height: 500, alignment: .topLeading),
                            label:{
                                Text("Information page->")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .background(Color.blue)
                                    .cornerRadius(5)
                                    .shadow(radius: 10)
                            })
                        .frame(width: 380, height: 20, alignment: .trailing)
                    }
                }
            }
            Text("Status:\(bluetoothViewModel.bluetoothState)")
                .foregroundColor(.black)
            Text("Device:\(bluetoothViewModel.PeripheralStatus.rawValue)")
                .fontWeight(.heavy)
/***********************************************************************************/
            switch BTName
            {
            case .GoKart:
                Image("942 Image").resizable()
                    .frame(width: 150, height: 150)
                Text("942 Extream Go-Kart")
            case .EWagon:
                    Image("EWagon Image").resizable()
                    .frame(width: 150, height: 150)
                VStack{
                    Text("Radioflyer E-Wagon")
                }
                //                break
            case .Drone:
                //               Image("Drone Image").resizable()
                //                    .frame(width: 150, height: 150)
                Text("Drone: KV.1")
            case .Default:
                Text("Unknown product")
                
            }
            PowerButton()
                .padding(/*@START_MENU_TOKEN@*/EdgeInsets()/*@END_MENU_TOKEN@*/)
            HStack{
                Text("Battery: ")
                    .fontWeight(.heavy)
                    .frame(width: 90, height: 10, alignment: .leading)
                ZStack{
                    RoundedRectangle(cornerRadius: 1)
                        .foregroundColor(.green)
                        .frame(width: 40, height: 15, alignment: .trailing)
                        .padding(.trailing,30)
                    VStack{
                        BatteryView()
                    }
                    
                }
                .frame(width: 70, height:15)
                .padding()
                Text("voltage:\(bluetoothViewModel.Voltage)")
            }
            PIDSlideBAr()

        }
    }
}


struct BatteryView : View{
    var body: some View{
            GeometryReader{ geo in
            RoundedRectangle(cornerRadius:5)
                    .stroke(lineWidth: 2)
        }
    }
    
}

struct PIDSlideBAr : View{
    @State private var KP: Float = 0.01
    @State private var KI: Float = 0.01
    @State private var KD: Float = 0.01
    @State private var CFbutton = false
    
    var body: some View{
        HStack{
            VStack{
                Slider(value:$KP, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                Slider(value:$KI, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                Slider(value:$KD, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                
            }
            VStack{
                Text("KP: \(String(format: "%.2f",KP))")
                    .frame(width: 70, height: 30, alignment: .leading)
                Text("KI: \(String(format: "%.2f",KI))")
                    .frame(width: 70, height: 30, alignment: .leading)
                Text("KD: \(String(format: "%.2f",KD))")
                    .frame(width: 70, height: 30, alignment: .leading)
            }
            VStack{
                Button(action:{
                    CFbutton.toggle()
                }){
                    Text("Set")
                        .frame(width: 90)
                }
                .font((.system(size: 30, weight: .bold)))
                .background(.gray)
                .opacity(0.5)
                .cornerRadius(10)
                .frame(width: 90, alignment: .leading)
                Text(CFbutton ? "SET OK" : "SET FAILED")
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            }
        }
        .frame(width: 380, alignment: .leading)
    }
}

/*struct TextView: View {

    var body: some View {
        Text("Message:\(observedData.Message)")
        Text("Voltage:\(observedData.Voltage)")
            .fontWeight(.heavy)
            .frame(width: 200, height: 10, alignment: .leading)
        
    }
}*/

struct PowerButton: View{
    @State var isPoweredOn = false
    @State private var text:String = "Off"
    @State var MessageBox : String = GlobalMessage

    func changeText(_input: String)->String{
        var newString:String = "1234567"
        let Motoroff: String = "0X13MOffe"
        let Motoron:String = "0X13MOne"
        var APPdata = Data(bytes : Motoron, count: Motoron.count)
//        let APPdata1 = Data(bytes : bytes, count : Motoroff.count)
        if(isPoweredOn)
        {
            newString = "On"
            APPdata = Data(bytes : Motoron, count: Motoron.count)
            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            print("Write to peripheral: \(APPdata)")
            print("found characteristic\(GLBCharacteristic), Ready for data")
        }
        else
        {
            APPdata = Data(bytes : Motoroff, count: Motoroff.count)
            newString = "Off"
            print("Write to peripheral: \(APPdata)")
            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
        }
        return newString
    }
    
    var body:some View{
        Toggle("Power:\(changeText(_input: text))", isOn: $isPoweredOn)
     //       .padding()
            .font(.system(size: 20,weight: .bold))
            .frame(width: 200, height: 10, alignment: .leading)
    }
    
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
//        SplashScreenView()
        ContentView()
    }
}



 

/*struct ContentView: View {
    var emoji = ["🚗","🚕","🚙","🏎","😃","😁","🤣","🚓","🚗","🚕","🚙","🏎","😃","😁","🤣","🏎"]
    @State var emojicount = 8
    var body: some View {
        VStack{
            ScrollView{
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 65))]){
                        ForEach(emoji[0..<emojicount], id: \.self, content:{ emoji in
                            CardView(content: emoji)})
                            .aspectRatio(2/3, contentMode: .fit)
                          }
                            .padding(.horizontal).foregroundColor(.yellow)
                        }
                    Spacer()
                    HStack{
                            add
                            Spacer()
                            remove
                          }
                    .font(.largeTitle)
                    .padding(.horizontal)
                    .padding(.horizontal).foregroundColor(.blue)
        }
    }
    var remove: some View {
        Button(action: {
            if emojicount>1{
                emojicount -= 1}
        }, label: {
                Image(systemName: "minus.circle")
            
        })
    }
    var add: some View{
        Button(action: {
            if emojicount < emoji.count{
                emojicount += 1}
        }, label:{
            Image(systemName: "plus.circle")
        })
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
.previewInterfaceOrientation(.portrait)
        ContentView()
            .preferredColorScheme(.light    )
    }
}

struct CardView: View{
    var content: String
    @State var isFaceup:Bool = true//default value needed in swift
    let shape = RoundedRectangle(cornerRadius: 20)
    var body: some View{
        ZStack{
            if isFaceup{
            shape.fill().foregroundColor(.white)
            shape.strokeBorder(lineWidth: 5)//keep the full card view(not cut off)
            Text(content).font(.largeTitle)
            }
            else{
                shape.fill()
            }
        }
        .onTapGesture {
            isFaceup = !isFaceup
        }
    }
}*/
