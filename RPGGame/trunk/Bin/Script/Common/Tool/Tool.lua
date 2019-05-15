local PrintTabKey = ""
function PrintTable(table , level)
    level = level or 1
    local indent = ""
    for i = 1, level do
      indent = indent.."  "
    end
  
    if PrintTabKey ~= "" then
      print(indent..PrintTabKey.." ".."=".." ".."{")
    else
      print(indent .. "{")
    end
  
    PrintTabKey = ""
    for k,v in pairs(table) do
       if type(v) == "table" then
        PrintTabKey = k
          PrintTable(v, level + 1)
       else
          local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
        print(content)  
        end
    end
    print(indent .. "}\n")
  end