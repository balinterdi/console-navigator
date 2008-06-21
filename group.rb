require "test/unit"

class Group
  attr_accessor :name
  attr_accessor :members
  attr_accessor :expenses
    
  def initialize(name, members=[])
    @name = name
    @members = members
    @expenses = []
  end
  
  def add_member(new_member)
    @members << new_member unless @members.include?(new_member)
    members
  end
  
  def get_weight
    @members.length
  end
  
  def add_expenses(*expenses)
    expenses.each { |e| @expenses << e }
  end
  
  def total_expenses
    @expenses.inject(0) { |sum, e| sum + e }
  end
end

if __FILE__ == $0
  class GroupTester < Test::Unit::TestCase
    def test_name
      assert_equal("spanish friends", Group.new("spanish friends").name)
    end
    def test_members
      assert_equal(["jaime", "juanjo"], Group.new("spanish friends", ["jaime", "juanjo"]).members)
    end
    def test_add_member
      g = Group.new("spanish friends", ["jaime", "juanjo"])
      assert_equal(["jaime", "juanjo"], g.add_member("juanjo"))
      assert_equal(["jaime", "juanjo"], g.members)
      assert_equal(["jaime", "juanjo", "fernando"], g.add_member("fernando"))
      assert_equal(["jaime", "juanjo", "fernando"], g.members)
    end
    
    def test_group_weight
      g = Group.new("spanish friends", ["jaime", "juanjo", "albert"])
      assert_equal(3, g.get_weight)
      g = Group.new("french friends", ["xavier", "hichem", "lucile", "fred"])
      assert_equal(4, g.get_weight)
    end
    
    def test_add_expenses
      g = Group.new("spanish friends", ["juan", "manuel", "xavi"])
      g.add_expenses(43)
      assert_equal([43], g.expenses)
      g.add_expenses(12)
      assert_equal([43, 12], g.expenses)
      g.add_expenses(10, 30)
      assert_equal([43, 12, 10, 30], g.expenses)
    end

    def test_total_expenses
      g = Group.new("spanish friends", ["juan", "manuel", "xavi"])
      g.expenses = [43]      
      assert_equal(43, g.total_expenses)
      g.expenses = [43, 12]
      assert_equal(55, g.total_expenses)
    end
  end
end