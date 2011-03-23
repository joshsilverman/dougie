require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup

    sign_in users(:one)
    @user_id = 1

    # set requests
    @requests = {:basic_outline => {
                 :html => '<body id="node_0"><p id="node_2" line_id="" changed="1" class="outline_node" parent="node_0">a</p><p line_id="" changed="1" class="outline_node" id="node_3" parent="node_0">b</p><p line_id="" changed="1" class="outline_node" id="node_4" parent="node_0">c</p><ul changed="1"><li line_id="" changed="1" class="outline_node" id="node_5" parent="node_0">1<ul><li line_id="" changed="1" class="outline_node" id="node_6" parent="node_5">2<ul><li line_id="" changed="1" class="outline_node" id="node_7" parent="node_6">3</li></ul></li></ul></li></ul></body>',
                 :name => 'untitled',
                 :delete_nodes => nil,
                 :new_nodes => 'true'}
               }

    # create/update default outline
    @document = Document.create(:user_id => @user_id, :name => 'untitled')

    # add document id to params
    params = @requests[:basic_outline]
    params[:id] = @document.id

    @document = Document.update(params, @user_id)

    # get highest node id
    node_ids = @requests[:basic_outline][:html].scan(/id="node_(\d+)"/)
    @max_node_id =  node_ids.max[0].to_i

  end

  test "simple" do

    # login via https
    sign_in users(:one)

    # new document
    document = Document.create(:user_id => 1, :name => 'untitled')

    request = {
      :delete_nodes=>",,,30950,30951,30952,30953,30954",
      :name=>"untitled",
      :html=>'<body line_id=\"30640\" id=\"node_0\"><p id="node_2" line_id="" changed="1" class="outline_node" parent="node_0">a</p></body>',
      :id=>document.id,
      :new_nodes=>"true"
    }

    Document.update(request, 1)
    lines = Line.find_all_by_document_id(document.id)
    assert(lines.length == 2)

  end

  test "add node, update node, delete node" do

    # set requests
    @add_node_request = {
       :id => @document.id,
       :html => nil,
       :name => 'untitled',
       :delete_nodes => nil,
       :new_nodes => 'true'}

    @add_node_request[:html] = add_node(@document.html)
    @document = Document.update(@add_node_request, @user_id)
    lines = Line.find_all_by_document_id(@document.id)

    assert(lines.length == 8)
  end

  def add_node(html)

    @max_node_id += 1
    new_node = "<p id=\"%i\" line_id=\"\" changed=\"1\" class=\"outline_node\" parent=\"node_0\">new!</p>" % @max_node_id

    html.gsub!('</body>', new_node + '</body>')
    return html
  end

  test "new IE doc" do

    # create/update default outline
    document = Document.create(:user_id => @user_id, :name => 'untitled')

    # set requests
    request = {
       :id => document.id,
#       :html => "<UL>\r\n<LI id=node_2 class=outline_node line_id changed=\"0\" active=\"true\" parent=\"node_0\">hello - adsf</LI>\r\n<LI id=node_3 class=outline_node line_id changed=\"0\" active=\"true\" parent=\"node_0\">sdfsdf - adfsdfd</LI>\r\n<LI id=node_4 class=outline_node line_id changed=\"0\" parent=\"node_0\">sdfgsdfgsdfgsdfg</LI>\r\n<LI id=node_5 class=outline_node line_id changed=\"0\" parent=\"node_0\">sdfgsdfg</LI>\r\n<LI id=node_6 class=outline_node line_id changed=\"1\" active=\"true\" parent=\"node_0\">zxcv - asdf</LI>\r\n<LI id=node_7 class=outline_node line_id changed=\"1\" active=\"true\" parent=\"node_0\">asdf - asdf</LI></UL>",
       :html => "<BODY id=node_0 line_id=\"413\">\r\n<UL>\r\n<LI id=node_16 class=outline_node line_id changed=\"1\" parent=\"node_0\" active=\"true\">a</LI>\r\n<LI id=node_17 class=outline_node line_id changed=\"1\" parent=\"node_0\" active=\"true\">b \r\n<UL>\r\n<LI id=node_18 class=outline_node line_id changed=\"1\" active=\"true\" parent=\"node_17\">c - d</LI></UL></LI></UL></BODY>",
       :name => 'untitled',
       :delete_nodes => nil,
       :new_nodes => 'true'}

    document = Document.update(request, @user_id)
    lines = Line.find_all_by_document_id(document.id)

    assert(lines.length == 4)
  end

  test "error" do

    # login
    sign_in users(:one)

    # new document
    document = Document.create(:user_id => 1, :name => 'untitled')

    request = {
      :delete_nodes=>"",
      :name=>"untitled",
      :html=>"<body line_id=\"30640\" id=\"node_0\"><ul changed=\"1\"><li parent=\"node_0\" class=\"outline_node\" line_id=\"\" changed=\"1\" id=\"node_373\">a<br><ul changed=\"1\"><li parent=\"node_373\" class=\"outline_node\" line_id=\"\" changed=\"0\" id=\"node_470\"><br><ul changed=\"1\"><li parent=\"\" class=\"outline_node\" line_id=\"\" changed=\"0\" id=\"node_471\"><br><ul><li parent=\"\" class=\"outline_node\" line_id=\"\" changed=\"0\" id=\"node_472\"><br><ul changed=\"1\"><li parent=\"\" class=\"outline_node\" line_id=\"\" changed=\"0\" id=\"node_473\"><br><ul><li parent=\"\" class=\"outline_node\" line_id=\"\" changed=\"0\" id=\"node_474\">s</li></ul></li></ul></li></ul></li></ul></li></ul></li></ul></body>",
      :id=>document.id,
      :new_nodes=>"true"
    }

    Document.update(request, 1)
    lines = Line.find_all_by_document_id(document.id)
    assert(lines.length == 7)

  end

end
