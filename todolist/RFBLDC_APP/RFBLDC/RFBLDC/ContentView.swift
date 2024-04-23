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



var GLBPeripheral : CBPeripheral?
var GLBCharacteristic : CBCharacteristic!
var GlobalVoltage = "000"
var GlobalSpeed = "000"
var GlobalMessage = "000"
var GramValue : Int  = 100
var PWMValue  : Int = 10

class PID_Parameter_Class: ObservableObject{
    @Published var KP: Float = 0.11
    @Published var KI: Float = 0.1
    @Published var KD: Float = 0.1
}
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
    var sendCharacteristic: [CBCharacteristic]?
    var BTmodule: CBPeripheral?
    @Published var PID_Parameters = PID_Parameter_Class()
    var BTName: BTDeviceName = .Default
    
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
        self.centralManager? .scanForPeripherals(withServices: nil)
        PeripheralStatus = .scaning
        BTName = .Default
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
                    Message = String(messageString)
                }
            }
            else if let prefixRange = bufferString.range(of: "0X31")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("MessageBox: \(messageString)")
 //                   GlobalMessage = String(messageString)
                    Message = String(messageString)
                }
            }
            if let prefixRange = bufferString.range(of: "0X31P")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("KP: \(messageString)")
                    if let temp = Float(messageString)
                    {
                        PID_Parameters.KP = temp
                        print("KP from Controller:\(self.PID_Parameters.KP)")
                    }
                    else
                    {
                        print("Unrapping error")
                    }
                }
            }
            else if let prefixRange = bufferString.range(of: "0X31I")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("MessageBox: \(messageString)")
                    if let temp = Float(messageString)
                    {
                        PID_Parameters.KI = temp
                        print("KI from Controller:\(self.PID_Parameters.KI)")
                    }
                    else
                    {
                        print("Unrapping error")
                    }
                }
            }
            else if let prefixRange = bufferString.range(of: "0X31D")
            {
                let messagrString0 = bufferString[prefixRange.upperBound...]
                if let sepratorRange = messagrString0.range(of: "\n"){
                    
                    let messageString = messagrString0[..<sepratorRange.lowerBound]
                    print("MessageBox: \(messageString)")
                    if let temp = Float(messageString)
                    {
                        PID_Parameters.KD = temp
                        print("KD from Controller:\(self.PID_Parameters.KD)")
                        let confirmBit = Data(bytes : "E", count: "E".count)
                        GLBPeripheral?.writeValue(confirmBit, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)//for PID calibration confirm
                    }
                    else
                    {
                        print("Unrapping error")
                    }
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
                        ImageView()
                        Text("Message:\(bluetoothViewModel.Message)")
                            .frame(width: 380, height: 30,alignment: .leading)
                            .font(.headline)
                        NavigationLink(
                            destination: Linechart().frame(width: 380, height: 500, alignment: .topLeading),
                            label:{
                                Text("Force Chart->")
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
                .frame(width: 380,alignment: .leading)
            Text("Device:\(bluetoothViewModel.PeripheralStatus.rawValue)")
                .frame(width: 380,alignment: .leading)
  //              .fontWeight(.heavy)
/***********************************************************************************/
            HStack{
                Text("Battery: ")
                    .fontWeight(.heavy)
  //                  .frame(width: 90, height: 10, alignment: .leading)
                ZStack{
                    RoundedRectangle(cornerRadius: 1)
                        .foregroundColor(.green)
                        .frame(width: 90, height: 15, alignment: .trailing)
                        .padding(.trailing,30)
                    BatteryView()
                }
                .frame(width: 70, height:15)
                .padding()
                Text("voltage:\(bluetoothViewModel.Voltage)")
                    .padding()
            }
            .frame(width: 380, height: 20, alignment: .leading)
            PowerButton()
            PIDSlideBar()

        }
    }
}


struct BatteryView : View{
    var body: some View{
            GeometryReader{ geo in
            RoundedRectangle(cornerRadius:5)
                    .stroke(lineWidth: 2)
                    .frame(width: 100)
                
        }
    }
    
}

struct ImageView: View{
    @StateObject private var bluetoothViewModel = BluetoothViewModel()
    var body: some View{
        switch bluetoothViewModel.BTName
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
    }
}

struct PIDSlideBar : View{
    @StateObject private var bluetoothViewModel = BluetoothViewModel()
 /*   @State var KP: Float = BluetoothViewModel().PID_Parameters.KP
    @State var KI: Float = BluetoothViewModel().PID_Parameters.KI
    @State var KD: Float = BluetoothViewModel().PID_Parameters.KD*/
    @State private var CFbutton = false
    var presurfix: String = "["

    

    var body: some View{
        HStack{
            VStack{
                Slider(value:$bluetoothViewModel.PID_Parameters.KP, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                Slider(value:$bluetoothViewModel.PID_Parameters.KI, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                Slider(value:$bluetoothViewModel.PID_Parameters.KD, in: 0...1, step: 0.01)
                    .padding()
                    .frame(width: 200, height: 30)
                
            }
            VStack{
                Text("KP: \(String(format: "%.2f",bluetoothViewModel.PID_Parameters.KP))")
                    .frame(width: 70, height: 30, alignment: .leading)
                Text("KI: \(String(format: "%.2f",bluetoothViewModel.PID_Parameters.KI))")
                    .frame(width: 70, height: 30, alignment: .leading)
                Text("KD: \(String(format: "%.2f",bluetoothViewModel.PID_Parameters.KD))")
                    .frame(width: 70, height: 30, alignment: .leading)
            }
            VStack{
                Button(action:{
                    CFbutton.toggle()
                }){
                    Text("Set")
                        .frame(width: 90)
                        .onTapGesture {
                         var   APPdata = Data(bytes : presurfix , count: presurfix.count)
    
                            var floatToString = String(bluetoothViewModel.PID_Parameters.KP)
                            APPdata = Data(bytes: floatToString, count: floatToString.count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            APPdata = Data(bytes : "P", count: "P".count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            
                            floatToString = String(bluetoothViewModel.PID_Parameters.KI)
                            APPdata = Data(bytes: floatToString, count: floatToString.count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            APPdata = Data(bytes : "I", count: "I".count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            
                            floatToString = String(bluetoothViewModel.PID_Parameters.KD)
                            APPdata = Data(bytes: floatToString, count: floatToString.count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            
                            APPdata = Data(bytes : "D", count: "D".count)
                            GLBPeripheral?.writeValue(APPdata, for: GLBCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                            print("Send: \(APPdata)")
                            //print("PID sent:\(KP) \(KI) \(KD)")
                        }
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

struct PowerButton: View{
    @State var isPoweredOn = false
    @State private var text:String = "Off"
    @State var MessageBox : String = GlobalMessage

    func changeText(_input: String)->String{
        var newString:String = "1234567"
        let Motoroff: String = "0X13MOffe"
        let Motoron:String = "0X13MOne"
        var APPdata = Data(bytes : Motoron, count: Motoron.count)
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
            .font(.system(size: 20,weight: .bold))
            .frame(width: 380)
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
