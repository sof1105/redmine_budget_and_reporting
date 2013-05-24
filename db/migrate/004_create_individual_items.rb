class CreateIndividualItems < ActiveRecord::Migration
  def change
    create_table :individual_items do |t|
      t.integer :receipt_number
      t.integer :cost_type
      t.string :cost_description
      t.integer :project_id
      t.string :label
      t.date :booking_date
      t.date :receipt_date
      t.decimal :amount, :precision => 8, :scale => 3
      t.decimal :costs, :precision => 10, :scale => 2
    end
  end
end
