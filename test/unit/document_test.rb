require 'test_helper'

class DocumentTest < ActiveSupport::TestCase

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

  end

  # Replace this with your real tests.
  test "setup" do

    lines = Line.find_all_by_document_id(@document.id)
    root_id = Line.where(:domid => 'node_0', :document_id => @document.id).first.id
    assert(lines.length == 7)
    assert(@document.html == %Q[<body id="node_0"><p id="node_2" line_id="#{root_id+1}" changed="1" class="outline_node" parent="node_0">a</p><p line_id="#{root_id+2}" changed="1" class="outline_node" id="node_3" parent="node_0">b</p><p line_id="#{root_id+3}" changed="1" class="outline_node" id="node_4" parent="node_0">c</p><ul changed="1"><li line_id="#{root_id+4}" changed="1" class="outline_node" id="node_5" parent="node_0">1<ul><li line_id="#{root_id+5}" changed="1" class="outline_node" id="node_6" parent="node_5">2<ul><li line_id="#{root_id+6}" changed="1" class="outline_node" id="node_7" parent="node_6">3</li></ul></li></ul></li></ul></body>])
  end
end
