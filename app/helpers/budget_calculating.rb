module BudgetCalculating

  def costs_for_TimeEntry(entry, salary_customfield = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    return (User.find(entry.user_id).custom_field_value(salary_customfield.id) || salary_customfield.default_value || 0.0).to_f * entry.hours
  end
  
  def costs_for_issue(issue, upto = Date.today, salary_customfield = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    
    all_TimeEntries = TimeEntry.where("issue_id = ? AND spent_on <= ?", issue.id, upto)
    total_costs = 0
    all_TimeEntries.each do |entry|
      total_costs += costs_for_TimeEntry(entry, salary_customfield)
    end
    return total_costs
  end
  
  def costs_for_individualitems(project, upto = Date.today )
    return IndividualItem.until(upto, project.id).sum(:costs)
  end
  
  def costs_for_all_issues(project, upto = Date.today, salary_customfield = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    
    all_entries = TimeEntry.where("project_id = ? AND spent_on <= ?", project.id, upto)
    total_costs = 0
    all_entries.each do |entry|
      total_costs += costs_for_TimeEntry(entry, salary_customfield)
    end
    return total_costs
  end
end
