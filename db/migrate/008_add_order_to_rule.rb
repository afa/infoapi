Sequel.migration do
  change do
    alter_table :rules do
      add_column :order_traversal, String, text: true
    end
  end
end
