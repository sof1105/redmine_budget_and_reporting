module BudgetCalculating

  def costs_for_TimeEntry(entry, salary_customfield = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    return (User.find(entry.user_id).custom_field_value(salary_customfield.id) || salary_customfield.default_value || 0.0).to_f * entry.hours
  end
  
  def costs_for_issue(issue, upto = Date.today, salary_customfield = nil)
    return 0 if issue == nil
    
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    
    is = IssueSubtotal.where("issue_id = ? AND upto <= ?",issue.id, upto).order("upto DESC").first
    total_costs = 0
    if is
      entries = TimeEntry.where("issue_id = ? AND spent_on <= ? AND spent_on > ?", issue.id, upto, is.upto)
      total_costs += is.amount
    else
      entries = TimeEntry.where("issue_id = ? AND spent_on <= ?", issue.id, upto)
    end

    entries.each do |entry|
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
    
  	total_costs = 0
  	issues = Issue.where(:project_id => project.id)
  	issues.each do |i|
      total_costs += costs_for_issue(i, upto, salary_customfield)
  	end
  	
    return total_costs
  end
end
