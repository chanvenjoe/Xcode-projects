//
//  ContentView.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/8/26.
//

import SwiftUI
import CoreBluetooth


class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var bluetoothState = ""
    
    override init(){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            break
        case .resetting:break
        case . unsupported:break
        case . unauthorized:break
        case . poweredOff: break
        case . poweredOn:
            self.centralManager? .scanForPeripherals(withServices: nil)
            break
        @unknown default:
            break;
        }
        
        bluetoothState = "\(central.state)"
    
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String:Any], rssi RSSI: NSNumber) {
        print("\(peripheral)")
        self.peripheralNames.append("\(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append((peripheral.name ?? "unnamed device"))
        }

    }
    
}

struct ContentView: View{
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View{
        VStack{
                NavigationView
                {
                    List(bluetoothViewModel.peripheralNames, id: \.self) {
                        peripheral in
                        Text(peripheral)
                        }
                    .navigationTitle("BT Device list:")
                }
            Text("status:\(self.bluetoothViewModel.bluetoothState)")
  /*          Divider()
            List{
                ForEach(self.bluetoothViewModel.peripheralNames, id: \.self){
                    item in Text("\(item)")
                }
            }*/
            
/*            Image("942 Image").resizable()
                .frame(width: 150, height: 150)
            Text("942 Extream Go-Kart")*/
        }
    }
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
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
