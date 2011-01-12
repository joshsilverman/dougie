require 'test_helper'
require 'rails/performance_test_help'

class EditorTest < ActionDispatch::PerformanceTest

#  def test_create_39_nodes
#
#    # login via https
#    https!
#    get "/users/sign_out"
#    get "/users/sign_in"
#    assert_response :success
#    post_via_redirect "/users/sign_in", {'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
#    assert_equal '/', path
#
#    # new document
#    https!(false)
#    get_via_redirect "/documents/create/1"
#    assert (path =~ /editor\/\d+/)
#    document_id = path.scan(/editor\/(\d+)/)[0][0]
#
#    # initial update document
#    post 'documents/update', {:name => 'yo', :id => document_id, :html => '<p id="node_2" line_id="" changed="1294800081437" class="outline_node" parent="node_0">2</p><p id="node_3" line_id="" changed="1294800081440" class="outline_node" parent="node_0">3</p><p id="node_4" line_id="" changed="1294800081442" class="outline_node" parent="node_0">4</p><p id="node_5" line_id="" changed="1294800081445" class="outline_node" parent="node_0">5</p><p id="node_6" line_id="" changed="1294800081447" class="outline_node" parent="node_0">6</p><p id="node_7" line_id="" changed="1294800081450" class="outline_node" parent="node_0">7</p><p id="node_8" line_id="" changed="1294800081452" class="outline_node" parent="node_0">8</p><p id="node_9" line_id="" changed="1294800081455" class="outline_node" parent="node_0">9</p><p id="node_10" line_id="" changed="1294800081462" class="outline_node" parent="node_0">10</p><p id="node_11" line_id="" changed="1294800081466" class="outline_node" parent="node_0">11</p><p id="node_12" line_id="" changed="1294800081469" class="outline_node" parent="node_0">12</p><p id="node_13" line_id="" changed="1294800081471" class="outline_node" parent="node_0">13</p><p id="node_14" line_id="" changed="1294800081474" class="outline_node" parent="node_0">14</p><p id="node_15" line_id="" changed="1294800081476" class="outline_node" parent="node_0">15</p><p id="node_16" line_id="" changed="1294800081480" class="outline_node" parent="node_0">16</p><p id="node_17" line_id="" changed="1294800081483" class="outline_node" parent="node_0">17</p><p id="node_18" line_id="" changed="1294800081490" class="outline_node" parent="node_0">18</p><p id="node_19" line_id="" changed="1294800081494" class="outline_node" parent="node_0">19</p><p id="node_20" line_id="" changed="1294800081497" class="outline_node" parent="node_0">20</p><p id="node_21" line_id="" changed="1294800081499" class="outline_node" parent="node_0">21</p><p id="node_22" line_id="" changed="1294800081502" class="outline_node" parent="node_0">22</p><p id="node_23" line_id="" changed="1294800081504" class="outline_node" parent="node_0">23</p><p id="node_24" line_id="" changed="1294800081508" class="outline_node" parent="node_0">24</p><p id="node_25" line_id="" changed="1294800081511" class="outline_node" parent="node_0">25</p><p id="node_26" line_id="" changed="1294800081513" class="outline_node" parent="node_0">26</p><p id="node_27" line_id="" changed="1294800081517" class="outline_node" parent="node_0">27</p><p id="node_28" line_id="" changed="1294800081520" class="outline_node" parent="node_0">28</p><p id="node_29" line_id="" changed="1294800081522" class="outline_node" parent="node_0">29</p><p id="node_30" line_id="" changed="1294800081530" class="outline_node" parent="node_0">30</p><p id="node_31" line_id="" changed="1294800081533" class="outline_node" parent="node_0">31</p><p id="node_32" line_id="" changed="1294800081536" class="outline_node" parent="node_0">32</p><p id="node_33" line_id="" changed="1294800081539" class="outline_node" parent="node_0">33</p><p id="node_34" line_id="" changed="1294800081542" class="outline_node" parent="node_0">34</p><p id="node_35" line_id="" changed="1294800081545" class="outline_node" parent="node_0">35</p><p id="node_36" line_id="" changed="1294800081548" class="outline_node" parent="node_0">36</p><p id="node_37" line_id="" changed="1294800081551" class="outline_node" parent="node_0">37</p><p id="node_38" line_id="" changed="1294800081559" class="outline_node" parent="node_0">38</p><p id="node_39" line_id="" changed="1294800081561" class="outline_node" parent="node_0">39</p><p id="node_40" line_id="" changed="1294800081564" class="outline_node" parent="node_0">40</p>'}
#
#    # temp
##   puts Document.find(document_id).to_yaml
##    yaml = File.new('temp.txt', 'w')
##    yaml.write(Line.find_all_by_document_id(document_id[0][0]).to_yaml)
#  end

  def test_augment_large_doc

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", {'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # update document
    post 'documents/update', {:name => 'yo', :id => 980190964, :html => '<p id="node_2" line_id="122" changed="1294800081437" class="outline_node" parent="node_0">2</p><p id="node_3" line_id="123" changed="1294800081440" class="outline_node" parent="node_0">3</p><p id="node_4" line_id="124" changed="1294800081442" class="outline_node" parent="node_0">4</p><p id="node_5" line_id="125" changed="1294800081445" class="outline_node" parent="node_0">5</p><p id="node_6" line_id="126" changed="1294800081447" class="outline_node" parent="node_0">6</p><p id="node_7" line_id="127" changed="1294800081450" class="outline_node" parent="node_0">7</p><p id="node_8" line_id="128" changed="1294800081452" class="outline_node" parent="node_0">8</p><p id="node_9" line_id="129" changed="1294800081455" class="outline_node" parent="node_0">9</p><p id="node_10" line_id="130" changed="1294800081462" class="outline_node" parent="node_0">10</p><p id="node_11" line_id="131" changed="1294800081466" class="outline_node" parent="node_0">11</p><p id="node_12" line_id="132" changed="1294800081469" class="outline_node" parent="node_0">12</p><p id="node_13" line_id="133" changed="1294800081471" class="outline_node" parent="node_0">13</p><p id="node_14" line_id="134" changed="1294800081474" class="outline_node" parent="node_0">14</p><p id="node_15" line_id="135" changed="1294800081476" class="outline_node" parent="node_0">15</p><p id="node_16" line_id="136" changed="1294800081480" class="outline_node" parent="node_0">16</p><p id="node_17" line_id="137" changed="1294800081483" class="outline_node" parent="node_0">17</p><p id="node_18" line_id="138" changed="1294800081490" class="outline_node" parent="node_0">18</p><p id="node_19" line_id="139" changed="1294800081494" class="outline_node" parent="node_0">19</p><p id="node_20" line_id="140" changed="1294800081497" class="outline_node" parent="node_0">20</p><p id="node_21" line_id="141" changed="1294800081499" class="outline_node" parent="node_0">21</p><p id="node_22" line_id="142" changed="1294800081502" class="outline_node" parent="node_0">22</p><p id="node_23" line_id="143" changed="1294800081504" class="outline_node" parent="node_0">23</p><p id="node_24" line_id="144" changed="1294800081508" class="outline_node" parent="node_0">24</p><p id="node_25" line_id="145" changed="1294800081511" class="outline_node" parent="node_0">25</p><p id="node_26" line_id="146" changed="1294800081513" class="outline_node" parent="node_0">26</p><p id="node_27" line_id="147" changed="1294800081517" class="outline_node" parent="node_0">27</p><p id="node_28" line_id="148" changed="1294800081520" class="outline_node" parent="node_0">28</p><p id="node_29" line_id="149" changed="1294800081522" class="outline_node" parent="node_0">29</p><p id="node_30" line_id="150" changed="1294800081530" class="outline_node" parent="node_0">30</p><p id="node_31" line_id="151" changed="1294800081533" class="outline_node" parent="node_0">31</p><p id="node_32" line_id="152" changed="1294800081536" class="outline_node" parent="node_0">32</p><p id="node_33" line_id="153" changed="1294800081539" class="outline_node" parent="node_0">33</p><p id="node_34" line_id="154" changed="1294800081542" class="outline_node" parent="node_0">34</p><p id="node_35" line_id="155" changed="1294800081545" class="outline_node" parent="node_0">35</p><p id="node_36" line_id="156" changed="1294800081548" class="outline_node" parent="node_0">36</p><p id="node_37" line_id="157" changed="1294800081551" class="outline_node" parent="node_0">37</p><p id="node_38" line_id="158" changed="1294800081559" class="outline_node" parent="node_0">38</p><p id="node_39" line_id="159" changed="1294800081561" class="outline_node" parent="node_0">39</p><p id="node_40" line_id="160" changed="1294800081564" class="outline_node" parent="node_0">40</p>'}
    
  end

end
