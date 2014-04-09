# -*- coding: utf-8 -*-

module PDFRender
  
  def render_pdf(project, o_c, c_p_i, i_c, i_c_o)
    pdf = Prawn::Document.new
    pdf = Prawn::Document.new(:page_size => 'A4')
    n2c = Proc.new {|m| view_context.number_to_currency(m, :delimiter => ".")}
    pdf.instance_eval do

      font_size 11

      # project heading --------------------------------------------------------------
      font(font.name, :size => 18, :style => :bold) do
        text project.name
      end
      
      move_down 2.mm

      # project description
      font(font.name, :style => :italic) do
        text project.description
      end
      
      move_down 8.mm

      # overview -----------------------------------------------------------------------
      bounding_box([0, cursor],:width => 500) do
        fill_color "CCCCFF"
        fill_rectangle [bounds.left-4, bounds.top+6], 500+8, 14+6
        fill_color "000000"
        font(font.name, :size => 12) do
          text 'Übersicht'
        end
      end
  
      move_down 4.mm
      
      data = [["Geplannt am #{o_c[:planned].nil? ? "" : I18n.l(o_c[:planned].created_on)}:",  
                  n2c.call(o_c[:planned].try(:budget)) ],
              ["Prognose vom #{o_c[:forecast].nil? ? "" :  I18n.l(o_c[:forecast].planned_date)}:", 
                  n2c.call(o_c[:forecast].try(:budget))],
              ["IST-Wert:", n2c.call(o_c[:issues] + o_c[:individual])],
              ['','('+n2c.call(o_c[:issues])+" Personal + "+
                      n2c.call(o_c[:individual])+" Einzelkosten)"]]
  
      table(data) do
        columns(0).style(:font_style => :bold)
        columns(1).style(:padding => [5,5,5,8]) #TODO: padding top and bottom less
        cells.style(:borders => [])
        cells[3,1].style(:font_style => :italic)
      end

      move_down 14.mm
      
      # costs for personal ----------------------------------------------------------------
      bounding_box([0, cursor],:width => 500) do
        fill_color "CCCCFF"
        fill_rectangle [bounds.left-4, bounds.top+6], 500+8, 14+6
        fill_color "000000"
        font(font.name, :size => 12) do
          text 'Personalkosten'
        end
      end

      move_down 8.mm
    
      data = []
      styling = [] # used to style each row of the table

      c_p_i.each do |version, issues|
        version_name = version.nil? ? "Ohne Meilenstein" : version.name
        total = 0
        data << [{:content => version_name, :colspan => 3}]
        styling << :heading
        issues.each do |i, c|
          name = i.subject.to_s
          hours = i.spent_hours.round(2).to_s + "/" + (i.estimated_hours.nil? ? "0.0" : i.estimated_hours.round(2).to_s) + "h"
          amount = {:content => n2c.call(c), :align => :right}
          total += c
          data << [name, hours, amount]
          styling << :issue
        end
        data << [{:content => ''},{:content => issues.sum{|i,c| i.spent_hours}.round(2).to_s + "h", :align => :right}, 
                 {:content => n2c.call(total), :align => :right}]
        styling << :sum
      end
      
      if not data.empty?
        table(data) do
          cells.style(:borders => [], :padding => [3,5])
          styling.each_index do |i|
            if styling[i] == :heading
              rows(i).style(:borders => [:top, :bottom, :left, :right], :background_color => "EEEEEE")
            elsif styling[i] == :sum
              rows(i).style(:padding => [7,5])
              cells[i,0].style(:borders => [:left, :bottom])
              cells[i,1].style(:borders => [:bottom, :top], :font_style => :bold)
              cells[i,2].style(:borders => [:right, :bottom, :top], :font_style => :bold)
            else
              cells[i,0].style(:borders => [:left], :font_style => :italic, :width => 370)
              cells[i,2].style(:borders => [:right])
            end
          end
        end
      end

      move_down 8.mm
      
      if not project.children.empty?
        data = []
        styling = []

        data << [{:content => 'Personalkosten für Unterprojekte', :colspan => 3}]
        styling << :heading
        project.children.each do |child|
          hours = child.issues.sum{|i| i.spent_hours}.round(2).to_s
          costs = child.costs_issues + child.costs_individual_items
          data << [{:content => child.name}, {:content => hours + 'h', :align => :right}, {:content => n2c.call(costs), :align => :right}]
          styling << :child
        end
        data << [{:content => ''}, {:content => project.children.sum{|c| c.issues.sum{|i| i.spent_hours}.round(2)}.to_s, :align => :right},
                 {:content => n2c.call(project.children.sum{|c| c.costs_issues + c.costs_individual_items}), :align => :right}]
        styling << :sum

        table(data) do
          cells.style(:borders => [], :padding => [3,5])
          styling.each_index do |i|
            if styling[i] == :heading
              rows(i).style(:borders => [:top, :bottom, :left, :right], :background_color => "EEEEEE")
            elsif styling[i] == :sum
              rows(i).style(:padding => [7,5])
              cells[i,0].style(:borders => [:left, :bottom])
              cells[i,1].style(:borders => [:top, :bottom], :font_style => :bold)
              cells[i,2].style(:borders => [:top, :bottom, :right], :font_style => :bold)
            else
              cells[i,0].style(:borders => [:left], :font_style => :italic, :width => 370)
              cells[i,2].style(:borders => [:right])
            end
          end
        end
      end

      move_down 14.mm

      # Costs for invididual items --------------------------------------------------------------------------
      bounding_box([0, cursor],:width => 500) do
        fill_color "CCCCFF"
        fill_rectangle [bounds.left-4, bounds.top+6], 500+8, 12+6
        fill_color "000000"
        font(font.name, :size => 12) do
          text 'Einzelkosten'
        end
      end

      move_down 5.mm
      
      data = []
      styling = []
      i_c.each do |group, list|
        list.each_with_index do |(type, info), index|
          content = [info[0], type.to_s, {:content => n2c.call(info[1]), :align => :right}]
          if index == 0
            content << {:content =>group.to_s + ":\n" + n2c.call(i_c[group].sum{|type,info| info[1]}), 
                        :align => :right,
                        :valign => :center,
                        :rowspan => list.length}
            styling << :first
          elsif index == list.length - 1
            styling << :end
          else
            styling << :normal
          end
          data << content
        end
      end
      data << [{:content => 'Sonstiges', :colspan => 2}, 
               {:content => n2c.call(i_c_o), :align => :right}, 
               {:content => "Sonstiges:\n"+n2c.call(i_c_o), :align => :right, :valign =>:center}]
      styling << :other
      if not project.children.empty?
        project.children.each do |child|
          data << [{:content => child.name, :colspan => 2},{:content => n2c.call(child.costs_individual_items), :align => :right},
                   {:content => "Unterprojekte:\n"+n2c.call(project.children.sum{|c| c.costs_individual_items}),
                    :align => :right,
                    :valign => :center,
                    :rowspan => project.children.length}]
          styling << :other
        end
      end
      data << [{:content => 'Gesamt: '+n2c.call(i_c.sum{|g,l| l.sum{|t,i| i[1]}}+i_c_o), :align => :right, :colspan => 4}]
      styling << :sum

      table(data) do
        styling.each_index do |i|
          if styling[i] == :first
            cells[i,0].style(:borders => [:left, :top], :width => 150)
            cells[i,1].style(:borders => [:top], :width => 70)
            cells[i,2].style(:borders => [:top], :width => 90)
            cells[i,3].style(:font_style => :bold, :borders => [:top, :left, :right, :bottom])
          elsif styling[i] == :end
            cells[i,0].style(:borders => [:left, :bottom], :width => 150)
            cells[i,1].style(:borders => [:bottom], :width => 70)
            cells[i,2].style(:borders => [:bottom], :width => 90)
            cells[i,3].style(:font_style => :bold, :borders => [:bottom, :left, :right])
          elsif styling[i] == :other
            cells[i,0].style(:borders => [:left, :bottom])
            cells[i,2].style(:borders => [:bottom], :width => 90)
            cells[i,3].style(:borders => [:bottom, :right, :left], :font_style => :bold)
          elsif styling[i] == :sum
            cells[i,0].style(:borders => [:left, :bottom, :top, :right], :font_style => :bold)
          else
            cells[i,0].style(:borders => [:left], :width => 150)
            cells[i,1].style(:borders => [], :width => 70)
            cells[i,2].style(:borders => [], :width => 90)
            cells[i,3].style(:font_style => :bold, :borders => [:left, :right])
          end
        end
      end
    end
    return pdf.render
  end
end
