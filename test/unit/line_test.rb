require 'test_helper'
require 'document'

class LineTest < ActiveSupport::TestCase

  def test_save

    #setup
    require 'documents_helper'
    name = 'new document'
    html = %q[
              <body>

                <p changed="1" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li changed="1" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li changed="1" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                      <li changed="1" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                      <li changed="1" id="5" parent="2" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="1" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

                </ul>

              </body>
            ]

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:text => "root", :domid => 0, :document_id => document.id)
    
    unless document.html.blank?
      Line.update_line(dp.doc,existing_lines)
    end
    
    dp = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(dp.doc, document.id)

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

                  <p changed="1" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="1" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="1" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="1" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="1" id="5" parent="2" line_id="" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="1" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

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
        Line.update_line(dp.doc,existing_lines)
      end

      document[0].update_attribute(:html,html[0])
      Line.preorder_save(dp.doc, document[0].id)
      
      #assert_equal(7, Line.all.length)
      

      #hsh = Line.id_hash(Document.find_by_id(id))

      #render :json => hsh
      
      line_id = Line.first.id
      html[1] = %Q[
                      <body>
        
                          <p changed="1" parent="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>
        
                          <ul>
        
                            <li changed="1" parent="0" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                              <ul>
                                <li parent="2" changed="90273598237590879082372" id="3" line_id="#{line_id+3}" active="true">a just to keep track [EDIT]</li>
                                <li parent="2" changed="1" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                                <li parent="2" changed="1" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                              </ul>
                            </li>
        
                            <li changed="1" parent="0" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>
        
                          </ul>
        
                        </body>
                      ]
        

      document[1] = Document.find_by_id(document[0].id)
      dp = DocumentsHelper::DocumentParser.new(html[1])
      existing_lines = document[1].lines
      
      unless document[1].html.blank?
        Line.update_line(dp.doc,existing_lines)
      end          

      document[1].update_attribute(:html,html[1])

      assert_equal(7, Line.all.length)
      assert_equal("a just to keep track [EDIT]", Line.all[3].text)

  end

  def test_augment

    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>

                  <p changed="1" id="1" parent="0" line_id="" active="true">a This is a test - think<br></p>

                  <ul>

                    <li changed="1" id="2" parent="0" line_id="" active="true">a the letter 'a' i am using
                      <ul>
                        <li changed="1" id="3" parent="2" line_id="" active="true">a just to keep track</li>
                        <li changed="1" id="4" parent="2" line_id="" active="false">a of things that are saved on the first</li>
                        <li changed="1" id="5" parent="2" line_id="" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="1" id="6" parent="0" line_id="" active="true">a where as items that begin with</li>

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
        Line.update_line(dp.doc,existing_lines)
      end

      document[0].update_attribute(:html,html[0])
      Line.preorder_save(dp.doc, document[0].id)
      
      assert_equal(7, Line.all.length)
      

      #hsh = Line.id_hash(Document.find_by_id(id))

      #render :json => hsh
      
      line_id = Line.first.id
      html[1] = %Q[
                      <body>
        
                          <p changed="1" parent="0" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>
        
                          <ul>
        
                            <li changed="1" parent="0"  id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                              <ul>
                                <li parent="2" changed="90273598237590879082372" id="3" line_id="#{line_id+3}" active="true">a just to keep track</li>
                                <li parent="2" changed="1" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                                <li parent="2" changed="1" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                              </ul>
                            </li>
        
                            <li parent="0" changed="1" id="6" line_id="#{line_id+6}" active="true">a where as items that begin with</li>
                            
                            <li parent="0" changed="" id="7" line_id="" active="true">PLEASE WORK</li>
        
                          </ul>
        
                        </body>
                      ]
        

      document[1] = Document.find_by_id(document[0].id)
      dp = DocumentsHelper::DocumentParser.new(html[1])
      existing_lines = document[1].lines
      
      unless document[1].html.blank?
        Line.update_line(dp.doc,existing_lines)
      end

      document[1].update_attribute(:html,html[1])
      Line.preorder_save(dp.doc, document[1].id)


      assert_equal(8, Line.all.length)
      assert_equal("a just to keep track", Line.all[3].text)
      assert_equal("PLEASE WORK", Line.all[7].text)
      
  end
  
  def test_multiple_levels
    
    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>
                <p parent="0" active="false" class="outline_node" changed="" line_id="" id="2">
                	node 1<br>
                </p>
                <p parent="0" id="3" active="false" class="outline_node" changed="" line_id="">
                	node 2<br>
                </p>
                <ul>
                	<li parent="0" id="4" active="false" class="outline_node" changed="" line_id="">node 3<br>
                	</li>
                	<li parent="0" id="5" active="false" class="outline_node" changed="" line_id="">node 4<br>
                		</li>
                </ul>
                </body>
            ]
    
   
      document[0] = Document.create
      dp = []
      dp[0] = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines)
      end
      
      document[0].update_attribute(:html,html[0])
      Line.preorder_save(dp[0].doc,document[0].id)
      
      assert_equal(5,document[0].lines.length)
      
      ###
      
      line_id = Line.first.id
      html[1] = %Q[
                  
                  <body>
                	<p parent="0" active="false" class="outline_node" changed="1" line_id="#{line_id+1}" id="2">node 1<br></p>
                  <p parent="0" id="3" active="false" class="outline_node" changed="1" line_id="#{line_id+2}">node 2<br>
                  </p>
                  <ul>
                  	<li parent="0" id="4" active="false" class="outline_node" changed="1" line_id="#{line_id+3}">node 3<br>
                  	</li>
                  	<li parent="0" id="5" active="false" class="outline_node" changed="1" line_id="#{line_id+4}">node 4<br>
                  		<ul>
                  			<li id="6" parent="5" active="false" class="outline_node" changed="" line_id="">node 5<br>
                  			</li>
                  			<li id="7" parent="5" active="false" class="outline_node" changed="" line_id="">node 6<br>
                  			</li>
                  		</ul>
                  	</li>
                  	<li id="8" parent="0" active="false" class="outline_node" changed="" line_id="">node 7<br>
                  	</li>
                  </ul>
                  </body>


              ]
      
        document[1] = Document.find_by_id(document[0].id)
        dp[1] = DocumentsHelper::DocumentParser.new(html[1])
        existing_lines = document[1].lines

        unless document[1].html.blank?
          Line.update_line(dp[1].doc,existing_lines)
        end

        document[1].update_attribute(:html,html[1])
        Line.preorder_save(dp[1].doc, document[1].id)

        assert_equal(8, Line.all.length)
        assert_equal("node 1",Line.find_by_domid("2").text)
        assert_equal("node 3",Line.find_by_domid("4").text)
        
        
        assert_equal("node 2",Line.find_by_domid("3").text)
    
  end
  
  def test_augment_depth_4
    #setup
    require 'documents_helper'
    html = []
    document = []
    html[0] = %q[
                <body>

                <p parent="0" changed="1" id="1" line_id="" active="true">a This is a test - think<br></p>

                <ul>

                  <li parent="0" changed="1" id="2" line_id="" active="true">a the letter 'a' i am using
                    <ul>
                      <li parent="2" changed="1" id="3" line_id="" active="true">a just to keep track</li>
                      <li parent="2" changed="1" id="4" line_id="" active="false">a of things that are saved on the first</li>
                      <li parent="2" changed="1" id="5" line_id="" active="false">a run through</li>
                    </ul>
                  </li>

                  <li changed="1" id="6" parent="0" line_id="" active="true">a where as items that begin with
                    <ul>
                      <li parent="6" changed="1" id="7" line_id="" active="true">level 2a</li>
                      <li parent="6" changed="1" id="8" line_id="" active="false">level 2b</li>
                      <li parent="6" changed="1" id="9" line_id="" active="false">level 2c</li>
                      <li parent="6" changed="1" id="10" line_id="" active="false">level 2d</li>
                    </ul>
                  </li>

                </ul>

              </body>
            ]
    
   
      document[0] = Document.create
      dp = []
      dp[0] = DocumentsHelper::DocumentParser.new(html[0])
      existing_lines = document[0].lines

      root = Line.create( :document_id => document[0].id,
                          :domid => 0,
                          :text => "root" )

      unless document[0].html.blank?
        Line.update_line(dp.doc,existing_lines)
      end
      
      document[0].update_attribute(:html,html[0])
      Line.preorder_save(dp[0].doc,document[0].id)
      
      assert_equal(11,document[0].lines.length)
      
      ###
      
      line_id = Line.first.id
      html[1] = %Q[
                  <body>

                  <p parent="0" changed="1" id="1" line_id="#{line_id+1}" active="true">a This is a test - think<br></p>

                  <ul>

                    <li parent="0" changed="1" id="2" line_id="#{line_id+2}" active="true">a the letter 'a' i am using
                      <ul>
                        <li parent="2" changed="1" id="3" line_id="#{line_id+3}" active="true">a just to keep track</li>
                        <li parent="2" changed="1" id="4" line_id="#{line_id+4}" active="false">a of things that are saved on the first</li>
                        <li parent="2" changed="1" id="5" line_id="#{line_id+5}" active="false">a run through</li>
                      </ul>
                    </li>

                    <li changed="1" id="6" parent="0" line_id="#{line_id+6}" active="true">a where as items that begin with
                      <ul>
                        <li parent="6" changed="1" id="7" line_id="#{line_id+7}" active="true">level 2a</li>
                        <li parent="6" changed="1" id="8" line_id="#{line_id+8}" active="false">level 2b</li>
                        <li parent="6" changed="1" id="9" line_id="#{line_id+9}" active="false">level 2c</li>
                        <li parent="6" changed="1" id="10" line_id="#{line_id+10}" active="false">level 2d</li>
                        <li parent="6" changed="1" id="11" line_id="" active="false">level 2e
                        
                          <ul>
                            <li parent="11" changed="1" id="12" line_id="" active="true">level 3a</li>
                            <li parent="11" changed="1" id="13" line_id="" active="false">level 3b</li>
                            <li parent="11" changed="1" id="14" line_id="" active="false">level 3c
                            
                              <ul>
                                <li parent="14" changed="1" id="15" line_id="" active="true">level 4a</li>
                                <li parent="14" changed="1" id="16" line_id="" active="false">level 4b</li>
                                <li parent="14" changed="1" id="17" line_id="" active="false">level 4c</li>
                              </ul>
                            
                            </li>
                            <li parent="11" changed="1" id="18" line_id="" active="false">last node</li>
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
          Line.update_line(dp[1].doc,existing_lines)
        end

        document[1].update_attribute(:html,html[1])
        Line.preorder_save(dp[1].doc, document[1].id)

        #cardinality
        assert_equal(19, Line.all.length)

        #tree relations
        [1, 2, 6].each do |i|
          assert_equal(Line.find_by_domid(0).id, Line.find_by_domid(i).parent_id)
        end
        [3, 4, 5].each do |i|
          assert_equal(Line.find_by_domid(2).id, Line.find_by_domid(i).parent_id)
        end
        [7, 8, 9, 10, 11].each do |i|
          assert_equal(Line.find_by_domid(6).id, Line.find_by_domid(i).parent_id)
        end
        [12, 13, 14, 18].each do |i|
          assert_equal(Line.find_by_domid(11).id, Line.find_by_domid(i).parent_id)
        end
        [15, 16, 17].each do |i|
          assert_equal(Line.find_by_domid(14).id, Line.find_by_domid(i).parent_id)
        end

        #text
        assert_equal("a This is a test - think",Line.find_by_domid('1').text)
        assert_equal("a the letter 'a' i am using",Line.find_by_domid('2').text)
        assert_equal("a just to keep track",Line.find_by_domid('3').text)
        assert_equal("a of things that are saved on the first",Line.find_by_domid('4').text)
        assert_equal("a run through",Line.find_by_domid('5').text)
        assert_equal("a where as items that begin with",Line.find_by_domid('6').text)
        assert_equal("level 2a",Line.find_by_domid('7').text)
        assert_equal("level 2b",Line.find_by_domid('8').text)
        assert_equal("level 2c",Line.find_by_domid('9').text)
        assert_equal("level 2d",Line.find_by_domid('10').text)
        assert_equal("level 2e",Line.find_by_domid('11').text)
        assert_equal("level 3a",Line.find_by_domid('12').text)
        assert_equal("level 3b",Line.find_by_domid('13').text)
        assert_equal("level 3c",Line.find_by_domid('14').text)
        assert_equal("level 4a",Line.find_by_domid('15').text)
        assert_equal("level 4b",Line.find_by_domid('16').text)
        assert_equal("level 4c",Line.find_by_domid('17').text)
        assert_equal("last node",Line.find_by_domid('18').text)
  end
end

 
 
 
 
 
 
 
 
 
 
 
 
 
 
