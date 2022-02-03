//
//  ContentView.swift
//  todolist
//
//  Created by Chuanfeng Chou on 2022/1/29.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var userdata:todo = todo(data: [ToDoItem(title: "Xcode course", duedate: Date()),
        ToDoItem(title: "STM32", duedate: Date()),
        ToDoItem(title: "Music", duedate: Date())
                                   ])
    var body: some View {
        ScrollView(.vertical,showsIndicators:true){
            VStack {
                ForEach(self.userdata.todolist){item in
                    SingleCardView(index: item.id)
                        .environmentObject(self.userdata)
                        .padding()
                }
    //            SingleCardView(title:"Home work")
    //            SingleCardView(title:"Learning Xcode")
    //            SingleCardView(title:"Learning STM32")
            }
            
        }
    }
}

struct SingleCardView: View{

    @EnvironmentObject  var userdata:todo
    var index:Int
    var body: some View{
        HStack {
            Rectangle()
                .frame(width: 6)
                .foregroundColor(.blue)
            VStack(alignment:.leading, spacing:6.0) {
                Text(self.userdata.todolist[index].title)
                    .font(.headline)
                    .fontWeight(.heavy)
                Text(self.userdata.todolist[index].duedate.description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.leading)
            Spacer()
            
            Image(systemName: self.userdata.todolist[index].isChecked ? "checkmark.square" : "square")
                .imageScale(.large)
                .padding(.trailing)
                .onTapGesture {
                    self.userdata.check(id: self.index)
                }
            
        }
        .frame(height:80)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10,x:0,y:10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
