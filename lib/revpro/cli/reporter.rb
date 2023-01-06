class Revpro::CLI::Reporter
  # REPORT_HOST = "https://res-app-web-staging-pr-39.onrender.com"
  REPORT_HOST = ENV.has_key?("REVPRO_CLI_REPORT_HOST") ? ENV["REVPRO_CLI_REPORT_HOST"] : "https://staging.res.revatu.re"
  # TELEMETRY_URL = "https://revpro-telemetry.herokuapp.com/submit"

  extend Revpro::CLI::Utils::ClassMethods

  attr_accessor :logger

  def init_logger
    if @logger.nil?
      # p "Initializing logger"
      config_directory_path = "#{ENV.has_key?("GITPOD_WORKSPACE_CONTEXT") ? "/workspace/.revpro" : "#{ENV["HOME"]}/.revpro"}"
      if !File.exists?(config_directory_path)
        FileUtils.mkdir_p(config_directory_path)
      end

      log_file_path = "#{config_directory_path}/revpro-cli.log"
      if !File.exists?(log_file_path)
        FileUtils.touch(log_file_path)
      end
      @logger = Logger.new(log_file_path)
      @logger.debug "Initializing logger in reporter... done."
    end
  end

  def initialize(event_name:, event_data: {}, event_object: {})
    init_logger
    # puts "Reporter::initialize: event_data: #{JSON.generate(event_data)}"
    @config = self.class.global_config_data
    @event_object = event_object
    @event_name = event_name
    @event_data = event_data
    send("#{@event_name}_event")
  end

  def deliver_event(payload)
    @logger.info "Delivering event to Res..."
    begin
      con = Faraday.new(REPORT_HOST)
      res = con.post("/revpro-cli-events", payload)
      # p res
      # binding.pry
      @logger.debug "Response Status: #{res.status}"
      @logger.debug "Response Body: #{res.body}" if res.status != 500
    rescue
    end
    @logger.info "Delivering event to Res... Done."
  end

  def log_event(payload)
    @logger.info "Logging event to config directory..."
    # Write a json file in .revpro for this event
    # self.class.global_config_data
    # binding.pry

    # if File.exists?()

    event_log_file_name = "event-#{@event_name}-#{Time.now.to_i}.json"
    event_log_folder = "#{self.class.global_config_dir}/.events/"

    FileUtils.mkdir_p("#{event_log_folder}")
    File.open("#{event_log_folder}#{event_log_file_name}", "w") do |f|
      f.write(payload.to_json)
    end

    @logger.info "Logging event to config directory (#{event_log_folder}#{event_log_file_name})... Done."
  end

  def payload
    @payload ||= {
      event_name: @event_name,
      event_actor: {
        github_username: @config[:github_username],
        github_email: @config[:git_email],
        revpro_email: @config[:revpro_email],
      },
      event_timestamp: Time.now,
    }
  end

  def start_event
    @logger.info "Merging start event payload..."

    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        lab_path: @event_data[:lab_path],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
        previous_lab: @event_data[:previous_lab],
        current_lab: @event_data[:current_lab],
        origin_remote: @event_data[:origin_remote],
        repo_clone_folder: @event_data[:repo_clone_folder],
        gitpod: @event_data[:gitpod],
        progress: @event_data[:progress],
        progress_test: @event_data[:progress_test],
        version: @event_data[:version],
      },
    })

    @logger.info "Merging start event payload... Done."

    # puts event_payload
    log_event(event_payload)
    deliver_event(event_payload)
  end

  def open_event
    @logger.info "Merging open event payload..."

    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        lab_path: @event_data[:lab_path],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
        repo_path: @event_data[:repo_path],
        origin_remote: @event_data[:origin_remote],
        repo_clone_folder: @event_data[:repo_clone_folder],
        gitpod: @event_data[:gitpod],
        progress: @event_data[:progress],
        progress_test: @event_data[:progress_test],
        version: @event_data[:version],
      },
    })

    @logger.info "Merging open event payload... Done."

    # puts event_payload
    log_event(event_payload)
    deliver_event(event_payload)
  end

  def test_event
    @logger.info "Merging test event payload..."

    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        lab_path: @event_data[:lab_path],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
        repo_path: @event_data[:repo_path],
        origin_remote: @event_data[:origin_remote],
        repo_clone_folder: @event_data[:repo_clone_folder],
        gitpod: @event_data[:gitpod],
        progress: @event_data[:progress],
        progress_test: @event_data[:progress_test],
        version: @event_data[:version],
      },
    })

    @logger.info "Merging test event payload... Done."

    # puts event_payload
    log_event(event_payload)
    deliver_event(event_payload)
  end

  def save_event
    @logger.info "Merging save event payload..."

    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        lab_path: @event_data[:lab_path],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
        repo_path: @event_data[:repo_path],
        origin_remote: @event_data[:origin_remote],
        repo_clone_folder: @event_data[:repo_clone_folder],
        gitpod: @event_data[:gitpod],
        progress: @event_data[:progress],
        progress_test: @event_data[:progress_test],
        version: @event_data[:version],
      },
    })

    @logger.info "Merging save event payload... Done."

    # puts event_payload
    log_event(event_payload)
    deliver_event(event_payload)
  end

  def submit_event
    @logger.info "Merging submit event payload..."

    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
        repo_path: @event_data[:repo_path],
        previous_lab: @event_data[:previous_lab],
        current_lab: @event_data[:current_lab],
        origin_remote: @event_data[:origin_remote],
        repo_clone_folder: @event_data[:repo_clone_folder],
        gitpod: @event_data[:gitpod],
        progress: @event_data[:progress],
        progress_test: @event_data[:progress_test],
        version: @event_data[:version],
      },
    })

    @logger.info "Merging submit event payload... Done."

    # Sends the payload to Res
    # From RES
    # Admin will see that there is a submission for this lab to review.
    # They will click start review
    # Res will automate opening up a pull request from the github_username of the student and their lab branch to the canonical repo
    # It will then open the pull request URL in their browser
    # Github actions will run the test suite for the students lab branch within the PR interface
    # they admin will then go to the "Start Review" for the PR
    # they can review the code and the test run results
    # by approving the PR, they are grading the lab as a pass
    # by rejecting the PR, they are grading the lab as a fail
    # The PR is only closed on a passing grade but never merged
    # if they failed, what's the workflow for resubmitting / re-reviewing...

    # TODO
    # [x] have CLI submit payload to Res
    # [x] configure res to receive this payload and setup the submission / start review
    # [] upon start review
    # open the PR
    # [] configure Res to listen to payloads from Github
    # [] finish the workflow
    # TELEMETRY_URL = "https://revpro-telemetry.herokuapp.com/submit"
    log_event(event_payload)
    deliver_event(event_payload)
  end
end
