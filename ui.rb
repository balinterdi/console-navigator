class UI
=begin
  ConsoleMenu::UI takes an answer from the user and returns it. Answer codes are:
  - a number if the question is of 'single choice' type
  - a string if the question is of 'free input' type (the answer can be validated and is only
  accepted once a valid answer is received from the user)
  - a list of numbers if the question is of 'multiple choice' type
  - :esc if user wants to go to the main menu
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
