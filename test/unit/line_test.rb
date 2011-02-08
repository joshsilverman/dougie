require 'test_helper'
require 'document'

class LineTest < ActiveSupport::TestCase

  def test_save

    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                      <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 0, :document_id => document.id)
    
    dp = DocumentsHelper::DocumentParser.new(html)
    Line.document_html = html
    Line.preorder_save(dp.doc, document.id, {'node_0' => root}, 1)

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
    assert_equal("a the letter 'a' i am using", lines_tree.children[1].text)
    assert_equal('a just to keep track', lines_tree.children[1].children[0].text)
  end

  def test_update

    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>

                  <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                  </ul>

                </body>
            #]
    
   
      document[0] = Document.create(:name => 'untitled')
      dp = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end

      Line.document_html = html[0]
      Line.preorder_save(dp.doc, document[0].id, {'node_0' => root}, 1)
      document[0].update_attribute(:html, Line.document_html)

      line_id = Line.where("text = 'root'").order("created_at DESC").first.id
      html[1] = %Q[
                      <body>
        
                          <p changed="0" parent="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>
        
                          <ul>
        
                            <li changed="0" parent="0" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                              <ul>
                                <li parent="2" changed="1" id="3" line_id="#{line_id+3}" active="true">a just to keep track [EDIT]</li>
                                <li parent="2" changed="0" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first [FALSE EDIT]</li>
                                <li parent="2" changed="0" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                              </ul>
                            </li>
        
                            <li changed="0" parent="0" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>
        
                          </ul>
        
                        </body>
                      ]
        
      document[1] = Document.find_by_id(document[0].id)
      dp = DocumentsHelper::DocumentParser.new(html[1])
      existing_lines = document[1].lines

      unless document[1].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end 

      document[1].update_attribute(:html,html[1])

      lines = Line.find_all_by_document_id(document[1].id)
      assert_equal(7, lines.length)
      assert_equal("a just to keep track [EDIT]", lines[3].text)
      assert_equal("a of things that are saved on the first", lines[4].text)

  end

  def test_augment

    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>

                  <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                  </ul>

                </body>
            #]
    
   
      document[0] = Document.create(:name => 'untitled')
      dp = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end

      Line.document_html = html[0]
      Line.preorder_save(dp.doc, document[0].id, {'node_0' => root}, 1)
      document[0].update_attribute(:html,Line.document_html)

      lines = Line.find_all_by_document_id(document[0].id)
      assert_equal(7, lines.length)

      #hsh = Line.id_hash(Document.find_by_id(id))

      #render :json => hsh
      
      line_id = Line.where("text = 'root'").order("created_at DESC").first.id
      html[1] = %Q[
                      <body>
        
                          <p changed="0" parent="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>
        
                          <ul>
        
                            <li changed="0" parent="0"  id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                              <ul>
                                <li parent="2" changed="0" id="3" line_id="#{line_id+3}" active="true">a just to keep track</li>
                                <li parent="2" changed="0" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                                <li parent="2" changed="0" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                              </ul>
                            </li>
        
                            <li parent="0" changed="0" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>
                            
                            <li parent="0" changed="0" id="7" line_id="" active="true">PLEASE WORK</li>
        
                          </ul>
        
                        </body>
                      ]
        

      document[1] = Document.find_by_id(document[0].id)
      dp = DocumentsHelper::DocumentParser.new(html[1])
      existing_lines = document[1].lines
      
      unless document[1].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end

      Line.document_html = html[1]
      Line.preorder_save(dp.doc, document[1].id, {'node_0' => root}, 1)
      document[1].update_attribute(:html,Line.document_html)

      lines = Line.find_all_by_document_id(document[0].id)
      assert_equal(8, lines.length)
      assert_equal("a just to keep track", lines[3].text)
      assert_equal("PLEASE WORK", lines[7].text)
      
  end
  
  def test_multiple_levels
    
    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>
                <p parent="0" active="false" class="outline_node" changed="0" line_id="" id="2">
                	node 1<br>
                </p>
                <p parent="0" id="3" active="false" class="outline_node" changed="0" line_id="">
                	node 2<br>
                </p>
                <ul>
                	<li parent="0" id="4" active="false" class="outline_node" changed="0" line_id="">node 3<br>
                	</li>
                	<li parent="0" id="5" active="false" class="outline_node" changed="0" line_id="">node 4<br>
                		</li>
                </ul>
                </body>
            ]
    
   
      document[0] = Document.create(:name => 'untitled')
      dp = []
      dp[0] = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end
      
      Line.document_html = html[0]
      Line.preorder_save(dp[0].doc,document[0].id, {'node_0' => root}, 1)
      document[0].update_attribute(:html,Line.document_html)
      
      assert_equal(5,document[0].lines.length)
      
      ###
      
      line_id = Line.where("text = 'root'").order("created_at DESC").first.id
      html[1] = %Q[
                  
                  <body>
                	<p parent="0" active="false" class="outline_node" changed="0" line_id="#{line_id+1}" id="2">node 1<br></p>
                  <p parent="0" id="3" active="false" class="outline_node" changed="0" line_id="#{line_id+2}">node 2<br>
                  </p>
                  <ul>
                  	<li parent="0" id="4" active="false" class="outline_node" changed="0" line_id="#{line_id+3}">node 3<br>
                  	</li>
                  	<li parent="0" id="5" active="false" class="outline_node" changed="0" line_id="#{line_id+4}">node 4<br>
                  		<ul>
                  			<li id="6" parent="5" active="false" class="outline_node" changed="0" line_id="">node 5<br>
                  			</li>
                  			<li id="7" parent="5" active="false" class="outline_node" changed="0" line_id="">node 6<br>
                  			</li>
                  		</ul>
                  	</li>
                  	<li id="8" parent="0" active="false" class="outline_node" changed="0" line_id="">node 7<br>
                  	</li>
                  </ul>
                  </body>


              ]
      
        document[1] = Document.find_by_id(document[0].id)
        dp[1] = DocumentsHelper::DocumentParser.new(html[1])
        existing_lines = document[1].lines

        unless document[1].html.blank?
          Line.update_line(dp[1].doc,existing_lines,1)
        end

        Line.document_html = html[1]
        Line.preorder_save(dp[1].doc, document[1].id, {'node_0' => root}, 1)
        document[1].update_attribute(:html,Line.document_html)

        lines = Line.find_all_by_document_id(document[0].id)
        assert_equal(8, lines.length)
        assert_equal("node 1",Line.where("domid = 2 AND document_id = ?", document[0].id)[0].text)
        assert_equal("node 3",Line.where("domid = 4 AND document_id = ?", document[0].id)[0].text)
        
        
        assert_equal("node 2",Line.where("domid = 3 AND document_id = ?", document[0].id)[0].text)
    
  end
  
  def test_augment_depth_4

    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>

                <p parent="0" changed="0" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li parent="0" changed="0" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li parent="2" changed="0" id="3" line_id="" active="true">a just to keep track</li>
                      <li parent="2" changed="0" id="4" line_id="" active="false">a of things that are saved on the first</li>
                      <li parent="2" changed="0" id="5" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with
                    <ul>
                      <li parent="6" changed="0" id="7" line_id="" active="true">level 2a</li>
                      <li parent="6" changed="0" id="8" line_id="" active="false">level 2b</li>
                      <li parent="6" changed="0" id="9" line_id="" active="false">level 2c</li>
                      <li parent="6" changed="0" id="10" line_id="" active="false">level 2d</li>
                    </ul>
                  </li>

                </ul>

              </body>
            ]
    
   
      document[0] = Document.create(:name => 'untitled')
      dp = []
      dp[0] = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end
      
      Line.document_html = html[0]
      Line.preorder_save(dp[0].doc,document[0].id, {'node_0' => root}, 1)
      document[0].update_attribute(:html,Line.document_html)
      
      assert_equal(11,document[0].lines.length)
      
      ###
      
      line_id = Line.where("text = 'root'").order("created_at DESC").first.id
      html[1] = %Q[
                  <body>

                  <p parent="0" changed="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>

                  <ul>

                    <li parent="0" changed="0" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                      <ul>
                        <li parent="2" changed="0" id="3" line_id="#{line_id+3}" active="true">a just to keep track</li>
                        <li parent="2" changed="0" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                        <li parent="2" changed="0" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="0" id="6" parent="0" line_id="#{line_id+6}" active="true">a where as items that begin with
                      <ul>
                        <li parent="6" changed="0" id="7" line_id="#{line_id+7}" active="true">level 2a</li>
                        <li parent="6" changed="0" id="8" line_id="#{line_id+8}" active="false">level 2b</li>
                        <li parent="6" changed="0" id="9" line_id="#{line_id+9}" active="false">level 2c</li>
                        <li parent="6" changed="0" id="10" line_id="#{line_id+10}" active="false">level 2d</li>
                        <li parent="6" changed="0" id="11" line_id="" active="false">level 2e
                        
                          <ul>
                            <li parent="11" changed="0" id="12" line_id="" active="true">level 3a</li>
                            <li parent="11" changed="0" id="13" line_id="" active="false">level 3b</li>
                            <li parent="11" changed="0" id="14" line_id="" active="false">level 3c
                            
                              <ul>
                                <li parent="14" changed="0" id="15" line_id="" active="true">level 4a</li>
                                <li parent="14" changed="0" id="16" line_id="" active="false">level 4b</li>
                                <li parent="14" changed="0" id="17" line_id="" active="false">level 4c</li>
                              </ul>
                            
                            </li>
                            <li parent="11" changed="0" id="18" line_id="" active="false">last node</li>
                          </ul>
                        
                        
                        </li>
                      </ul>
                    </li>
                  </ul>

                </body>
              ]

        document[1] = Document.find_by_id(document[0].id)
        dp[1] = DocumentsHelper::DocumentParser.new(html[1])
        existing_lines = document[1].lines

        unless document[1].html.blank?
          Line.update_line(dp[1].doc,existing_lines,1)
        end

        Line.document_html = html[1]
        Line.preorder_save(dp[1].doc,document[1].id, {'node_0' => root}, 1)
        document[1].update_attribute(:html,Line.document_html)

        #cardinality
        lines = Line.find_all_by_document_id(document[0].id)
        assert_equal(19, lines.length)

        #tree relations
        [1, 2, 6].each do |i|
          assert_equal(Line.where("domid = 0 AND document_id = ?", document[0].id)[0].id, Line.where("domid = ? AND document_id = ?", i, document[0].id)[0].parent_id)
        end
        [3, 4, 5].each do |i|
          assert_equal(Line.where("domid = 2 AND document_id = ?", document[0].id)[0].id, Line.where("domid = ? AND document_id = ?", i, document[0].id)[0].parent_id)
        end
        [7, 8, 9, 10, 11].each do |i|
          assert_equal(Line.where("domid = 6 AND document_id = ?", document[0].id)[0].id, Line.where("domid = ? AND document_id = ?", i, document[0].id)[0].parent_id)
        end
        [12, 13, 14, 18].each do |i|
          assert_equal(Line.where("domid = 11 AND document_id = ?", document[0].id)[0].id, Line.where("domid = ? AND document_id = ?", i, document[0].id)[0].parent_id)
        end
        [15, 16, 17].each do |i|
          assert_equal(Line.where("domid = 14 AND document_id = ?", document[0].id)[0].id, Line.where("domid = ? AND document_id = ?", i, document[0].id)[0].parent_id)
        end

        #text
        assert_equal("a This is a test - think",Line.where("domid = 1 AND document_id = ?", document[0].id)[0].text)
        assert_equal("a the letter 'a' i am using",Line.where("domid = 2 AND document_id = ?", document[0].id)[0].text)
        assert_equal("a just to keep track",Line.where("domid = 3 AND document_id = ?", document[0].id)[0].text)
        assert_equal("a of things that are saved on the first",Line.where("domid = 4 AND document_id = ?", document[0].id)[0].text)
        assert_equal("a run through",Line.where("domid = 5 AND document_id = ?", document[0].id)[0].text)
        assert_equal("a where as items that begin with",Line.where("domid = 6 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 2a",Line.where("domid = 7 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 2b",Line.where("domid = 8 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 2c",Line.where("domid = 9 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 2d",Line.where("domid = 10 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 2e",Line.where("domid = 11 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 3a",Line.where("domid = 12 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 3b",Line.where("domid = 13 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 3c",Line.where("domid = 14 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 4a",Line.where("domid = 15 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 4b",Line.where("domid = 16 AND document_id = ?", document[0].id)[0].text)
        assert_equal("level 4c",Line.where("domid = 17 AND document_id = ?", document[0].id)[0].text)
        assert_equal("last node",Line.where("domid = 18 AND document_id = ?", document[0].id)[0].text)
  end

  def test_list

    #setup
    require 'documents_helper'
    name = 'new document'

    html = %q[
              <ul>
                <li id="node_2" line_id="" changed="0" class="outline_node" active="false" parent="node_0">1
                  <ul>
                    <li line_id="" changed="0" class="outline_node" active="false" id="node_3" parent="node_2">2</li>
                    <li line_id="" changed="0" class="outline_node" active="false" id="node_4" parent="node_2">3
                      <ul>
                        <li line_id="" changed="0" class="outline_node" active="false" id="node_5" parent="node_4">4</li>
                        <li line_id="" changed="0" class="outline_node" active="false" id="node_6" parent="node_4">5</li>
                      </ul>
                    </li>
                  </ul>
                </li>
              </ul>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 'node_0', :document_id => document.id)

#    unless document.html.blank?
#      Line.update_line(dp.doc,existing_lines,1)
#    end

    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc, document.id, {'node_0' => root}, 1)

    #get recently saved
    document = Document.find_by_name(name)
    lines_all = Line.find_all_by_document_id(document.id)
    lines_tree = Line.find(:first,
                           :include => { :children => { :children => { :children => { :children => :children }}}},
                           :conditions => {'lines.parent_id' => nil, 'lines.document_id' => document.id})
    lines = Line.find(:all, :conditions => {'lines.document_id' => document.id})

    #cardinality assertions
    assert_equal(6, lines_all.size)
    assert_equal(6, lines.size)
    assert_equal(1, lines_tree.children.size)
    assert_equal(2, lines_tree.children[0].children.size)
    assert_equal(2, lines_tree.children[0].children[1].children.size)

    #text associations
    assert_equal("root",Line.where("domid = 'node_0' AND document_id = ?", document.id)[0].text)
    assert_equal("1",Line.where("domid = 'node_2' AND document_id = ?", document.id)[0].text)
    assert_equal("2",Line.where("domid = 'node_3' AND document_id = ?", document.id)[0].text)
    assert_equal("3",Line.where("domid = 'node_4' AND document_id = ?", document.id)[0].text)
    assert_equal("4",Line.where("domid = 'node_5' AND document_id = ?", document.id)[0].text)
    assert_equal("5",Line.where("domid = 'node_6' AND document_id = ?", document.id)[0].text)

    #tree relations
    assert_equal(Line.where("domid = 'node_0' AND document_id = ?", document.id)[0].id, Line.where("domid = 'node_2' AND document_id = ?", document.id)[0].parent_id)
    [3, 4].each do |i|
      assert_equal(Line.where("domid = 'node_2' AND document_id = ?", document.id)[0].id, Line.where("domid = ? AND document_id = ?", "node_%i" % i, document.id)[0].parent_id)
    end
    [5, 6].each do |i|
      assert_equal(Line.where("domid = 'node_4' AND document_id = ?", document.id)[0].id, Line.where("domid = ? AND document_id = ?", "node_%i" % i, document.id)[0].parent_id)
    end
  end

  #@todo move? mem creation invoked by line model...
  def test_mem_creation

    #setup
    Mem.delete_all #@todo shouldn't be necessary...
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                      <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 0, :document_id => document.id)

    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc, document.id, {'node_0' => root}, 1)

    #get recently saved
    document = Document.find_by_name(name)

    #cardinality
    assert_equal(6, Mem.all.size)

    #foreign key check
    matches = 0
    Line.find_all_by_document_id(document.id).each do |line|
      if (line.parent_id.nil?)
        next
      end
      match = false
      Mem.all.each do |mem|
        if (line.id == mem.line_id)
          match = true
        end
      end
      assert(match)
      matches += 1
    end
    assert(matches == 6)
  end

  #@todo move? mem active/inactive invoked by line model...
  def test_mem_active_inactive

    #setup
    Mem.delete_all #@todo shouldn't be necessary...
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                      <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 0, :document_id => document.id)

    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc, document.id, {'node_0' => root}, 1)

    #get recently saved
    document = Document.find_by_name(name)

    #active attribute assertions
    assert(Line.find_by_domid("1").mems.first.status)
    assert(Line.find_by_domid("2").mems.first.status)
    assert(Line.find_by_domid("3").mems.first.status)
    assert(!Line.find_by_domid("4").mems.first.status)
    assert(!Line.find_by_domid("5").mems.first.status)
    assert(Line.find_by_domid("6").mems.first.status)

  end

  def test_html_updated
    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                      <li line_id="" changed="0" id="4" parent="2" active="false">a of things that are saved on the first</li>
                      <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 0, :document_id => document.id)

    dp = DocumentsHelper::DocumentParser.new(html)

    Line.document_html = html
    Line.preorder_save(dp.doc,document.id, {'node_0' => root}, 1)
    document.update_attribute(:html,Line.document_html)

    #get recently saved
    document = Document.find_by_name(name)

#    #@todo i struggled with nokogiri before submitting to a complex regex
#    lines = html.scan(/(?:<p|<li)[^>]*(?:[^_]id="([^"]*)"[^>]*line_id="([^"]*)"|line_id="([^"]*)"[^>]*[^_]id="([^"]*)")[^>]*>/)
#    lines.each do |line|
#
#      #check for no line id; check that domid exists
#      dom_id = line[0] || line[3]
#      if (line[1].blank? && line[2].blank? && !dom_id.blank?)
#
#        #retrieve line
#        line = Line.find_by_domid(dom_id)
#        if (!line.blank?)
#          id = line.id
#          #make substitution - two expressions for readability
#          html = html.gsub(/((?:<p|<li)[^>]*[^_]id="#{dom_id}"[^>]*line_id=")("[^>]*>)/) {"#{$1}#{id}#{$2}"}
#          html = html.gsub(/((?:<p|<li)[^>]*line_id=")("[^>]*[^_]id="#{dom_id}"[^>]*>)/) {"#{$1}#{id}#{$2}"}
#        end
#      end
#    end

#    puts document.html

    #no assertions


  end

  def test_augment_large

    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %Q[
                <body>

                  <p changed="0" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="0" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="0" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="5" parent="2" line_id="" active="false">a run through</li>

                        <li changed="0" id="7" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="8" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="9" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="10" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="11" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="12" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="13" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="14" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="15" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="16" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="17" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="18" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="19" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="20" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="21" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="22" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="23" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="24" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="25" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="26" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="27" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="28" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="29" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="30" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="31" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="32" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="33" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="34" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="35" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="36" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="37" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="38" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="39" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="40" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="41" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="42" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="43" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="44" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="45" parent="2" line_id="" active="false">a run through</li>
                        <li changed="0" id="46" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="0" id="47" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="0" id="48" parent="2" line_id="" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="0" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                  </ul>

                </body>
            #]


      document[0] = Document.create
      dp = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end

      Line.document_html = html[0]
      Line.preorder_save(dp.doc, document[0].id, {'node_0' => root}, 1)
      document[0].update_attribute(:html,Line.document_html)

      line_id = Line.first.id
      html[1] = %Q[
                      <body>

                          <p changed="0" parent="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>

                          <ul>

                            <li changed="0" parent="0" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                              <ul>
                                <li parent="2" changed="0" id="3" line_id="#{line_id+3}" active="true">a just to keep track [EDIT]</li>
                                <li parent="2" changed="0" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                                <li parent="2" changed="0" id="5" line_id="#{line_id+5}" active="false">a run through</li>

                                <li changed="0" id="7" parent="2" line_id="#{line_id+6}" active="true">a just to keep track</li>
                                <li changed="0" id="8" parent="2" line_id="#{line_id+7}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="9" parent="2" line_id="#{line_id+8}" active="false">a run through</li>
                                <li changed="0" id="10" parent="2" line_id="#{line_id+9}" active="true">a just to keep track</li>
                                <li changed="0" id="11" parent="2" line_id="#{line_id+10}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="12" parent="2" line_id="#{line_id+11}" active="false">a run through</li>
                                <li changed="0" id="13" parent="2" line_id="#{line_id+12}" active="true">a just to keep track</li>
                                <li changed="0" id="14" parent="2" line_id="#{line_id+13}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="15" parent="2" line_id="#{line_id+14}" active="false">a run through</li>
                                <li changed="0" id="16" parent="2" line_id="#{line_id+15}" active="true">a just to keep track</li>
                                <li changed="0" id="17" parent="2" line_id="#{line_id+16}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="18" parent="2" line_id="#{line_id+17}" active="false">a run through</li>
                                <li changed="0" id="19" parent="2" line_id="#{line_id+18}" active="true">a just to keep track</li>
                                <li changed="0" id="20" parent="2" line_id="#{line_id+19}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="21" parent="2" line_id="#{line_id+20}" active="false">a run through</li>
                                <li changed="0" id="22" parent="2" line_id="#{line_id+21}" active="true">a just to keep track</li>
                                <li changed="0" id="23" parent="2" line_id="#{line_id+22}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="24" parent="2" line_id="#{line_id+23}" active="false">a run through</li>
                                <li changed="0" id="25" parent="2" line_id="#{line_id+24}" active="true">a just to keep track</li>
                                <li changed="0" id="26" parent="2" line_id="#{line_id+25}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="27" parent="2" line_id="#{line_id+26}" active="false">a run through</li>
                                <li changed="0" id="28" parent="2" line_id="#{line_id+27}" active="true">a just to keep track</li>
                                <li changed="0" id="29" parent="2" line_id="#{line_id+28}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="30" parent="2" line_id="#{line_id+29}" active="false">a run through</li>
                                <li changed="0" id="31" parent="2" line_id="#{line_id+30}" active="true">a just to keep track</li>
                                <li changed="0" id="32" parent="2" line_id="#{line_id+31}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="33" parent="2" line_id="#{line_id+32}" active="false">a run through</li>
                                <li changed="0" id="34" parent="2" line_id="#{line_id+33}" active="true">a just to keep track</li>
                                <li changed="0" id="35" parent="2" line_id="#{line_id+34}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="36" parent="2" line_id="#{line_id+35}" active="false">a run through</li>
                                <li changed="0" id="37" parent="2" line_id="#{line_id+36}" active="true">a just to keep track</li>
                                <li changed="0" id="38" parent="2" line_id="#{line_id+37}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="39" parent="2" line_id="#{line_id+38}" active="false">a run through</li>
                                <li changed="0" id="40" parent="2" line_id="#{line_id+39}" active="true">a just to keep track</li>
                                <li changed="0" id="41" parent="2" line_id="#{line_id+40}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="42" parent="2" line_id="#{line_id+41}" active="false">a run through</li>
                                <li changed="0" id="43" parent="2" line_id="#{line_id+42}" active="true">a just to keep track</li>
                                <li changed="0" id="44" parent="2" line_id="#{line_id+43}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="45" parent="2" line_id="#{line_id+44}" active="false">a run through</li>
                                <li changed="0" id="46" parent="2" line_id="#{line_id+45}" active="true">a just to keep track</li>
                                <li changed="0" id="47" parent="2" line_id="#{line_id+46}" active="false">a of things that are saved on the first</li>
                                <li changed="0" id="48" parent="2" line_id="#{line_id+47}" active="false">a run through</li>
                              </ul>
                            </li>

                            <li changed="0" parent="0" id="6" line_id="#{line_id+48}" active="true">a where as items that begin with</li>

                          </ul>

                        </body>
                      ]


      document[1] = Document.find_by_id(document[0].id)
      dp = DocumentsHelper::DocumentParser.new(html[1])
      existing_lines = document[1].lines

      unless document[1].html.blank?
        Line.update_line(dp.doc,existing_lines,1)
      end

#      document[1].update_attribute(:html,html[1])
#
#      assert_equal(7, Line.all.length)
#      assert_equal("a just to keep track [EDIT]", Line.all[3].text)

  end

end