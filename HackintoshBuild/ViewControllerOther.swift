//
//  ViewControllerOther.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/1/17.
//  Copyright © 2020 bugprogrammer,Arabaku. All rights reserved.
//

import Cocoa

class ViewControllerOther: NSViewController {
    
    @IBOutlet weak var sipLable: NSTextField!
    @IBOutlet var textview: NSTextView!
    @IBOutlet weak var unclockButton: NSButton!
    @IBOutlet weak var rebuildButton: NSButton!
    @IBOutlet weak var spctlButton: NSButton!
    @IBOutlet weak var showButton: NSButton!
    @IBOutlet weak var hiddenButton: NSButton!
    
    let taskQueue = DispatchQueue.global(qos: .default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spctlButton.isEnabled = true
        
        guard let enabled = isSIPStatusEnabled else {
            sipLable.textColor = NSColor.red
            sipLable.stringValue = "SIP 状态未知"
            unclockButton.isEnabled = false
            rebuildButton.isEnabled = false
            return
        }
        if enabled {
            sipLable.textColor = NSColor.red
            sipLable.stringValue = "SIP 未关闭，请先关闭 SIP"
            unclockButton.isEnabled = false
            rebuildButton.isEnabled = false
        } else {
            sipLable.textColor = NSColor(named: "ColorGreen")
            sipLable.stringValue = "SIP 已关闭"
            unclockButton.isEnabled = true
            rebuildButton.isEnabled = true
        }
    }
    
    @IBAction func unlockSLE(_ sender: Any) {
        
        textview.string = ""
        
        if #available(OSX 10.15, *) {
            runBuildScripts("unlockSLE", [], "SLE 解锁成功")
        } else {
            let alert = NSAlert()
            alert.messageText = "系统版本低于 10.15，无需解锁"
            alert.runModal()
        }
    }
    
    @IBAction func rebuildCache(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("rebuildCache", [], "修复权限以及重建缓存成功")
    }
    
    @IBAction func spctl(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("spctl", [], "已开启未知来源安装")
    }
        
    @IBAction func timeMachineOptimize(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("timeMachine", ["0"], "时间机器已经满血运行，注意：如果用NAS备份，请使用AFP协议")
    }
    
    @IBAction func timeMachineReset(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("timeMachine", ["1"], "时间机器已经恢复默认状态")
    }
        
    @IBAction func showFiles(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("showhiddenFiles", ["true"], "已显示隐藏文件")
    }
    
    @IBAction func hiddenFiles(_ sender: Any) {
        textview.string = ""
        
        runBuildScripts("showhiddenFiles", ["false"], "隐藏文件状态已恢复")
    }
    
    func runBuildScripts(_ shell: String,_ arguments: [String],_ alertText: String) {
        AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.arguments = arguments
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        AraHUDViewController.shared.hideHUD()
                            
                        let alert = NSAlert()
                        if self.textview.string != "" {
                            alert.messageText = alertText
                        }
                        else {
                            alert.messageText = "操作失败"
                        }
                        alert.runModal()
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.textview.string
                    let nextOutput = previousOutput + "\n" + outputString
                    self.textview.string = nextOutput
                    let range = NSRange(location:nextOutput.count,length:0)
                    self.textview.scrollRangeToVisible(range)
                })
            }
        }
    }
    
}
