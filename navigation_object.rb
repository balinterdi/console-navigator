class NavigationObject
  # This holds saved data created during navigation

  # this should be a Module(?) and thus renamed Navigable
  # the save, mark_saved and saved? instance modules
  # will be included by the model object (e.g Expense)
  # and optionally can be rewritten there       
  attr_reader :value
  
  def initialize(value)
    @value = value
    @saved = false
  end
  
  def save
    puts "I'm saved"
  end
  
  def mark_saved
    puts "I'm mark saved"
    @saved = true
  end
  
  def saved?
    @saved
  end
  
end
