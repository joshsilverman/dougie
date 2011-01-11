require 'test_helper'
require 'rails/performance_test_help'

class EditorTest < ActionDispatch::PerformanceTest

#  include Devise::TestHelpers

  def test_create

    @user = users(:one)
    sign_in @user
##    sign_in :one, @user
#
#    get 'documents/new/1'
  end

#  def test_create
#
#    post 'documents/new/1', :post => {html => '<p id="node_2" line_id="" changed="1294698122027" class="outline_node" parent="node_0">1</p><p line_id="" changed="1294698122027" class="outline_node" parent="node_0" id="node_3">2</p><p line_id="" changed="1294698122027" class="outline_node" parent="node_0" id="node_4">3</p><p line_id="" changed="1294698122028" class="outline_node" parent="node_0" id="node_5">4</p><p line_id="" changed="1294698122028" class="outline_node" parent="node_0" id="node_6">5</p><p line_id="" changed="1294698122028" class="outline_node" parent="node_0" id="node_7">6</p><p line_id="" changed="1294698122028" class="outline_node" parent="node_0" id="node_8">7</p><p line_id="" changed="1294698122029" class="outline_node" parent="node_0" id="node_9">8</p><p line_id="" changed="1294698122029" class="outline_node" parent="node_0" id="node_10">9</p><p line_id="" changed="1294698122029" class="outline_node" parent="node_0" id="node_11">0</p>',
#                                      id => 153,
#                                      name => 'untitled'}
#  end

end
