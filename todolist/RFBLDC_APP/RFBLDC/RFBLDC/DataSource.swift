//
//  DataSource.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2024/3/17.
//

import Foundation
import SwiftUI
import Charts

struct PullForceData: Identifiable{
    var time:Float
    var force:Double
    var id = UUID()//why i need to add this to be identifiable?
}

var LineChart : [PullForceData] = [
    .init(time: 0, force: 0),
    .init(time: 1, force: 1),
    .init(time: 3, force: 6)
]

struct Linechart: View{
    var body: some View{
        if #available(iOS 16.0, *) {
            GroupBox("Pull force data"){
                Chart{
                    ForEach(LineChart){
                        LineMark(
                            x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                            y:.value("Force", $0.force)
                        )
                        .foregroundStyle(.blue)
                    }
                }
            }
            .foregroundColor(.black)
            .fontWeight(.heavy)
            .fontWidth(.standard)
            .font(.headline)
        } else {
            // Fallback on earlier versions
        }
    }
}

struct DataSource_Previews: PreviewProvider{
    static var previews: some View{
        Linechart()
    }
}

