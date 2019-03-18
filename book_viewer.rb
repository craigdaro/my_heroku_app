require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'
require 'yaml'

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    para_begin = "<p>"
    para_end = "</p>"
    text.split("\n\n").map.with_index{|string, index|
      "<p id='#{index}'>#{string}</p>"
  }.join
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

  
end

not_found do
  redirect "/"
end


get "/" do
  @title = "My Adventures"
  erb :home, layout: :layout_book         #Methode
end

get "/persons" do
  @person_data = load_yaml_file("data/users.yaml")
  erb :persons
end

get "/show/:name" do
  params
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


get "/directory" do
          @title = "Public Directory"
    @dirs = Dir.glob("*").map { |file| File.basename(file) }.sort
    @dirs.reverse! if params[:sort] == "desc"
      erb :directory
end
