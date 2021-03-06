require 'test_helper'
require 'rails/performance_test_help'

class EditorTest < ActionDispatch::PerformanceTest

  def test_create_blank_doc

    ###################
    # [370] (Baseline)

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", { 'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # new document
    https!(false)
    get_via_redirect "/documents/create/1"
    assert (path =~ /documents\/\d+\/edit/)

  end

  def test_create_large_doc

    ###################
    # 1.5, 1.45, 1.37, 1.55, 1.61, 1.59, 1.7 - 1.53 (Baseline)
    # 1.27, 1.22 - 1.25 (line_id into document.id during preorder save)
    # 1.12, 1.14, 1.22 - 1.15 (combining preorder save and update_line queries into two transactions)
    # 1.05, 1.12, 1.02 -1.06 [2.47] (further combination of line/document transactions)
    # 1.02, 1.03 - [2.46] (only updating when changed)
    # 963, 959 [2.39, 2.35] (stripped two queries from update)

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", { 'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # new document
    https!(false)
    get_via_redirect "/documents/create/1"
    assert (path =~ /documents\/\d+\/edit/)
    document_id = path.scan(/documents\/(\d+)\/edit/)[0][0]

    # initial update document
    html = ''
    (1...80).to_a.each do |i|
      html += '<p id="node_%i" line_id="" changed="" class="outline_node" parent="node_0">%i</p>' % [i, i]
    end
    put 'documents/%i' % document_id, {:name => 'yo', :html => html, :new_nodes => 'true'}
    assert_response :success

  end

  def test_augment_large_doc

    ###################
    # 3.16, 3.19 (baseline)
    # 1.42, 1.45, 1.45 (update_line from O(n) -> O(n^2)) - something funky here
    # 1.43, 1.41, 1.37, 1.48, 1.54 - 1.44 (line_id into document.id during preorder save)
    # 1.33, 1.33, 1.36 - 1.34 (combing preorder save and update_line queries into two transactions)
    # 1.17, 1.18, 1.15 - 1.17 [3.05] (further combination of line/document transactions)
    # 1.11, 1.11 [2.85] (only updating when changed)
    # 1.07, 1.03 [2.79, 2.68] (stripped two queries from update)

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", { 'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # new document
    https!(false)
    get_via_redirect "/documents/create/1"
    assert (path =~ /documents\/\d+\/edit/)
    document_id = path.scan(/documents\/(\d+)\/edit/)[0][0]

    # initial update document
    html = ''
    (1...80).to_a.each do |i|
      html += '<p id="node_%i" line_id="" changed="" class="outline_node" parent="node_0">%i</p>' % [i, i]
    end
    put 'documents/%i' % document_id, {:name => 'yo', :html => html, :new_nodes => 'true'}
    assert_response :success

    #augment
    html = Document.find(document_id).html + '<p id="node_81" line_id="" changed="" class="outline_node" parent="node_0">81</p>'
    put 'documents/%i' % document_id, {:name => 'yo', :html => html, :new_nodes => 'true'}
    assert_response :success

  end

end
