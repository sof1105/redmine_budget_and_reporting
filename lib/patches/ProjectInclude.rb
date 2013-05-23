module ProjectIncludeBudgetReporting

  def self.included(base)
    base.class_eval do 
      has_many :IndividualItem, :dependent => :destroy
      has_many :PlannedBudget, :dependent => :destroy
      has_many :VersiondateForecast, :dependent => :destroy
      has_many :ProjectbudgetForecast, :dependent => :destroy
    end
  end


end

unless Project.included_modules.include? ProjectIncludeBudgetReporting
  Project.send(:include, ProjectIncludeBudgetReporting)
end
