class IndividualItemAddMaterialColumn < ActiveRecord::Migration
  def change
    add_column :individual_items, :material_number, :integer
    add_column :individual_items, :material, :string
  end
end
