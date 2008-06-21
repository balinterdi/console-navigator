require "test/unit"

class RandomIO < IO
=begin
Gives back a random integer between 0 and _max_+1 each time
it is read or gets is called on it (mainly for testing reasons)
it should be instantiated like this: 
  RandomIO(fake_int_for_file_handler, mode_string, max)
=end  
  def initialize(f, mode_string, max)
    super(f, mode_string)
    @max = max
  end
  def read    
    rand(@max+1)
  end
  def gets
    read
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
=end
    def initalize(tree)
      @tree = tree
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
      random_io = RandomIO.new(11, "r", 10)
      @console_ui.io_stream = random_io
      10.times { |i| assert_equal(true, (0..10).include?(@console_ui.take_answer)) }
    end
  end
  
end