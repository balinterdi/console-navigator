require "date"
require "yaml"

module ConsoleNavigator
	class NavigationObject
		
	  # This holds saved data created during navigation

	  attr_reader :value
  
	  def initialize(value)
	    @value = value
	    @saved = false
			@date = DateTime::now
	  end
  
		def serialized_form
			to_yaml
		end
		
	  def mark_saved
	    @saved = true
	  end
  
	  def saved?
	    @saved
	  end
  
	end	
end