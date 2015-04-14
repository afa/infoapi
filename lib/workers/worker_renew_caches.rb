class WorkerRenewCaches
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start renew caches for production #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.renew_caches!
    logger.info "done production #{production_id}"
  end
end
