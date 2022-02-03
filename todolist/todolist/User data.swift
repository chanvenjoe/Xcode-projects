//
//  User data.swift
//  todolist
//
//  Created by Chuanfeng Chou on 2022/2/2.
//

import Foundation

class todo: ObservableObject{
    @Published var todolist:[ToDoItem]
    var count = 0 //store the number in the array
//    
//    init(){
//        self.todolist = []
//    }
    init(data:[ToDoItem]){
        self.todolist = []
        for item in data{
            self.todolist.append(ToDoItem(title: item.title, duedate:  item.duedate, id:self.count))
            count+=1
            
        }
    }
    func check(id:Int){
        self.todolist[id].isChecked.toggle()
    }
}

struct ToDoItem:Identifiable{
    var title:String = ""
    var duedate:Date = Date()
    var isChecked:Bool = false
    
    var id:Int = 0
}

