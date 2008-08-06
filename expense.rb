require 'test/unit'
require 'date'

class Expense
  
  def initialize(amount, date=nil)
    @amount = amount
    @date = date.nil? ? DateTime::now : date
  end
  
end