require 'yaml'

persons = YAML.load_file("data/users.yaml")

p persons[:jamy]
# {:jamy=>{:email=>"jamy.rustenburg@gmail.com", :interests=>["woodworking", "cooking", "reading"]},
#  :nora=>{:email=>"nora.alnes@yahoo.com", :interests=>["cycling", "basketball", "economics"]},
#   :hiroko=>{:email=>"hiroko.ohara@hotmail.com", :interests=>["politics", "history", "birding"]}}


#drucke alle users aus

def to_str(person_hash)
  #User : User
  #Email : email, 
  #Interessen : - politis
  #            : - history
  #User2 ..

  #inner_properties = {:email => String, :interests => [Array]}
  person_hash.each do |name, inner_propertys|
    puts "Person: #{name.capitalize}"
      inner_propertys.each do |key, value|
        if value.is_a? Array
          puts "#{key.capitalize}:"
          value.each{ |v| puts "         -#{v}" }
        else
          puts "#{key.capitalize}: #{value}"
        end
      end  
    puts "---------------"
  end
  
end

def total_interests_and_persons(person_hash)
  puts "#{person_hash.keys.count} Persons"
  p person_hash.values
  nr = person_hash.values.reduce(0) do |sum, n|
    sum + n[:interests].count 
    end

  p nr
end

to_str(persons)

total_interests_and_persons(persons)