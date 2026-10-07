import Foundation
let bases = ["ghbdtn", "rfr", "yt", "b", "z", "d", "f", "c", "e", "r", "j", "Rfr", "GHBDTN", "hello", "ozon", "OZON", "api", "BBC", "xml", "jq", "ns", "привет", "файл", "и", "я", "руддщ", "ерфе", "cgfcb,j", "k.,k.", "x`", "[v", "vjuen"]
let wrappers: [(String,String)] = [("",""),("","!"),("","?"),("","?!"),("(",")"),("(",")!"),("((","))"),("(",""),("",")"),("!",""),("?",""),("","()"),("",","),("","."),("",";"),("\"","\""),("'","'")]
print("word\tfresh\truContext\tenContext\tconvertedRU\tconvertedEN")
for base in bases {
 for (left,right) in wrappers {
  let word=left+base+right; var answers:[String]=[]
  for seed in ["","привет","hello"] { let d=Detector(); if !seed.isEmpty { _ = d.verdict(for:seed) }; answers.append(String(describing:d.verdict(for:word))) }
  print(([word]+answers+[KeyMap.convert(word,to:.ru),KeyMap.convert(word,to:.en)]).joined(separator:"\t"))
 }
}
for word in ["hello_world","snake_case","camelCase","someVariable","HTTPServer","ghbdtn123","b2b","привет7","a+b=c","node.js","example.com","https://example.com","user@example.com","!ghbdtn","ghbdtn?key=value","foo(bar)","(api)","version1.0","C++","C#"] {
 let d=Detector(); print([word,String(describing:d.verdict(for:word)),"-","-",KeyMap.convert(word,to:.ru),KeyMap.convert(word,to:.en)].joined(separator:"\t"))
}
