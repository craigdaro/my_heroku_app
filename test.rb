list = {
  :name => "hai",
  :todos => [
              {completed: true, :name => "Aufräumen"}, 
              {completed: false, :name => "Zähneputzen"},
              {completed: true, :name => "Putzen"}
              
            ]
        
}

p list[:todos].count { |hash| !hash[:completed] }


p list[:todos].sort_by{ |hash| hash[:name]}

p list