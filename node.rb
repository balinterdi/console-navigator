class Node
  # The nodes of the tree represent the menu items and are denoted by symbols 
  # (e.g :main is the root of the tree)      
  # Navigation happens between nodes. A node has a _question_ (of _q_type_) and possibly
  # _choices_ which to choose from (if question is of :single_choice or :multiple_choice type)
  # _action_ is called when we arrive at that node.
  
  class NodeError < Exception
  end
  attr_reader :links, :action
  
  def self.link_id(value)
    value.to_s.to_sym
  end

  def self.make_sorted_hash(unsorted_hash)
    sorted_hash = Array.new
    unsorted_hash.each_pair { |k, v| sorted_hash.push({ k => v })  }
    sorted_hash.sort { |h1, h2| h1.keys()[0] <=> h2.keys()[0] }
  end
        
  def initialize(id, question, q_type, action, links)
    @id = id
    @question = question 
    @q_type = q_type # :free_input, :single_choice, :multiple_choice
    #
    @links = links
    @action = action
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
