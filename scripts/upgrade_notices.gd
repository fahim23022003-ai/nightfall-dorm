class_name UpgradeNotices
extends RefCounted
# One readable lane. Count/label coalescing stays bounded even under rapid input.
var queue=[]
var active={}
var age=0.0
var clock=0.0
func push(label: String):
 if not queue.is_empty() and clock-queue[-1].time<.4:
  add(queue[-1],label);return
 if queue.size()>=6:add(queue[-1],label);return
 var row={"time":clock,"count":0,"labels":{}};add(row,label);queue.append(row)
func add(row,label):
 row.count=mini(1000000,int(row.count)+1)
 if row.labels.has(label):row.labels[label]+=1
 elif row.labels.size()<24:row.labels[label]=1
 else:row.labels["Other upgrades"]=int(row.labels.get("Other upgrades",0))+1
func update(delta: float,urgent: bool):
 clock+=delta
 if urgent:return
 if active.is_empty() and not queue.is_empty():active=queue.pop_front();age=0
 if not active.is_empty():
  age+=delta
  if age>2.8:active={}
func text() -> String:
 if active.is_empty():return ""
 return "%d upgrade%s · %s" % [active.count,"" if active.count==1 else "s",summary(active)]
func summary(row) -> String:
 var labels=[]
 for label in row.labels:labels.append(label+(" ×%d" % row.labels[label] if row.labels[label]>1 else ""))
 return ", ".join(labels)
func details() -> String:
 return summary(active) if not active.is_empty() else ""
