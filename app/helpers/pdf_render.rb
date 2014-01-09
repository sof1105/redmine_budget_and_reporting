# -*- coding: utf-8 -*-

module PDFRender
  
  
  def render_pdf(project, overall_costs)
    pdf = Prawn::Document.new
    pdf = Prawn::Document.new(:page_size => 'A4')

    pdf.instance_eval do

      # project heading
      font(font.name, :size => 18, :style => :bold) do
        text project.name
      end
      
      move_down 2.mm
      font(font.name, :style => :italic) do
        text project.description
      end
      
      move_down 8.mm

      # overview
      bounding_box([0, cursor],:width => 500) do
        font(font.name, :size => 14, :style => :bold) do
          text 'Übersicht'
        end
        transparent(0.1){fill_rectangle [bounds.left-4, bounds.top+6], bounds.width+8, bounds.height+6}
      end
  
      move_down 4.mm
      
      data = [["Geplannt am #{I18n.l(overall_costs[:planned].created_on)}:",  
                  env.number_to_currency(overall_costs[:planned].budget, :delimiter => ".") ],
              ["Prognose vom #{ I18n.l(overall_costs[:forecast].planned_date)}:", 
                  env.number_to_currency(overall_costs[:forecast].budget, :delimiter => ".")],
              ["IST-Wert:", number_to_currency(overall_costs[:issues] + overall_costs[:individual], :delimiter => ".")],
              ['','('+env.number_to_currency(overall_costs[:issues], :delimiter => ".")+" Personal + "+
                      env.number_to_currency(overall_costs[:individual], :delimiter => ".")+" Einzelkosten)"]]
  
      table(data) do
        columns(0).style(:font_style => :bold)
        columns(1).style(:padding => [5,5,5,8])
        cells.style(:borders => [])
        cells[3,1].style(:font_style => :italic)
      end

      move_down 8.mm
    end
    return pdf.render
  end
end
