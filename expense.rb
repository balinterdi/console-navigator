require 'test/unit'
require 'date'
require 'console_ui'

class Expense
  
  def self.make_expense(amount)
    # puts "A new expense with the amount #{amount} has been created"
    new(amount)
  end
  
  def initialize(amount, date=nil)
    @amount = amount
    @date = date.nil? ? DateTime::now : date
  end
    
end

if __FILE__ == $0:
  @console_ui = ConsoleMenu::UI.new(prompt='>')
  @expense_input_node = ConsoleMenu::Navigator::Node.new(:main, "so how much did you pay?", :free_input, Proc.new { |amount| Expense.make_expense(amount) }, {})
  @navigator = ConsoleMenu::Navigator.new(@expense_input_node, @console_ui)
  @navigator.browse
  
end