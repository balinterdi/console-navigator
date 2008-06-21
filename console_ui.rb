require "test/unit"

class RandomIO < IO
  def initialize(f, mode_string, max)
    super(f, mode_string)
    @max = max
  end
  def read    
    rand(@max+1)
  end
  def gets
    rand(@max+1)
  end
end

class ConsoleUI
  
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
  
  def choose_between_answers(question, answers)
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

if __FILE__ == $0
  class ConsoleUITester < Test::Unit::TestCase
    def setup
      @test_prompt = '>'
      @console_ui = ConsoleUI.new(prompt=@test_prompt)
      @test_question = 'Who wins Euro\'08?'
      @test_answers = ['Netherlands', 'Portugal', 'Spain', 'Turkey']
    end
    def XXXtest_prompt
      answer = @console_ui.choose_between_answers(@test_question, @test_answers)
      assert_equal(@test_prompt, answer[0,1])
    end
    def XXXtest_choose_between_answers
      answer = @console_ui.choose_between_answers(@test_question, @test_answers)
      assert_equal(true, (0...@test_answers.length).include?(answer))
    end
    def XXXtest_free_input
      answer = @console_ui.free_input("how would you rate this movie? (1-5)") { |x| x = x.to_i; x >= 1 && x <= 5 }
      assert_equal(true, (1..5).include?(answer.to_i))
    end
    def test_random_io
      random_io = RandomIO.new(11, "r", 10)
      10.times { |i| puts random_io.read }
      #@console_ui.io_stream = random_io
      #100.times { |i| assert_equal(true, (0...10).include?(@console_ui.take_answer)) }
    end
  end
  
end