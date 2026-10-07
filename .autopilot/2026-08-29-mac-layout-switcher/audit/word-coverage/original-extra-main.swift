import Foundation
for seq in ["plan b", "drive c", "vitamin d", "option f", "model r", "team e", "channel j", "привет b", "привет d", "привет c", "hello b", "hello z"] {
 let d=Detector(); var output=[String]()
 for word in seq.split(separator:" ").map(String.init) { let v=d.verdict(for:word); output.append(word+":"+String(describing:v)) }
 print(output.joined(separator:"\t"))
}
for word in ["люблю", "Люблю", "ЛЮБЛЮ", "k.,k.", "K.,k.", "K><K>", "bbc", "brb", "rfc", "xml", "файл", "Файл", "ФАЙЛ", "f", "F", "d", "D", "e", "E", "r", "R", "c", "C", "j", "J", "b", "B", "z", "Z", "a", "A", "i", "I", ",", ";", ".", "'", "[", "]", "`", "~"] {
 var states=[String]()
 for seed in ["","привет","hello"] { let d=Detector(); if !seed.isEmpty { _=d.verdict(for:seed) }; states.append(String(describing:d.verdict(for:word))) }
 print(([word,KeyMap.convert(word,to:.ru),KeyMap.convert(word,to:.en)]+states).joined(separator:"\t"))
}
