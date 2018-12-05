#!/usr/local/bin/run_ruby_script_in_rvm

#====================================================================
module Rnd
  
  RND_OBJECT = Random.new
  HEX_CHARS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
               'A', 'B', 'C', 'D', 'E', 'F']
  
  #------------------------------------------------------------------
  def Rnd.get(arr, count = 1)
    if arr.empty? then
      return ""
    end
    
    if count <= 0 then
      return ""
    end
    
    txt = ""
    
    1.upto count do
      index = RND_OBJECT.rand(0..(arr.length - 1))
      txt << arr[index]
    end
    
    return txt
  end
  
  #------------------------------------------------------------------
  def Rnd.get_hex(count = 1)
    return get(HEX_CHARS, count)
  end
  
end

#====================================================================
# Some tests...
#puts Rnd.get_hex
#puts Rnd.get_hex(1)
#puts Rnd.get_hex(5)
#puts Rnd.get_hex(13)

# Will cause error...
#puts Rnd.HEX_CHARS
