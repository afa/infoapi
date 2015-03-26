class WorkerMarkEmpty
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start mark empty for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.mark_empty!
    logger.info "done production #{production_id}"
  end
end



