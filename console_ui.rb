=begin
  TODO
  - Node: choices are not needed separately but links have been given another data type that
  establishes the link between the user answer and the node to go next when given that answer
  - instead of make_sorted_hash, sort the hash simply by Hash#sort that will give an array of arrays.
=end
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

class ConsoleMenu

=begin
The ConsoleMenu handles all navigation and ui related tasks for a console input
=end
  
  class Navigator
=begin
ConsoleMenu::Navigator keeps track of where the user is located in the navigation tree. It queries
the actual node for the quetion it has to pose and forwards the answer coming from the UI to the node
so the node can tell where should it go next. Somerhing along the lines of:
- I am at node_x
- question_and_valid_inputs = node_x.get_valid_options
- user_answer = console_ui.get_answer_from_user(question_and_valid_inputs)
- next_link = node_x.get_next_link(user_answer)
- go_to_next_link (e.g node_y)
=end
    attr_reader :location, :nodes, :navigation_objects
    
    def initialize(loc, ui)
      @location = loc
      @ui = ui
      @prev_location = nil
      @menu_nav_keys = Hash.new
      @navigation_objects = Array.new
      @nodes = Hash.new
      add_menu_nav_keys
      add_nodes(loc)
    end

    def add_menu_nav_keys
      # FIXME: escape sometimes comes back as "\e" and sometimes as '\e' 
      # and they don't appear to be the same
      @menu_nav_keys['\e'] = Proc.new { go_to_main }
      # @menu_nav_keys["\e"] = Proc.new { go_to_main }
      # @menu_nav_keys['\e[D'] = go_back
      # @menu_nav_keys['\e[C'] = go_forward
    end
    
    def add_nodes(*nodes)
      nodes.each do |node|
        @nodes[node.get_id] = node
      end
    end
    
    def find_node(node_id)
      @nodes[node_id]
    end
    
    def get_user_answer
      # just delegate the task to the node I'm at
      q_data = @location.get_question_data
      valid_answers = @menu_nav_keys.keys.concat(q_data[:valid_answers])
      return @ui.ask(q_data[:question], q_data[:choices], valid_answers)
    end
    
    def get_next_node
      answer = get_user_answer
      puts "User answer: #{answer}"
      if @menu_nav_keys.key?(answer)
        next_node_id = @menu_nav_keys[answer].call
      else
        link_action = @location.get_link_action_for_answer(answer)
        do_link_action(link_action, answer) if link_action
        next_node_id = @location.get_link_id_for_answer(answer)
      end
      find_node(next_node_id)
    end

    def go_to(node)
      unless node.nil?
        @prev_location = @location
        @location = node
      end
    end
    
    def go_to_main
      puts "going back to main"
      @prev_location = @location
      @location = find_node(:main)
      @location.get_id
    end
    
    def go_back
      @location = @prev_location
      @prev_location = nil
      @location.get_id
    end
        
    def browse
      while true
        next_node = get_next_node
        go_to(next_node)
      end
    end
    
    def do_link_action(action_name, answer)
      link_action = method(action_name.to_s)
      link_action.call(answer)
    end
    
    def make_navigation_object(value)
      navigation_objects.push(NavigationObject.new(value))      
    end
    
    def make_expense(value)
      navigation_objects.push(Expense::Expense.new(value))
    end
        
    class NavigationObject
      # This holds saved data created during navigation

      # TODO: this class should be replaced by outside classes
      # that can be passed to the navigator. Navigator instance methods
      # should be created (by metaprogramming, probably) on the fly
      # from the yaml file that describes the problem domain.
      # E.g in the case of groupfin, a create_expense method should be created
      # that just creates an Expense object (make_expense).
      
      attr_reader :value
      def initialize(value)
        @value = value
      end
    end
    
    class Node
      # The nodes of the tree represent the menu items and are denoted by symbols 
      # (e.g :main is the root of the tree)      
      # Navigation happens between nodes. A node has a _question_ (of _q_type_) and possibly
      # _choices_ which to choose from (if question is of :single_choice or :multiple_choice type)
      # _action_ is called when we arrive at that node.
      
=begin
  todo: make a node action that will be executed with the users answer as argument
  that allows to make objects in free_input nodes
=end
      class NodeError < Exception
      end
      attr_reader :links
      
      def self.link_id(value)
        value.to_s.to_sym
      end

      def self.make_sorted_hash(unsorted_hash)
        sorted_hash = Array.new
        unsorted_hash.each_pair { |k, v| sorted_hash.push({ k => v })  }
        sorted_hash.sort { |h1, h2| h1.keys()[0] <=> h2.keys()[0] }
      end
            
      def initialize(id, question, q_type, links)
        @id = id
        @question = question 
        @q_type = q_type # :free_input, :single_choice, :multiple_choice
        #
        @links = links
        @action = :pose_question
      end
      
      def get_id
        @id
      end
      
      def get_question_data
        question_data = case @q_type
        when :single_choice
          choices_for_question = get_choices_for_question_single_choice
          { :question => @question, :choices => self.class.make_sorted_hash(choices_for_question), :valid_answers => choices_for_question.keys.collect { |k| k.to_s } }
        when :free_input
          { :question => @question, :choices => [], :valid_answers => [:any] }
        else
          nil
        end
        question_data
      end
      
      def get_choices_for_question_single_choice
        # user-friendly indexing: starting from one instead of zero
        choices_for_display = Hash.new
        links.each_pair { |link_id, link_data| choices_for_display[link_id] = link_data[:title] }
        return choices_for_display
      end

      def get_link_attribute_for_answer(answer, property)
        link = @links.find { |link| link[0] == answer }
        return link[1][property] unless link.nil?        
      end
      
      def get_link_action_for_answer(answer)
        get_link_attribute_for_answer(answer, :action)
      end
      
      def get_link_id_for_answer(answer)
        get_link_attribute_for_answer(answer, :link_id)
      end
      
    end
    
  end
  
  class UI
=begin
    ConsoleMenu::UI takes an answer from the user and returns it. Answer codes are:
    - a number if the question is of 'single choice' type
    - a string if the question is of 'free input' type (the answer can be validated and is only
    accepted once a valid answer is received from the user)
    - a list of numbers if the question is of 'multiple choice' type
    - :esc if user wants to go up one level in the menu
    TODO: the UI should just keep asking until it receives a valid input (valid meaning
    an input that satisfies the given block). The question and answers should be passed to
    it as parameters. 
    Also, at initialization it takes some inputs that are always accepted and a mapping
    of what entity (symbol) they are converted to before returning it.
=end  
  
    attr_accessor :prompt
    attr_accessor :io_stream
  
    def initialize(prompt='>', io_stream=nil)
      @prompt = prompt
      @io_stream = io_stream
    end
  
    def take_answer
      io_stream.nil? ? gets.chomp : io_stream.gets
    end
  
    def try_again(msg)
      puts ""
      puts msg
      print @prompt + ' '
    end
    
    def echo_answer(answer)
      puts answer
    end
    
    def ask(question, choices, valid_answers)
      out = []
      unless choices.empty?
        choices.each do |choice|
          choice_id = choice.keys[0]
          choice_title = choice[choice_id]
          out << "#{choice_id} #{choice_title} \n"
        end
      end      
      out << "#{question}\n" unless question.empty?
      puts out.join('')
      print @prompt + ' '
      tries = 0
      unless valid_answers.include?(:any)
        user_answer = take_answer
        until tries == 5 || valid_answers.include?(user_answer) do
          tries += 1
          try_again("Please choose a valid option")
        end
      else
        user_answer = take_answer
      end
      echo_answer(user_answer)
      return user_answer
    end
      
  end
    
end

if __FILE__ == $0
  class ConsoleMenuTester < Test::Unit::TestCase
    FakeFileDesc = 1
    def setup
      @test_prompt = '>'
      @console_ui = ConsoleMenu::UI.new(prompt=@test_prompt)
      @test_question = 'Who wins Euro\'08?'
      @test_answers = [ { 1 => 'Netherlands', 2 => 'Portugal', 3 => 'Spain', 4 => 'Turkey', 5 => 'Germany'} ]
      #---
      @free_input_node = ConsoleMenu::Navigator::Node.new(:main, "please tell me anything", :free_input, [])
      @main_node = ConsoleMenu::Navigator::Node.new(:main, "Main menu of Euro '08", :single_choice, { "1" => { :link_id => :group_sel, :title => "Group selection" }, "2" => { :link_id => :pick_fav_team, :title => "Pick favorite team", :action => "make_navigation_object" }, "3" => { :link_id => :see_results, :title => "See results" }})
      @group_sel_node = ConsoleMenu::Navigator::Node.new(:group_sel, "please choose a group", :single_choice, { "1" => { :link_id => :group_a, :title => "Group A"}, "2" => { :link_id => :group_b, :title => "Group B" }, "3" => { :link_id => :group_c, :title => "Group C" }, "4" => { :link_id => :group_d, :title => "Group D"}})
      @group_a_node = ConsoleMenu::Navigator::Node.new(:group_a, "which team?", :single_choice, { "1" => { :link_id => :switzerland, :title => 'Switzerland'}, "2" => { :link_id => :portugal, :title => 'Portugal'}, "3" => { :link_id => :turkey, :title => 'Turkey'}, "4" => { :link_id => :czechrepublic, :title => 'Czech Republic'}})
      @group_b_node = ConsoleMenu::Navigator::Node.new(:group_b, "which team?", :single_choice, { "1" => { :link_id => :germany, :title => 'Germany'}, "2" => { :link_id => :poland, :title => 'Poland'}, "3" => { :link_id => :croatia, :title => 'Croatia'}, "4" => { :link_id => :austria, :title => 'Austria'}})
      @group_c_node = ConsoleMenu::Navigator::Node.new(:group_c, "which team?", :single_choice, { "1" => { :link_id => :netherlands, :title => 'Netherlands'}, "2" => { :link_id => :italy, :title => 'Italy'}, "3" => { :link_id => :france, :title => 'France'}, "4" => { :link_id => :romania, :title => 'Romania'}})
      @group_d_node = ConsoleMenu::Navigator::Node.new(:group_d, "which team?", :single_choice, { "1" => { :link_id => :spain, :title => 'Spain'}, "2" => { :link_id => :russia, :title => 'Russia'}, "3" => { :link_id => :greece, :title => 'Greece'}, "4" => { :link_id => :sweden, :title => 'Sweden'}})
      @navigator = ConsoleMenu::Navigator.new(@main_node, @console_ui)
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
    
    def XXXtest_make_the_menu
      @navigator.make_the_menu([@main_node, @group_sel_node].map { |node| node.to_yaml }) 
    end    

    def test_go_back
      @navigator.go_to(@group_sel_node)
      @navigator.go_back
      assert_equal(@main_node, @navigator.location)
    end
    
    def test_does_action
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
      assert_equal(:an_id, ConsoleMenu::Navigator::Node.link_id(:an_id))
      assert_equal(:an_id, ConsoleMenu::Navigator::Node.link_id("an_id"))
      assert_equal(:"1", ConsoleMenu::Navigator::Node.link_id(1))
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
      @expense_input_node = ConsoleMenu::Navigator::Node.new(:main, "so how much did you pay?", :free_input, [])
      @navigator = ConsoleMenu::Navigator.new(@expense_input_node, @console_ui)
      @navigator.browse
    end
    
  end
  
end