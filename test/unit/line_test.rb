require 'test_helper'
require 'document'

class LineTest < ActiveSupport::TestCase

  def test_save

    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="1" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="1" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="1" id="3" line_id="" active="true">a just to keep track</li>
                      <li changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="1" id="5" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="1" id="6" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :document_id => document.id)
    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc.children, root, document.id)

    #get recently saved
    document = Document.find_by_name(name)
    lines_all = Line.find(:all)
    lines_tree = Line.find(:first,
                          :include => { :children => { :children => { :children => { :children => :children }}}},
                          :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document.id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document.id})

    #cardinality assertions
    assert_equal(7, lines_all.size)
    assert_equal(7, lines.size)
    assert_equal(3, lines_tree.children.size)
    assert_equal(3, lines_tree.children[1].children.size)

    #order assertions
    assert_equal('root', lines_tree.text)
    assert_equal('a This is a test - think', lines_tree.children[0].text)
    assert_equal('a just to keep track', lines_tree.children[1].children[0].text)
  end

  def test_update

    #setup
    require 'documents_helper'
    name = 'new document'
    html = []
    document = []
    html[0] = %q[
                <body>

                <p changed="1" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="1" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="1" id="3" line_id="" active="true">a just to keep track</li>
                      <li changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="1" id="5" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="1" id="6" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            #]

    #save [0] initial database state
    root = []
    document[0] = Document.find_or_create_by_name(name)
    root[0] = Line.find_or_create_by_document_id(document.id)
    dp = DocumentsHelper::DocumentParser.new(html[0])
    Line.preorder_save(dp.doc.children, root[0], document[0].id)

    #get saved [1]
    document[1] = Document.find_by_name(name)
    existing_lines = document[1].lines

    #note: tables are not truncated between tests. therefore, line_ids must be
    #      set dynamically to assure that they correspond with existing lines

    line_id = Line.first.id
    html[1] = %Q[
                <body>

                  <p changed="1" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="1" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="90273598237590879082372" id="3" line_id="#{line_id+3}" active="true">a just to keep track [EDIT]</li>
                        <li changed="1" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                        <li changed="1" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="1" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>

                  </ul>

                </body>
              ]

    #save [1]
    document[1].update_attribute(:html,html[1])
    root[1] = Line.find_or_create_by_document_id(document.id)
    dp = DocumentsHelper::DocumentParser.new(html[1])
    Line.update_line(dp.doc.children,existing_lines)

    #get saved [1]
    lines_all = Line.find(:all)
    lines_tree = Line.find(:first,
                          :include => { :children => { :children => { :children => { :children => :children }}}},
                          :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document[1].id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document[1].id})

    #assertions
    assert_equal(7, lines_all.size)
    assert_equal("a just to keep track [EDIT]", lines_all[3].text)
  end

  def test_augment

    #setup
    require 'documents_helper'
    name = 'new document'
    html = []
    document = []
    html[0] = %q[
                <body>

                <p changed="1" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="1" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="1" id="3" line_id="" active="true">a just to keep track</li>
                      <li changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="1" id="5" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="1" id="6" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            #]

    #save [0] initial database state
    root = []
    document[0] = Document.find_or_create_by_name(name)
    root[0] = Line.find_or_create_by_document_id(document.id)
    dp = DocumentsHelper::DocumentParser.new(html[0])
    Line.preorder_save(dp.doc.children, root[0], document[0].id)

    #get saved [1]
    document[1] = Document.find_by_name(name)
    existing_lines = document[1].lines

    #note: tables are not truncated between tests. therefore, line_ids must be
    #      set dynamically to assure that they correspond with existing lines

    line_id = Line.first.id
    html[1] = %Q[
                <body>

                  <p changed="1" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="1" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="90273598237590879082372" id="3" line_id="#{line_id+3}" active="true">a just to keep track [EDIT]</li>
                        <li changed="1" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                        <li changed="1" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                        <li changed="90273598237590879082372" id="7" line_id="" active="false">b I'm a new node. I love you</li>
                      </ul>
                    </li>

                    <li changed="1" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>

                  </ul>

                </body>
              ]

    #save [1]
    document[1].update_attribute(:html,html[1])
    root[1] = Line.find_or_create_by_document_id(document.id)
    dp = DocumentsHelper::DocumentParser.new(html[1])
    Line.preorder_augment(dp.doc.children, root[1], existing_lines, document[1].id)

    #get saved [1]
    lines_all = Line.find(:all)
    lines_tree = Line.find(:first,
                          :include => { :children => { :children => { :children => { :children => :children }}}},
                          :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document[1].id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document[1].id})

    #assertions
    assert_equal(8, lines_all.size)
    assert_equal(lines_all[2].id, lines_all[7].parent_id)

  end

  def test_depth_4

    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="1" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="1" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="1" id="3" line_id="" active="true">a just to keep track</li>
                      <li changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li>

                      <li changed="1" id="5" line_id="" active="false">a run through
                        <ul>
                          <li changed="1" id="6" line_id="" active="true">deep a</li>
                          <li changed="1" id="7" line_id="" active="false">deep b</li>
                          <li changed="1" id="8" line_id="" active="false">deep c</li>
                        </ul>
                      </li>

                    </ul>
                  </li>

                  <li changed="1" id="9" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :document_id => document.id)
    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc.children, root, document.id)

    #get recently saved
    document = Document.find_by_name(name)
    lines_all = Line.find(:all)
    lines_tree = Line.find(:first,
                          :include => { :children => { :children => { :children => { :children => :children }}}},
                          :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document.id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document.id})

    #cardinality assertions
    assert_equal(10, lines_all.size)
    assert_equal(10, lines.size)
    assert_equal(3, lines_tree.children.size)
    assert_equal(3, lines_tree.children[1].children.size)
    assert_equal(3, lines_tree.children[1].children[2].children.size)

    #order assertions
    assert_equal('root', lines_tree.text)
    assert_equal('a This is a test - think', lines_tree.children[0].text)
    assert_equal('a just to keep track', lines_tree.children[1].children[0].text)
    assert_equal('deep c', lines_tree.children[1].children[2].children[2].text)
  end
end
