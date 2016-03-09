ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "rack/test"
require "redcarpet"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app 
    Sinatra::Application
  end
  #Test başlaamdan önce harekete geçiyor
  def setup
    FileUtils.mkdir_p(data_path)
  end
  #Test bittikten sonra verileri yok ediyor.
  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end



  def test_index
    create_document("about.md")
    create_document("history.txt")

    get "/"
    assert_equal 200, last_response.status
    assert_includes(last_response.body,"about.md")
    assert_includes(last_response.body,"history.txt")
  end


  def test_request
    create_document("history.txt","I am a lucky man")
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes(last_response.body, "man")
  end

  def test_viewing_markdown_document
    create_document("about.md","I am a 19 year old girl")
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>I am a </h1>"
  end

  def test_not_found
    
    get "/notify.txt"
    assert_equal 302, last_response.status
    assert_equal "notify.txt does not exist.", session[:message]

  end

  def test_editing_documents
    create_document("history.txt","I am a lucky bastard")
    get "/history.txt/edit"
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end
end