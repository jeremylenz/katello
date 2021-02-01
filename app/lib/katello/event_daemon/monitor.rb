module Katello
  module EventDaemon
    class Monitor
      def initialize(services)
        @services = services
        @service_statuses = {}
      end

      def start
        loop do
          Rails.application.executor.wrap do
            check_services
          end
          sleep 15
        end
      end

      def check_services
        @services.each do |service_name, service_class|
          @service_statuses[service_name] = service_class.status
        rescue => error
          Rails.logger.error("Error occurred while pinging #{service_class}")
          Rails.logger.error(error.message)
          Rails.logger.error(error.backtrace.join("\n"))
        ensure
          if error || !@service_statuses.dig(service_name, :running)
            begin
              service_class.close
              service_class.run
              @service_statuses[service_name] = service_class.status
            rescue => error
              Rails.logger.error("Error occurred while starting #{service_class}")
              Rails.logger.error(error.message)
              Rails.logger.error(error.backtrace.join("\n"))
            end
          end
        end
        Rails.cache.write(
          Katello::EventDaemon::Runner::STATUS_CACHE_KEY,
          @service_statuses
        )
      end
    end
  end
end
