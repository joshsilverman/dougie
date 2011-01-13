require 'test_helper'
require 'rails/performance_test_help'

class EditorTest < ActionDispatch::PerformanceTest

  def test_create_large_doc

    ###################
    # (1) 1.5, 1.45, 1.37, 1.55, 1.61, 1.59

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", {'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # new document
    https!(false)
    get_via_redirect "/documents/create/1"
    assert (path =~ /editor\/\d+/)
    document_id = path.scan(/editor\/(\d+)/)[0][0]

    # initial update document
    html = ''
    (1...80).to_a.each do |i|
      html += '<p id="node_%i" line_id="" changed="1294800081564" class="outline_node" parent="node_0">%i</p>' % [i, i]
    end
    post 'documents/update', {:name => 'yo', :id => document_id, :html => html}

  end

  def test_augment_large_doc

    ###################
    # (1) 3.16, 3.19
    # (2) 1.42, 1.45, 1.45

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", {'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # new document
    https!(false)
    get_via_redirect "/documents/create/1"
    assert (path =~ /editor\/\d+/)
    document_id = path.scan(/editor\/(\d+)/)[0][0]

    # initial update document
    html = ''
    (1...80).to_a.each do |i|
      html += '<p id="node_%i" line_id="" changed="1294800081564" class="outline_node" parent="node_0">%i</p>' % [i, i]
    end
    post 'documents/update', {:name => 'yo', :id => document_id, :html => html}

    #augment
    html = Document.find(document_id).html + '<p id="node_81" line_id="" changed="1294800081564" class="outline_node" parent="node_0">81</p>'
    post 'documents/update', {:name => 'yo', :id => document_id, :html => html}

  end

end
