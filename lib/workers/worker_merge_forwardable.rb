class WorkerMergeForwardable
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:merge_forwardable!)
  end
end





