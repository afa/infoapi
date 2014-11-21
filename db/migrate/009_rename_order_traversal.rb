Sequel.migration do
  change do
    alter_table :rules do
      rename_column :order_traversal, :traversal_order
    end
  end
end

