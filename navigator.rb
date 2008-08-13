module ConsoleNavigator

	class Navigator
	# 	The Navigator keeps track of where the user is located in the navigation tree. It queries
	# the actual node for the quetion it has to pose and forwards the answer coming from the UI to the node
	# so the node can tell where should it go next. Somerhing along the lines of:
	# - I am at node_x
	# - question_and_valid_inputs = node_x.get_valid_options
	# - user_answer = console_ui.get_answer_from_user(question_and_valid_inputs)
	# - next_link = node_x.get_next_link(user_answer)
	# - go_to_next_link (e.g node_y)
	# 	  
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
	    @menu_nav_keys['save'] = Proc.new { save_objects }
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
	    nav_obj = do_node_action(answer)
	    @navigation_objects.push(nav_obj) unless nav_obj.nil?
	    # puts "User answer: #{answer}"
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
     
	  def save_objects
			serialized_objects = Array.new
	    @navigation_objects.each do |obj|
				serialized_objects.push(obj.serialized_form)
	      obj.mark_saved
	    end
			File.open("saved_objects.yml", "w") do |f|
				f.write(serialized_objects)
			end
	  end
     
	  def browse
	    while true
	      next_node = get_next_node
	      go_to(next_node)
	    end
	  end
  
	  def do_node_action(answer)
	    # method(@location.action).call(answer) unless @location.action.nil?
	    @location.action.call(answer) unless @location.action.nil?
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
         
	end
end