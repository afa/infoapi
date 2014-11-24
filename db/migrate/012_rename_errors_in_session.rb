Sequel.migration do
  change do
    rename_column :sitemap_sessions, :errors, :session_errors
  end
end
