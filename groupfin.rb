=begin
Helps to settle financial matters among groups (families, friends, co-locataires) 
where common expenses were covered by different groups during a period
=end

require "test/unit"
require "yaml"

require "group"
require "console_ui"

class GroupFin
  
  attr_accessor :groups
  attr_accessor :db_file
  
  def initialize(*groups)
    @groups = []
    groups.each { |g| add_group(g) }
    @db_file = "expenses.yml"
  end
  
  def add_group(g)
    @groups << g
  end
  
  def get_avg
    total_exp = @groups.inject(0) { |sum, g| sum + g.total_expenses }
    total_exp / @groups.inject(0) { |sum, g| sum + g.get_weight }
  end
  
  def get_share(group)
    avg = get_avg
    avg * group.get_weight
  end
  
  def get_balance(group)
    group.total_expenses - get_share(group) 
  end
  
  def save
    File.open(@db_file, "w") do |f|
      f.write(to_yaml)
    end
  end
  
  def load
    loaded = nil
    File.open(@db_file, "r") do |f|
      loaded = YAML.load(f.read)
    end
    @groups = loaded.groups
    @db_file = loaded.db_file
  end
  
end

if __FILE__ == $0
  class GroupFinTester < Test::Unit::TestCase
    def setup
      @g_es = Group.new("spanish friends", ["juan", "manuel", "xavi"])
      @g_fr = Group.new("french friends", ["robert", "guillaume"])
      @g_hu = Group.new("hungarian friends", ["emil", "zoli", "bela", "sanya"])
      @exp_es = [8, 14]
      @exp_hu = [17, 20, 25, 6]
      @console_ui = ConsoleMenu::UI.new
    end
    
    def test_init
      gf1 = GroupFin.new
      assert_equal([], gf1.groups)
      gf2 = GroupFin.new(@g_hu, @g_fr)
      assert_equal([@g_hu, @g_fr], gf2.groups)
    end
    
    def test_add_groups
      gf = GroupFin.new
      gf.add_group(@g_es)
      assert_equal([@g_es], gf.groups)
      gf.add_group(@g_hu)
      assert_equal([@g_es, @g_hu], gf.groups)
    end
    
    def test_get_avg
      @g_es.add_expenses(*@exp_es)
      @g_hu.add_expenses(*@exp_hu)
      gf = GroupFin.new(@g_es, @g_fr, @g_hu)
      assert_equal(10, gf.get_avg)
    end
    
    def test_get_share
      gf = GroupFin.new(@g_es, @g_hu, @g_fr)
      @g_es.add_expenses(*@exp_es)
      @g_hu.add_expenses(*@exp_hu)      
      assert_equal(30, gf.get_share(@g_es))
      assert_equal(40, gf.get_share(@g_hu))
      assert_equal(20, gf.get_share(@g_fr))
    end
    
    def test_get_balance
      gf = GroupFin.new(@g_es, @g_hu, @g_fr)
      @g_es.add_expenses(*@exp_es)
      @g_hu.add_expenses(*@exp_hu)      
      assert_equal(-8, gf.get_balance(@g_es))
      assert_equal(-20, gf.get_balance(@g_fr))
      assert_equal(28, gf.get_balance(@g_hu))
    end
    
    def test_save_reload
      gf = GroupFin.new(@g_es, @g_hu, @g_fr)
      @g_es.add_expenses(*@exp_es)
      @g_hu.add_expenses(*@exp_hu)
      gf.db_file = "expenses_test.yml"
      gf.save
      gf_reloaded = GroupFin.new
      gf_reloaded.db_file = "expenses_test.yml"
      gf_reloaded.load
      assert_equal(gf.groups.collect { |g| g.name }, gf_reloaded.groups.collect { |g| g.name })
      assert_equal(gf.groups.collect { |g| g.expenses }, gf_reloaded.groups.collect { |g| g.expenses } )
#      assert_equal([@g_es, @g_hu, @g_fr], gf_reloaded.groups)
    end
    
    def XXXtest_main_menu
      random_io = RandomIO.new(10)
      @console_ui.io_stream = random_io
      #@console_ui.single_choice("fav. color?", ['blue', 'red', 'green'])
    end
  end
end