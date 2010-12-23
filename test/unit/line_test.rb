require 'test_helper'
require 'document'

class LineTest < ActiveSupport::TestCase

  test "simple save" do

    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[<body><p changed="1" id="1" line_id="" active="true">a This is a test - think<br></p><ul><li changed="1" id="2" line_id="" active="true">a the letter 'a' i am using<ul><li changed="1" id="3" line_id="" active="true">a just to keep track</li><li changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li><li changed="1" id="5" line_id="" active="false">a run through</li></ul></li><li changed="1" id="6" line_id="" active="true">a where as items that begin with</li></ul></body>]

    #save
    document = Document.find_or_create_by_name(name)
    dp = DocumentsHelper::DocumentParser.new(document,html)
    Line.preorder_save(dp.doc.children, dp.root, document.id)

    #get recently saved
    document = Document.find_by_name(name)
    lines_tree = Line.find(:first,
                          :include => { :children => { :children => { :children => { :children => :children }}}},
                          :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document.id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document.id})

    #cardinality assertions
    assert_equal(7, lines.size)
    assert_equal(3, lines_tree.children.size)
    assert_equal(3, lines_tree.children[1].children.size)

    #order assertions
    assert_equal('root', lines_tree.text)
    assert_equal('a This is a test - think', lines_tree.children[0].text)
    assert_equal('a just to keep track', lines_tree.children[1].children[0].text)
  end
end
