class AaddAllowPasswordChangeToUser < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :allow_password_change, :boolean, default: false, null: false
  end
end
