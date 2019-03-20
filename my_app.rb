require "sinatra"
require "sinatra/reloader" if development?
require 'tilt/erubis'
require 'yaml'
require 'sinatra/content_for'

# Session Values are now included in the environment variable
configure do
  enable :sessions
  set :sessions_secret, 'secret'
end

#set @contents to fill in the chapters in the side menu
# set session[:lists] to store the Todo-Lists
before do
  @contents = File.readlines("data/toc.txt")
  session[:lists] ||= []
end

helpers do

  def validate_name(list, listname, &block)
    # checks the size of the currently added listname
    if wrong_name_length?(listname)
      session[:failed_list] = "Der Name muss mind 1. Charakter lang sein und weniger als 100"
    elsif  already_exist?(list, block)
      session[:failed_list] = "#{listname} ist schon vorhanden"
    else
      session[:success_list] = "#{listname} wurde erfolgreich erstellt"
    end
  end

  def wrong_name_length?(name)
    !((1..100).cover? name.size)
  end

  def already_exist?(list, block)
    #session[:lists].any? { |list| list[:name] == listname}
    list.any? { |l| block.call(l) }
  end


  def in_paragraphs(text)
    para_begin = "<p>"
    para_end = "</p>"
    text.split("\n\n").map.with_index do |string, index|
      "<p id='#{index}'>#{string}</p>"
    end.join
  end

  def each_chapter

    @contents.each_with_index do |name, index|
      index += 1
      content = File.read("data/chp#{index}.txt")
      yield(name,index, content)
    end
  end

  def chapters_matching(query)
      hash = {}
      return hash.keys if query == ""
      each_chapter do |name, index, content|
        passages = content.split("\n\n")
        passages.each_with_index do |text, id|
          next unless text.include?(query)
          hash[index] = [] unless hash[index]
          hash[index] << {passage: text, id: id, name: name} 
       end
     end
     hash
  end
   
  def mark_word(word)
     "<span class='marked'>#{word} </span>"
  end

  

  def find_search_chapter(query)
    #returns an array consisting of chapters that includes the search request
    arr = []
    @contents.each_with_index do |file, i|
      index = i + 1
      arr << {name: file, index: index} if File.read("data/chp#{index}.txt").include?(query)
    end
    arr
  end

  def load_yaml_file(file)
    YAML.load_file(file)
  end

  ## Manipulating the a list in the all - list view
  ### Count the unfinished items of a list
    # to Display them in the all List View

  def count_unfinnished_tasks(list)
    list[:todos].count { |hash| hash[:completed] }
  end

  ### Are all the tasks of one list finnished
    # if there is one element that is not completed, it will result in false

  def all_tasks_finnished?(list)
    !list[:todos].any?{ |hash| !hash[:completed]} &&
    list[:todos].size > 0
  end

  ### Send list view according to its status of completeness
    # completed list: <li class="complete">; normal : <li></li>


  def generate_view_for_single_list(list)
    inside_info = <<-INSIDE
          <h2>#{list[:name]}</h2>
          <p> #{count_unfinnished_tasks(list)}/#{list[:todos].count}</p>
        INSIDE
      if all_tasks_finnished?(list)     
        code = <<-HEREDOC
        <li class="complete">
          #{inside_info}               
        </li>
        HEREDOC
      else
        code = <<-HEREDOC
        <li>
          #{inside_info}               
        </li>
        HEREDOC
      end
      code
  end

  def sort_todo(list, &block)
    completed_tasks = {}
    incompleted_tasks = {}
    list.each_with_index do |hash,index|
      if hash[:completed]
        completed_tasks[hash] = index
      else
        incompleted_tasks[hash] = index
      end
    end
    incompleted_tasks.each(&block)
    completed_tasks.each(&block)
  end

  

  def sort_lists2(lists, &block)
    ##hashes are ordered
    completed_lists = {}
    incompleted_lists = {}

    lists.each_with_index do |list, index|
      if all_tasks_finnished?(list)
        completed_lists[list] = index
      else
        incompleted_lists[list] = index
      end
    end
    incompleted_lists.each(&block)
    completed_lists.each(&block)
  end

  ##using partition
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| all_tasks_finnished?(list)}
    incomplete_lists.each { |list| yield(list, lists.index(list))}
    complete_lists.each { |list| yield(list, lists.index(list))}
  end
end


not_found do
  redirect "/"
end


get "/" do
  redirect"/todo"
  @title = "My Adventures"
  erb :home, layout: :layout_book         #Methode
end

get "/persons" do
  @person_data = load_yaml_file("data/users.yaml")
  erb :persons
end

get "/show/:name" do
  params[:name]
end


get "/search" do
  @hash_list = chapters_matching(params[:query]) if params[:query]
  erb :search, layout: :layout_book
end

get "/chapters/:chp_nr" do
  @chapter_nr = params[:chp_nr]
  redirect "/" unless (1..@contents.size).cover?(@chapter_nr.to_i)
  @title = "Kapitel #{@chapter_nr}" #das klappt aufjedenfall
  @chapter_title = @contents[(@chapter_nr.to_i) - 1]
  @chapter = File.read("data/chp#{@chapter_nr}.txt")
  @chapter = in_paragraphs(@chapter)
  

  erb :chapter, layout: :layout_book
end

# GET   /todo       -> view all todo lists
# GET   /todo/new   -> add new list to the todo list
# POST  /todo       -> create new list
# GET   /todo/:nr     -> view a single list



#View all the list
# getting lists from the session variable
get "/todo" do
  @lists = session[:lists]
  @added_message = session[:success]
  erb :lists, layout: :todo
end

#Render new todo List form
get "/todo/new" do
  # session[:lists] << {name:"New List", todos:[]}
  # redirect "/todo"
  erb :new_list, layout: :todo
end


#param[:list_name] referenced the value of the attribute
# name="" in the <input> within  new_list.erb
post "/todo" do
  list_name = params[:list_name].strip
  # corresponding call: list.any? { |l| block.call(l) }
  list_proc = Proc.new { |list| list[:name] == list_name }
  validate_name(session[:lists], list_name, &list_proc)
  if session[:success_list]
    session[:lists] << { name: list_name, todos:[]}
    redirect "/todo"
  else
    erb :new_list, layout: :todo
  end  
end


# List of Items for a single list
# route 
# GET   "/todo/:nr"   -> shows group of single items

get "/todo/:nr" do |nr|
  @nr = nr = nr.to_i
  redirect"/todo" if session[:lists][nr].nil?
  @list = session[:lists][nr]
  erb :single_todo, layout: :todo
end

get "/todo/" do
  redirect "/todo"
end

post "/todo/:nr" do |nr|
  @nr = nr = nr.to_i
  @list = session[:lists][nr]
  item_name = params[:item_name].strip
  item_proc = Proc.new{ |item| item[:name] == item_name }
  validate_name(@list[:todos], item_name, &item_proc)
  @list[:todos] << {name: item_name, completed: false} if session[:success_list]
  erb :single_todo, layout: :todo
end


get "/todo/:nr/edit_list_name" do
  id = params[:nr].to_i
  @list = session[:lists][id]
  erb :edit_list_name, layout: :todo
end


# Liste oder Item Liste editieren
post "/todo/:nr/edit_list_name" do |nr|
  id = params[:nr].to_i
  list_name = params[:list_name]
  list_proc = Proc.new { |list| list[:name] == list_name }
  validate_name(session[:lists], list_name, &list_proc)
  session[:lists][id][:name] = list_name
  redirect '/todo/:nr' if session[:success_list]
  @list = session[:lists][id]
  erb :edit_list_name, layout: :todo
end

# Edit an existing todo list
get "/todo/:nr/edit" do
  erb :edit_list, layout: :todo
end

post "/todo/:nr/destroy" do
  session[:lists].delete_at(params[:nr].to_i)
  session[:success_list] = "Liste erforlgreich gelöscht"
  redirect "/todo"
end

post "/todo/:nr/destroy_item/:item_nr" do |nr, item_nr|
  nr = nr.to_i
  item_nr = item_nr.to_i
  @list = session[:lists][nr][:todos].delete_at item_nr
  session[:success_list] = "Item wurde erfolgreich gelöscht"
  redirect "/todo/#{nr}"
end

#Update status of a todo item
post "/todo/:nr/complete_item/:item_nr" do |nr, item_nr|
  nr = nr.to_i
  item_nr = item_nr.to_i
  @list = session[:lists][nr]
  is_completed = params[:completed] == 'true'
  @list[:todos][item_nr][:completed] = is_completed
  if is_completed
    session[:success_list] = "Das todo ist fertig"
  else
    session[:failed_list] = "Das todo ist doch noch nicht fertig"
  end
  redirect "/todo/#{nr}"
end

# Complete all items of a list

post "/todo/:nr/complete_all" do |nr|
  nr = nr.to_i
  @list = session[:lists][nr]
  @list[:todos].each { |hash| hash[:completed] = !hash[:completed]}
  redirect "/todo/#{nr}"
end

get "/directory" do
    @title = "Public Directory"
    @dirs = Dir.glob("*").map { |file| File.basename(file) }.sort
    @dirs.reverse! if params[:sort] == "desc"
    erb :directory
end



