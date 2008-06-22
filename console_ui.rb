require "test/unit"

class RandomIO < IO
=begin
Gives back a random integer between 0 and _max_+1 each time
it gets is called on it 
(the class has been constructed for testing reasons)
it should be instantiated like this (till I find a nicer way): 
  RandomIO(fake_int_for_file_handler, mode_string, max)
=end  
  def initialize(max)
    super(11, "r")
    @max = max
  end
  def gets
    # read
    rand(@max+1)
  end
end

class SeriesIO < IO
  def initialize(series, circular=false)
    super(11, "r")
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

class ConsoleMenu

=begin
The ConsoleMenu handles all navigation and ui related tasks for a console input
=end
  
  class Navigator
=begin
ConsoleMenu::Navigator keeps track of where the user is located in the navigation tree.
It asks questions and does other things accordingly.
The nodes of the tree represent the menu items and are denoted by symbols 
(e.g :main is the root of the tree)
=end
    attr_reader :location

    def initialize(root)
      @root = root
      @location = @root
    end

    class Node
      # Navigation happens between nodes. A node has a _question_ (of _q_type_) and possibly
      # _choices_ which to choose from (if question is of :single_choice or :multiple_choice type)
      # _action_ is called when we arrive at that node.
      class NodeError < Exception
      end   
      attr_reader :links
      
      def initialize(id, parent, question, q_type, choices={})
        @id = id
        @parent = parent        
        @question = question 
        @q_type = q_type # :free_input, :single_choice, :multiple_choice
        @choices = choices
        #
        @links = {}
        @action = :pose_question
        make_links
      end
      def make_links
        @links[:esc] = @parent
        # go through choices and make links whose key is the index of the choice
        # (converted to symbol, like so :0, :1, :2, :3)
        # @choices.each { |choice| @links[choice] }
      end
      
      def choices=(choices)
        raise NodeError, "Adding choices to not-choice-based question not allowed" \
          unless [:single_choice, :multiple_choice].include?(@q_type)
        @choices = choices
        make_links
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
=end  
  
    attr_accessor :prompt
    attr_accessor :io_stream
  
    def initialize(prompt='>', io_stream=nil)
      @prompt = prompt
      @io_stream = io_stream
      # @answer_method = answer_method
    end
  
    def take_answer
      io_stream.nil? ? gets : io_stream.gets
    end
  
    def try_again(msg)
      puts ""
      puts msg
      print @prompt + ' '
    end

    def put_question
    end
  
    def single_choice(question, answers)
      out = []
      # user-friendly indexing: starting from one instead of zero
      user_friendly_indexed_answers = []
      user_friendly_indexed_answers[0] = nil
      0.upto(answers.length-1) { |idx| user_friendly_indexed_answers[idx+1] = answers[idx] }
      1.upto(user_friendly_indexed_answers.length-1) { |idx| out << "#{idx} #{user_friendly_indexed_answers[idx]} \n" unless idx == 0 } 
      out << "#{question}\n"
      puts out.join('')
      print @prompt + ' '
      until (1...user_friendly_indexed_answers.length).include?(user_answer = gets.to_i) do
         try_again("Please choose a valid option")
       end
      puts user_friendly_indexed_answers[user_answer]
      return user_answer-1
    end
  
    def free_input(question)
      out = []
      out << "#{question}\n"
      puts out.join()
      print @prompt + ' '
      if block_given?
        until yield user_answer = take_answer do
           try_again("Input is not correct")
        end
      else
        user_answer = gets
      end
      user_answer.to_i
    end
    
  end
    
end

if __FILE__ == $0
  class ConsoleMenuTester < Test::Unit::TestCase
    def setup
      @test_prompt = '>'
      @console_ui = ConsoleMenu::UI.new(prompt=@test_prompt)
      @test_question = 'Who wins Euro\'08?'
      @test_answers = ['Netherlands', 'Portugal', 'Spain', 'Turkey', 'Germany']
      #---
      @main_node = ConsoleMenu::Navigator::Node.new(:main, nil, "please choose a group", :single_choice, ["Group selection", "Pick favorite team", "See results"])
      @group_sel_node = ConsoleMenu::Navigator::Node.new(:group_sel, @main_node, "please choose a group", :single_choice, ["Group A", "Group B", "Group C", "Group D"])
      @group_a_node = ConsoleMenu::Navigator::Node.new(:group_a, @main_node, "which team?", :single_choice, ['Switzerland', 'Portugal', 'Turkey', 'Czech Republic'])
      @group_b_node = ConsoleMenu::Navigator::Node.new(:group_b, @main_node, "which team?", :single_choice, ['Germany', 'Croatia', 'Poland', 'Austria'])
      @group_c_node = ConsoleMenu::Navigator::Node.new(:group_c, @main_node, "which team?", :single_choice, ['Netherlands', 'Italy', 'France', 'Romania'])
      @group_d_node = ConsoleMenu::Navigator::Node.new(:group_d, @main_node, "which team?", :single_choice, ['Spain', 'Russia', 'Greece', 'Sweden'])
      @navigator = ConsoleMenu::Navigator.new(@main_node)
    end
    def XXXtest_prompt
      answer = @console_ui.single_choice(@test_question, @test_answers)
      assert_equal(@test_prompt, answer[0,1])
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
      random_io = RandomIO.new(10)
      @console_ui.io_stream = random_io
      10.times { |i| assert_equal(true, (0..10).include?(@console_ui.take_answer)) }
    end
    def test_series_io
      groups = [:group_a, :group_b, :group_c, :group_d]
      series_io = SeriesIO.new(groups)
      assert_equal(:group_a, series_io.gets)
      assert_equal(:group_b, series_io.gets)
      assert_equal(:group_c, series_io.gets)
      assert_equal(:group_d, series_io.gets)
      assert_nil(series_io.gets)
    end
    def test_circular_series_io
      groups = [:group_a, :group_b, :group_c, :group_d]
      circular_series_io = SeriesIO.new(groups, true)
      groups.length.times { |n| circular_series_io.gets }
      assert_equal(:group_a, circular_series_io.gets )
    end
    # Navigator
    def test_navigator_init
      assert_equal(@main_node, @navigator.location)
    end
    
    # Node
    def test_make_links_main
      # def initialize(id, parent, question, q_type, object)    
      assert_equal({:esc => nil}, @main_node.links)
    end
    
    def test_adding_choices_to_not_choice_based_question_throws_error
      node = ConsoleMenu::Navigator::Node.new(:main, nil, "please give me a number", :free_input)
      assert_raise(ConsoleMenu::Navigator::Node::NodeError) { node.choices = [] }
      # node.choices = []
    end
    
    def test_make_links_first_level
      
    end
    
  end
  
end