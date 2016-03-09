require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"

configure do 
  enable :sessions
  set :session_secret, 'secret'
end







helpers do 
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end


  def load_file(path)
    content = File.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
    erb  render_markdown(content)
    end
  end

  def puts_yeah
    "yeah"
  end
end

#to create the path for  new files etc
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end


def sign_in?
  if session[:username]
    true
  else
    false
  end
end

def check_sign_in
  if sign_in?
    return
  else
    session[:message] = "You must be signed in to do that"
    redirect "/"
  end
end



def load_user_credentials
  credential_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end

  YAML.load_file(credential_path)
end


root = File.expand_path("..", __FILE__)


get "/" do 
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  puts @files.size
  erb :index, layout: :layout
end

get "/:file_name" do
   file_path = File.join(data_path, params[:file_name])

  if File.exist?(file_path)
    load_file(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
    
    
end








get "/:file_name/edit" do 
  check_sign_in
  file_path = File.join(data_path, params[:file_name])
  @filename = params[:file_name]
 
  @content = File.read(file_path)
  erb :edit_file, layout: :layout
end

#Dispaly the form for creating a new document
get "/new/document" do 
  check_sign_in
  erb :new_file
end


#Display the sign in form

get "/users/signin" do 
  erb :signin, layout: :layout
end







post "/:file_name" do
  check_sign_in
  file_path = File.join(data_path, params[:file_name])
  #edit_file daki textarea nın ismi "content" idi. Onu burada gelen data olarak kullanabiliyok.  
  File.write(file_path,params[:content])
  session[:message] = "#{params[:filename]} is updated."
  redirect "/"
end


#Creating a form o create  a new document
post "/new/create" do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new_file

  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

#Deletes the  document
post "/:filename/delete" do 
  check_sign_in
  file_name = params[:filename].to_s
  file_path = File.join(data_path,file_name)
  File.delete(file_path)
  session[:message] = "#{file_name} has been deleted"
  redirect "/"
end

post "/users/signin" do 
  credentials = load_user_credentials
  username = params[:firstname].to_s
  password = params[:password].to_s
  if credentials.key?(username)  && credentials[:username] == password
    
    session[:username] = username
    session[:message] = "Welcome!!!"
    redirect "/"
  else 
    session[:message] = "Invalid Credentials!!!"
    status 422
    erb :signin, layout: :layout
  end
end


post "/users/signout" do 
  session.delete(:username)
  session[:message] = "You have signed out"
  redirect "/"
end


  
  







