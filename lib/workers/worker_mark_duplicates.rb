class WorkerMarkDuplicates
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start mark duplicates for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.mark_duplicates!
    logger.info "done production #{production_id}"
  end
end




