module PhusionPassenger
module Railz
module FrameworkExtensions

module AnalyticsLogging
	# Instantiated from prepare_app_process in utils.rb.
	@@analytics_logger = nil
	
	def self.installable?(options)
		return options["analytics_logger"] && (
			ac_base_extension_installable? ||
			ac_rescue_extension_installable? ||
			av_benchmark_helper_extension_installable? ||
			ar_abstract_adapter_extension_installable?
		)
	end
	
	def self.ac_base_extension_installable?
		return defined?(ActionController::Base) &&
			ActionController::Base.private_method_defined?(:perform_action) &&
			ActionController::Base.method_defined?(:render)
	end
	
	def self.ac_benchmarking_extension_installable?
		return defined?(ActionController::Benchmarking::ClassMethods) &&
			ActionController::Benchmarking::ClassMethods.method_defined?(:benchmark)
	end
	
	def self.ac_rescue_extension_installable?
		return defined?(ActionController::Rescue) &&
			ActionController::Rescue.method_defined?(:rescue_action)
	end
	
	def self.av_benchmark_helper_extension_installable?
		return defined?(ActionView::Helpers::BenchmarkHelper) &&
			ActionView::Helpers::BenchmarkHelper.method_defined?(:benchmark)
	end
	
	def self.ar_abstract_adapter_extension_installable?
		return defined?(ActiveRecord::ConnectionAdapters::AbstractAdapter) &&
			ActiveRecord::ConnectionAdapters::AbstractAdapter.method_defined?(:log)
	end
	
	def self.install!(options)
		@@analytics_logger = options["analytics_logger"]
		if ac_base_extension_installable?
			require 'phusion_passenger/railz/framework_extensions/analytics_logging/ac_base_extension'
			ActionController::Base.class_eval do
				include ACBaseExtension
				alias_method_chain :perform_action, :passenger
				alias_method_chain :render, :passenger
			end
		end
		if ac_benchmarking_extension_installable?
			require 'phusion_passenger/railz/framework_extensions/analytics_logging/ac_benchmarking_extension'
			ActionController::Benchmarking::ClassMethods.class_eval do
				include ACBenchmarkingExtension
				alias_method_chain :benchmark, :passenger
			end
		end
		if ac_rescue_extension_installable?
			require 'phusion_passenger/railz/framework_extensions/analytics_logging/ac_rescue_extension'
			ActionController::Rescue.class_eval do
				include ACRescueExtension
				alias_method_chain :rescue_action, :passenger
			end
		end
		if av_benchmark_helper_extension_installable?
			require 'phusion_passenger/railz/framework_extensions/analytics_logging/av_benchmark_helper_extension'
			ActionView::Helpers::BenchmarkHelper.class_eval do
				include AVBenchmarkHelperExtension
				alias_method_chain :benchmark, :passenger
			end
		end
		if ar_abstract_adapter_extension_installable? && false
			require 'phusion_passenger/railz/framework_extensions/analytics_logging/ar_abstract_adapter_extension'
			ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
				include ARAbstractAdapterExtension
				alias_method_chain :log, :passenger
			end
		end
	end
	
	def self.continue_transaction_logging(request, category = :requests, large_messages = false)
		if request.env["PASSENGER_TXN_ID"]
			log = @@analytics_logger.continue_transaction(
				request.env["PASSENGER_GROUP_NAME"],
				request.env["PASSENGER_TXN_ID"],
				category, large_messages)
			begin
				yield log
			ensure
				log.close
			end
		end
	end
end

end
end
end