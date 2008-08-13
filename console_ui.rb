require "node"
require "ui"
require "navigator"
require "navigation_object"

require "test/unit"
require "yaml"

class RandomIO < IO
=begin
Gives back a random integer between 0 and _max_+1 each time
it gets is called on it 
(the class has been constructed for testing reasons)
it should be instantiated like this (till I find a nicer way): 
  RandomIO(fake_int_for_file_handler, mode_string, max)
=end  
  def initialize(fake_file_desc, max)
    # super(fake_file_desc, "r")
    @max = max
  end
  def gets
    # read
    rand(@max+1)
  end
end

class SeriesIO < IO
  def initialize(fake_file_desc, series, circular=false)
    # super(fake_file_desc, "r")
    @series = series
    @circular = circular
    @idx = 0
  end
  def gets
    @idx += 1
    @idx = 1 if @circular
    return @series[@idx-1]
  end
end

class FixIO < IO
  attr_accessor :out_data
  def initialize(fake_file_desc, out_data)
    # super(fake_file_desc, "r")
    @out_data = out_data
  end
  def gets
    out_data
  end  
end

if __FILE__ == $0
  class ConsoleNavigatorTester < Test::Unit::TestCase
    FakeFileDesc = 1
    def setup
      @test_prompt = '>'
      @console_ui = UI.new(prompt=@test_prompt)
      @test_question = 'Who wins Euro\'08?'
      @test_answers = [ { 1 => 'Netherlands', 2 => 'Portugal', 3 => 'Spain', 4 => 'Turkey', 5 => 'Germany'} ]
      #---
      @free_input_node = Node.new(:main, "please tell me anything", :free_input, nil, {})
      @main_node = Node.new(:main, "Main menu of Euro '08", :single_choice, nil, { "1" => { :link_id => :group_sel, :title => "Group selection" }, "2" => { :link_id => :pick_fav_team, :title => "Pick favorite team", :action => "make_navigation_object" }, "3" => { :link_id => :see_results, :title => "See results" }})
      @group_sel_node = Node.new(:group_sel, "please choose a group", :single_choice, nil, { "1" => { :link_id => :group_a, :title => "Group A"}, "2" => { :link_id => :group_b, :title => "Group B" }, "3" => { :link_id => :group_c, :title => "Group C" }, "4" => { :link_id => :group_d, :title => "Group D"}})
      @group_a_node = Node.new(:group_a, "which team?", :single_choice, nil, { "1" => { :link_id => :switzerland, :title => 'Switzerland'}, "2" => { :link_id => :portugal, :title => 'Portugal'}, "3" => { :link_id => :turkey, :title => 'Turkey'}, "4" => { :link_id => :czechrepublic, :title => 'Czech Republic'}})
      @group_b_node = Node.new(:group_b, "which team?", :single_choice, nil, { "1" => { :link_id => :germany, :title => 'Germany'}, "2" => { :link_id => :poland, :title => 'Poland'}, "3" => { :link_id => :croatia, :title => 'Croatia'}, "4" => { :link_id => :austria, :title => 'Austria'}})
      @group_c_node = Node.new(:group_c, "which team?", :single_choice, nil, { "1" => { :link_id => :netherlands, :title => 'Netherlands'}, "2" => { :link_id => :italy, :title => 'Italy'}, "3" => { :link_id => :france, :title => 'France'}, "4" => { :link_id => :romania, :title => 'Romania'}})
      @group_d_node = Node.new(:group_d, "which team?", :single_choice, nil, { "1" => { :link_id => :spain, :title => 'Spain'}, "2" => { :link_id => :russia, :title => 'Russia'}, "3" => { :link_id => :greece, :title => 'Greece'}, "4" => { :link_id => :sweden, :title => 'Sweden'}})
      @ticket_q_node = Node.new(:main, "how much did the ticket cost?", :free_input, Proc.new { |value| NavigationObject.new(value) }, {})
      @navigator = Navigator.new(@main_node, @console_ui)
    end
    def load_nodes_to_navigator
      @navigator.add_nodes(@main_node, @group_sel_node, @group_a_node, @group_b_node, @group_c_node, @group_d_node)
    end
    def XXXtest_prompt
      answer = @console_ui.single_choice(@test_question, @test_answers)
      assert_equal(@test_prompt, answer[0,1])
    end
    def XXXtest_ask_with_single_choice
      @console_ui.io_stream = SeriesIO.new(FakeFileDesc, @test_answers.length)
      assert_equal(true, (1..@test_answers.length).include?(@console_ui.ask(@test_question, @test_answers, nil))) 
    end
    def test_ask_with_free_input
      @console_ui.io_stream = SeriesIO.new(FakeFileDesc, ('a'..'z').to_a)
      assert_equal(true, ('a'..'z').include?(@console_ui.ask("Who are you?", [], [])))
    end
    
    def XXXtest_single_choice
      answer = @console_ui.single_choice(@test_question, @test_answers)
      assert_equal(true, (0...@test_answers.length).include?(answer))
    end
    
    def XXXtest_free_input
      answer = @console_ui.free_input("how would you rate this movie? (1-5)") { |x| x = x.to_i; x >= 1 && x <= 5 }
      assert_equal(true, (1..5).include?(answer.to_i))
    end
    
    def test_random_io
      random_io = RandomIO.new(FakeFileDesc, 10)
      @console_ui.io_stream = random_io
      10.times { |i| assert_equal(true, (0..10).include?(@console_ui.take_answer)) }
    end
    
    def test_series_io
      groups = [:group_a, :group_b, :group_c, :group_d]
      series_io = SeriesIO.new(FakeFileDesc, groups)
      assert_equal(:group_a, series_io.gets)
      assert_equal(:group_b, series_io.gets)
      assert_equal(:group_c, series_io.gets)
      assert_equal(:group_d, series_io.gets)
      assert_nil(series_io.gets)
    end
    
    def test_circular_series_io
      groups = [:group_a, :group_b, :group_c, :group_d]
      circular_series_io = SeriesIO.new(FakeFileDesc, groups, true)
      groups.length.times { |n| circular_series_io.gets }
      assert_equal(:group_a, circular_series_io.gets )
    end
    
    def test_fix_io
      fix_io = FixIO.new(FakeFileDesc, "a")
      assert_equal('a', fix_io.gets)
      fix_io.out_data = 'b'
      assert_equal('b', fix_io.gets)
    end
    
    # Navigator
    def test_navigator_init
      assert_equal(@main_node, @navigator.location)
    end
    
    def test_add_nodes
      @navigator.add_nodes(@group_sel_node, @group_a_node)
      assert_equal(true, @navigator.nodes.key?(@group_sel_node.get_id))
      assert_equal(true, @navigator.nodes.key?(@group_a_node.get_id))
      assert_equal(@group_sel_node, @navigator.nodes[@group_sel_node.get_id])
      assert_equal(@group_a_node, @navigator.nodes[@group_a_node.get_id])
    end
    
    def test_find_node
      @navigator.add_nodes(@group_sel_node, @group_a_node)
      assert_equal(nil, @navigator.find_node(:nonexistent_node_id))
      assert_equal(@group_sel_node, @navigator.find_node(@group_sel_node.get_id))
      assert_equal(@group_a_node, @navigator.find_node(@group_a_node.get_id))      
    end
    
    def XXXtest_get_user_answer
      q_data = @navigator.get_user_answer
      q_data_from_main_node = @navigator.location.get_question_data
      assert_equal(q_data_from_main_node[:question], q_data[:question])
      assert_equal(q_data_from_main_node[:choices], q_data[:choices])
      assert_equal(q_data_from_main_node[:valid_answers], q_data[:valid_answers])
    end
    
    def test_gets_next_node
      fix_io = FixIO.new(FakeFileDesc, "1")
      @console_ui.io_stream = fix_io
      @navigator.add_nodes(@group_sel_node, @group_a_node)      
      assert_equal(@main_node, @navigator.location)
      assert_equal(@group_sel_node, @navigator.get_next_node)
    end

    def test_goes_to_main
      fix_io = FixIO.new(FakeFileDesc, "1")
      @console_ui.io_stream = fix_io
      load_nodes_to_navigator
      2.times { |n| @navigator.go_to(@navigator.get_next_node) }
      assert_equal(@group_a_node, @navigator.location)
      fix_io.out_data = '\e'
      @navigator.go_to(@navigator.get_next_node)
      assert_equal(@main_node, @navigator.location)
    end
    
    def test_saves_objects
      fix_io = FixIO.new(FakeFileDesc, "10 dollars")
      @console_ui.io_stream = fix_io
      @navigator = Navigator.new(@ticket_q_node, @console_ui)
      @navigator.get_next_node
      @navigator.save_objects
      assert_equal(@navigator.navigation_objects.length, @navigator.navigation_objects.select { |obj| obj.saved? }.length )
    end
    
    def XXXtest_make_the_menu
      @navigator.make_the_menu([@main_node, @group_sel_node].map { |node| node.to_yaml }) 
    end    

    def test_go_back
      @navigator.go_to(@group_sel_node)
      @navigator.go_back
      assert_equal(@main_node, @navigator.location)
    end
    
    def test_does_node_action
      fix_io = FixIO.new(FakeFileDesc, "10 dollars")
      @console_ui.io_stream = fix_io
      @navigator = Navigator.new(@ticket_q_node, @console_ui)
      @navigator.get_next_node
      assert_equal("10 dollars", @navigator.navigation_objects.first.value)
    end
    
    def test_does_link_action
      fix_io = FixIO.new(FakeFileDesc, "2")
      @console_ui.io_stream = fix_io
      load_nodes_to_navigator
      @navigator.go_to(@navigator.get_next_node)
      assert_equal("2", @navigator.navigation_objects.first.value)
    end
    
    def XXXtest_browse_start
      load_nodes_to_navigator
      @navigator.browse
    end
    
    # Node    
    def test_link_id
      assert_equal(:an_id, Node.link_id(:an_id))
      assert_equal(:an_id, Node.link_id("an_id"))
      assert_equal(:"1", Node.link_id(1))
    end
    
    def test_make_sorted_hash
      assert_equal({}, {})
      assert_equal([{ 1 => "Group A"}, { 2 => "Group B"}, { 3 => "Group C"}, { 4 => "Group D"} ], @main_node.class.make_sorted_hash({ 1 => "Group A", 4 => "Group D", 3 => "Group C", 2 => "Group B" }))
    end
    
    def test_get_choices_for_question_single_choice
      assert_equal({"1" => "Group A", "2" => "Group B", "3" => "Group C", "4" => "Group D"}, @group_sel_node.get_choices_for_question_single_choice)
    end    
    
    #-----
    def XXXtest_creating_an_expense
      @expense_input_node = Node.new(:main, "so how much did you pay?", :free_input, node_action, {})
      @navigator = Navigator.new(@expense_input_node, @console_ui)
      @navigator.browse
    end
    
  end
  
end