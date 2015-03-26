class WorkerPrepareLinks
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start prepare links for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.prepare_links!
    logger.info "done production #{production_id}"
  end
end






