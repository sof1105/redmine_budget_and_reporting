module BudgetHelper

  def line_for_issue_hours_progress(issue)
    s = ""
    label =""
    
    estimated = issue.estimated_hours || 0
    actual = issue.spent_hours
    overspend = actual > estimated ? "red" : "green"
    
    label << actual.round(2).to_s << " / " << estimated.round(2).to_s << " h"
    
    progress = 0
    if estimated > 0
      progress = actual.to_f/estimated.to_f
      if progress > 1
        progress = 1
      end
    elsif estimated == 0 && actual > 0
      progress = 1
    end
    
    
    s << "<div class='bar_outer'><div class='bar_inner " << overspend
    s << "' style='width: " << (progress * 100).to_s << "%;'></div>"
    s << "<div class='bar_label'>" << label << "</div></div>"
    s.html_safe
    
  end

end
