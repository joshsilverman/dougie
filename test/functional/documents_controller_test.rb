require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase

  def setup

    @user_id = 751654198

    # set requests
    @requests = {:basic_outline => {
                 :html => '<body id="node_0"><p id="node_2" line_id="" changed="1" class="outline_node" parent="node_0">a</p><p line_id="" changed="1" class="outline_node" id="node_3" parent="node_0">b</p><p line_id="" changed="1" class="outline_node" id="node_4" parent="node_0">c</p><ul changed="1"><li line_id="" changed="1" class="outline_node" id="node_5" parent="node_0">1<ul><li line_id="" changed="1" class="outline_node" id="node_6" parent="node_5">2<ul><li line_id="" changed="1" class="outline_node" id="node_7" parent="node_6">3</li></ul></li></ul></li></ul></body>',
                 :name => 'untitled',
                 :delete_nodes => nil,
                 :new_nodes => 'true'}
               }

    # create/update default outline
    @document = Document.create(:user_id => @user_id)

    # add document id to params
    params = @requests[:basic_outline]
    params[:id] = @document.id

    @document = Document.update(params, @user_id)

    # get highest node id
    node_ids = @requests[:basic_outline][:html].scan(/id="node_(\d+)"/)
    @max_node_id =  node_ids.max[0].to_i

  end

  test "add node, update node, delete node" do

    # set requests
    @add_node_request = {
       :html => nil,
       :name => 'untitled',
       :delete_nodes => nil,
       :new_nodes => 'true'}

    @add_node_request[:html] = add_node(@document.html)
    @document = Document.update(@add_node_request, @user_id)
    lines = Line.find_all_by_document_id(@document.id)

    puts lines.length
    assert(lines.length == 8)
  end

  def add_node(html)

    @max_node_id += 1
    new_node = "<p id=\"%i\" line_id=\"\" changed=\"1\" class=\"outline_node\" parent=\"node_0\">new!</p>" % @max_node_id

    html.gsub!('</body>', new_node + '</body>')
    return html
  end
  
end
