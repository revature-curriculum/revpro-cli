module Revpro::CLI::Codelabs
  class RevproMultiple < Revpro::CLI::Codelab
    # REPORT_HOST = "http://localhost:3000"
    REPORT_HOST = ENV.has_key?("REVPRO_CLI_REPORT_HOST") ? ENV["REVPRO_CLI_REPORT_HOST"] : "https://res.revatu.re"

    attr_accessor :path, :manifest_path, :logger
    attr_reader :manifest, :metadata, :lab_name, :source, :version

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
        @logger.debug "Initializing logger... done."
      end
    end

    def self.clone(lab_url, lab_path)
      config_directory_path = "#{ENV.has_key?("GITPOD_WORKSPACE_CONTEXT") ? "/workspace/.revpro" : "#{ENV["HOME"]}/.revpro"}"
      if !File.exists?(config_directory_path)
        FileUtils.mkdir_p(config_directory_path)
      end

      log_file_path = "#{config_directory_path}/revpro-cli.log"
      if !File.exists?(log_file_path)
        FileUtils.touch(log_file_path)
      end
      clone_logger = Logger.new(log_file_path)
      clone_logger.info "Running start command... (self.clone with lab_url: #{lab_url}, lab_path: #{lab_path})"

      lab_path = File.basename(lab_url) if lab_path.empty?
      lab_url = "https://github.com/#{lab_url}" unless lab_url =~ URI::regexp || lab_url.start_with?("git@github.com")
      lab_address = Git::URL.parse(lab_url)
      git_owner_username = lab_url.split("/")[-2]
      git_repo_name = lab_url.split("/")[-1].gsub(".git", "")

      lab_url = "https://github.com#{lab_address.path}" if lab_address.scheme != "https"

      # Check Github URL
      if !lab_url.start_with?("https://github.com") || !(lab_address.path.end_with?("pep-labs") || lab_address.path.end_with?("pep-labs.git")) || lab_address.path.split("/").count != 3
        puts "#{"Command failed.".colorize(:white).colorize(:background => :red)}\nMake sure the link you copied looks like this: #{"https://github.com/username/pep-labs.git".colorize(:blue)}\n\nTo understand where to find the correct link to copy, check the instructions here:\n#{"https://revatu.re/pep-cliurl-issue-guide".colorize(:blue)}\n\n"

        clone_logger.debug "Command failed. Incorrect GitHub repo link."
        exit
      end

      clone_logger.debug "lab_url is correct."

      if git_owner_username.eql?("revature-curriculum")
        puts "#{"Command failed.".colorize(:white).colorize(:background => :red)}\nYou copied the link of an incorrect repository. Make sure that the link you copy is for the \"pep-labs\" repository.\n\nTo understand where to find the correct link to copy, check the instructions here:\n#{"https://revatu.re/pep-cliurl-issue-guide".colorize(:blue)}\n\n"

        clone_logger.debug "Command failed. Incorrect GitHub repo link. Used the upstream repo URL."
        exit
      end

      clone_logger.debug "git_owner_username is correct."

      if lab_path.empty? || !lab_path.eql?("pep-labs")
        puts "#{"Command failed.".colorize(:white).colorize(:background => :red)}\nMake sure the complete command looks like this with the folder name mentioned as #{"pep-labs".colorize(:blue)}:\n\n#{"revpro start https://github.com/username/pep-labs.git pep-labs"}\n\n"

        clone_logger.debug "Command failed. Clone folder name not given."
        exit
      end

      clone_logger.debug "lab_path is correct."

      gitpod_workspace_context, gitpod_workspace = {}, {}
      if ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
        gitpod_workspace_context = JSON.parse(ENV["GITPOD_WORKSPACE_CONTEXT"])
        gitpod_workspace = { workspace_id: ENV["GITPOD_WORKSPACE_ID"], workspace_url: ENV["GITPOD_WORKSPACE_URL"], repo_root: ENV["GITPOD_REPO_ROOT"], git_user_email: ENV["GITPOD_GIT_USER_EMAIL"], git_user_name: ENV["GITPOD_GIT_USER_NAME"] }
        home_dir = "/workspace"
      else
        home_dir = ENV["HOME"]
      end

      clone_logger.debug "home_dir: #{home_dir}"

      if File.exists?(lab_path) || File.exists?("/#{home_dir}/.revpro/config.yml")
        config_file = YAML.load_file("/#{home_dir}/.revpro/config.yml")
        puts "#{"Lab setup already completed. Please do not run revpro start more than once.".colorize(:white).colorize(:background => :red)}\n\n"

        clone_logger.fatal "Lab setup already completed."
        return
      else
        puts "Cloning lab from #{lab_url} to #{lab_path}"
        clone_logger.debug "Cloning lab from #{lab_url} to #{lab_path}"
        git_repo = Git::clone(lab_url, lab_path)
      end

      clone_logger.info "repo has been cloned."

      lab_path = File.expand_path(lab_path.strip)
      git_repo ||= Git.open(lab_path)

      manifest = YAML.load_file("#{lab_path}/.codelab/manifest.yml") if File.exists?("#{lab_path}/.codelab/manifest.yml")

      clone_logger.info "manifest located and loaded."

      origin_remote = git_repo.remotes.detect { |r| r.name == "origin" }

      config_path = "/#{home_dir}/.revpro/config.yml"
      FileUtils.mkdir_p("#{home_dir}/.revpro")

      if !File.exists?(config_path)
        File.open(config_path, "w") do |f|
          f.write({
            projects: {},
          }.to_yaml)

          clone_logger.debug "Config file updated."
        end
      end

      clone_logger.info "config file created and loaded."

      config_data = {
        github_username: git_owner_username,
        git_name: git_repo.config["user.name"],
        git_email: git_repo.config["user.email"],
        gitpod: { gitpod_workspace_context: gitpod_workspace_context, gitpod_workspace: gitpod_workspace },
        projects: {},
      }.merge(YAML.load_file(config_path))

      config_data[:projects][git_repo_name] = {
        repo_path: File.expand_path(lab_path),
        origin_remote: origin_remote.url,
        repo_clone_folder: lab_path,
      }
      config_data[:current_project] = git_repo_name

      clone_logger.info "Gathering tests and test cases."
      # Getting number of tests
      out_num_tests, err_num_tests, st_num_tests = Open3.capture3("find " + File.expand_path(lab_path) + ' -name "*Test.java" -exec grep -E "@Test$|public @Test" {} \; | wc -l')

      count_tests_total = 0
      if st_num_tests.success?
        count_tests_total = out_num_tests.strip.to_i
      end

      # Compiling per-test data
      progress_test = Hash.new
      progress_test[:count_tests_total] = count_tests_total
      progress_test[:count_tests_passed] = 0

      manifest[:labs].each do |lab|
        lab_name_key = lab.keys[0]
        progress_test[lab_name_key] = Hash.new

        out_num_tests_lab, err_num_tests_lab, st_num_tests_lab = Open3.capture3("find " + "#{File.expand_path(lab_path)}/#{lab_name_key}" + ' -name "*Test.java" -exec grep -E "@Test$|public @Test" {} \; | wc -l')

        progress_test[lab_name_key][:Week] = lab["Week"]
        progress_test[lab_name_key][:Order] = lab["Order"]
        progress_test[lab_name_key][:Type] = lab["Type"]
        progress_test[lab_name_key][:count_tests] = st_num_tests_lab.success? ? out_num_tests_lab.strip.to_i : 0
        progress_test[lab_name_key][:count_tests_passed] = 0
        progress_test[lab_name_key][:tests] = Hash.new

        out_tests_lab, err_tests_lab, st_tests_lab = Open3.capture3("find " + "#{File.expand_path(lab_path)}/#{lab_name_key}" + ' -name "*Test.java" -exec grep -E -A 4 "@Test$|public @Test" {} \; | grep -oP \'(?<=void ).*?(?=\()\'')

        if st_tests_lab.success?
          test_names = out_tests_lab.split("\n")
          test_names.each do |test_name|
            progress_test[lab_name_key][:tests][test_name] = 0
          end
        end
      end

      metadata_path = "#{lab_path}/.codelab/revpro.yml"

      metadata = {
        lab_name: git_repo_name,
        repo_path: File.expand_path(lab_path),
        previous_lab: manifest["start_lab"],
        current_lab: manifest["start_lab"],
        origin_remote: origin_remote.url,
        repo_clone_folder: lab_path,
        github_username: git_owner_username,
        git_name: git_repo.config["user.name"],
        git_email: git_repo.config["user.email"],
        gitpod: { gitpod_workspace_context: gitpod_workspace_context, gitpod_workspace: gitpod_workspace },
        progress: {
          count_labs_total: manifest[:labs].length,
          count_labs_passed: 0,
          count_tests_total: count_tests_total,
          count_tests_passed: 0,
        },
        progress_test: progress_test,
      }

      clone_logger.debug "Total #labs: #{manifest[:labs].length}"
      clone_logger.debug "Total #tests: #{count_tests_total}"

      clone_logger.info "Gathering tests and test cases. Done."
      clone_logger.info "metadata generated."

      File.open(metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end

      clone_logger.info "Created metadata file."

      File.open(config_path, "w") do |f|
        f.write(config_data.to_yaml)
      end

      clone_logger.info "Updated config file."

      codelab = new(lab_path: lab_path, git_repo: git_repo, command: "start")

      puts "\n#{"Labs set up and account connected to RevaturePro successfully. Happy Coding!".colorize(:white).colorize(:background => :green)}\n"

      puts "\nNext step, type the following command to start working on a lab:\nrevpro open <Lab Name>\n\nExample:\n#{"revpro open Start"}\n\n"

      codelab.report_start(lab_path)

      clone_logger.info "Running start command... Done."

      codelab.cd_into_lab(lab_path)
    end

    def self.open(lab_path: nil, git_repo: nil)
      new(lab_path: lab_path, git_repo: git_repo, command: "open").tap do |codelab|
        codelab.open
      end
    end

    def initialize(lab_path:, manifest_path: nil, git_repo: nil, command: nil)
      init_logger
      @logger.debug "Running initialize()"

      #puts "Global config data missing" and exit unless global_config_data
      if !self.class.global_config_exists?
        puts "#{"Labs not set up yet!".colorize(:white).colorize(:background => :red)}"
        puts "Please run the revpro start command. See instructions at #{"https://revatu.re/revature-pt-student-guide".colorize(:blue)}\n\n"

        @logger.fatal "Labs not set up yet. Exiting."
        exit
      end

      @logger.info "Global config exists. Continuing."

      global_config_data = self.class.global_config_data
      configure_revpro_email

      @logger.info "revpro email configured."
      # puts Dir.pwd
      # puts global_config_data[:current_project]
      # puts lab_path

      if Dir.pwd.include?(global_config_data[:current_project]) || lab_path.include?(global_config_data[:current_project])
        set_global_vars(global_config_data, lab_path, git_repo, command)
      else
        cd_into_lab(global_config_data[:projects][global_config_data[:current_project]][:repo_path])
        set_global_vars(global_config_data, lab_path, git_repo, command)
      end

      @logger.info "initialize completed."
    end

    def set_global_vars(global_config_data, lab_path, git_repo, command)
      @logger.debug "Setting global vars..."

      @monorepo_root_path = global_config_data[:projects][global_config_data[:current_project]][:repo_path]
      @repo = git_repo || Git.open(@monorepo_root_path)
      @manifest_path = "#{@monorepo_root_path}/.codelab/manifest.yml"
      @metadata_path = @manifest_path.gsub("manifest.yml", "#{manifest[:template]}")

      version_file_path = "#{@monorepo_root_path.gsub(global_config_data[:current_project], "")}/.version"
      version_string = "1.0.0"
      if File.exists?(version_file_path)
        version_file = File.open("#{@monorepo_root_path.gsub(global_config_data[:current_project], "")}/.version")
        version_string = version_file.read
        if version_string.empty?
          version_string = "1.0.0"
        end
        version_file.close
      end
      @version = version_string

      @lab_name = lab_path.split("/")[-1]
      if command.eql?("open")
        lab_name_from_lab_path = lab_path.split("/")[-1]
        actual_lab = lookup_lab?(lab_name_from_lab_path)

        if actual_lab == nil
          puts "#{"Cannot find that lab.".colorize(:white).colorize(:background => :red)}"
          puts "See instructions at #{"https://revatu.re/revature-pt-student-guide".colorize(:blue)}\n\n"
          @logger.fatal "revpro open: Couldn't find lab: #{lab_name_from_lab_path}. Exiting..."
          exit
        end

        @lab_name = actual_lab.keys[0]
      end
      @lab_path = "#{@monorepo_root_path}/#{@lab_name}"

      @logger.info "Setting global vars... Done."
    end

    def configure_revpro_email
      if !self.class.global_config_data[:revpro_email]
        @logger.info "Email not configured."
        RevproMultiple.email(@logger)
      end
    end

    # `revpro open` command.
    def open
      configure_revpro_email
      #puts "Opening #{@lab_name} in #{@monorepo_root_path}"
      # print out a message in green color
      if !check_labs_exist?
        #puts RevproMultiple.global_config_data[:projects][RevproMultiple.global_config_data[:current_project]][:repo_path]
        if Dir.exists?("#{RevproMultiple.global_config_data[:projects][RevproMultiple.global_config_data[:current_project]][:repo_path]}/Start")
          puts "#{"Cannot find that lab.".colorize(:white).colorize(:background => :red)}"
          puts "See instructions at #{"https://revatu.re/revature-pt-student-guide".colorize(:blue)}\n\n"
          exit
        end
        puts "#{"Please run revpro start to set up your labs.".colorize(:white).colorize(:background => :red)}"
        puts "See instructions at #{"https://revatu.re/revature-pt-student-guide".colorize(:blue)}\n\n"
        @logger.error "Labs not setup yet."
        return
      else
        if @monorepo_root_path
          @logger.debug "At root path #{@monorepo_root_path}"
          puts "#{"Successfully opened lab: #{@lab_name}".colorize(:white).colorize(:background => :green)}\n\n"
        else
          @logger.debug "Not at root path #{Dir.pwd}"
          cd_into_lab(@manifest[:repo_path])
        end
      end
      save_and_commit
      checkout_lab_branch(@lab_name)
      update_manifest_current_lab(@lab_path)
      report_open(@lab_path)
      open_editor(@lab_path)
      cd_into_lab(@lab_path)
    end

    # `revpro submit` command.
    def submit
      @logger.info "Running submit command..."

      configure_revpro_email

      if !Dir.pwd.eql?(File.expand_path(@lab_path))
        puts "#{"You are not in a lab.".colorize(:white).colorize(:background => :red)}\n"
        puts "You will not be able to use revpro test, save or submit unless you open a lab."
        puts "\nUse the following command to start working on a lab:\nrevpro open <Lab Name>\n\nExample:\n#{"revpro open Start"}\n\n"

        @logger.fatal "Not in a lab (pwd: #{Dir.pwd}). Exiting."
        exit
      end

      pom_path = "#{@lab_path}/pom.xml"

      # puts "#{File.exists?(pom_path)}"

      if File.exists?(pom_path)
        @logger.debug "pom file found at #{pom_path}."

        #want to hide this output
        test_1 = `mvn test -q -f #{pom_path} > #{File.expand_path(@lab_path)}/test-output.sh`
        test_2 = `bash #{@monorepo_root_path.chomp(self.class.global_config_data[:current_project])}/parse-test-output.sh #{File.expand_path(@lab_path)}/test-output.sh`

        puts test_1
        puts test_2
        @logger.debug test_1
        @logger.debug test_2

        # We are assuming there is only one Test file.
        possible_test_files = Dir.children("#{@lab_path}/target/surefire-reports/").filter { |file_name| file_name.end_with?(".xml") }
        surefire_results_path = "#{@lab_path}/target/surefire-reports/#{possible_test_files[0]}"

        if !File.exists?(surefire_results_path)
          puts "No SureFire results file found at #{surefire_results_path}"
          @logger.fatal "No SureFire results file found at #{surefire_results_path}. Exiting."
          return
        end

        @logger.debug "SureFire results file found at #{surefire_results_path}"

        surefire_results_file = File.open(surefire_results_path)
        parsed_results = Nokogiri::XML(surefire_results_file)
        number_of_tests = parsed_results.xpath("//testsuite")[0]["tests"].to_i
        number_of_failures = parsed_results.xpath("//testsuite")[0]["failures"].to_i
        number_of_errors = parsed_results.xpath("//testsuite")[0]["errors"].to_i
        total_failures = number_of_errors + number_of_failures
        parsed_testcases = parsed_results.xpath("//testcase")
        test_results = Hash.new
        parsed_testcases.each do |test|
          is_errored = test.xpath("child::failure").empty? && test.xpath("child::error").empty?
          test_results[test["name"]] = is_errored ? 1 : 0
        end

        save_progress(number_of_tests, total_failures, test_results)

        if total_failures > 0
          puts "Total tests: #{number_of_tests}"
          puts "#{"Tests failed: #{total_failures}".colorize(:white).colorize(:background => :red)}"
          puts "#{"Tests passed: #{number_of_tests - total_failures}".colorize(:white).colorize(:background => :green)}"
          puts "#{"Submitting, but the lab status will not be marked as complete because of failing tests.".colorize(:white).colorize(:background => :red)}\n\nIf you need to review detailed test results, then you can use the #{"mvn test".colorize(:blue)} command.\n\n"

          @logger.debug "Total tests: #{number_of_tests}"
          @logger.debug "Tests failed: #{total_failures}"
          @logger.debug "Tests passed: #{number_of_tests - total_failures}"
        else
          puts "#{"All tests passed!".colorize(:white).colorize(:background => :green)}\n\n"
          @logger.debug "Total tests: #{number_of_tests}"
          @logger.debug "All tests passed!"
        end
      else
        puts "No lab found at #{@lab_path}"
        # puts you are not in a lab in white and red background
        puts "#{"You are not in a lab.".colorize(:white).colorize(:background => :red)}\n"
        puts "You will not be able to use revpro test, save or submit unless you open a lab."
        puts "\nUse the following command to start working on a lab:\nrevpro open <Lab Name>\n\nExample:\n#{"revpro open Start"}\n\n"

        @logger.fatal "No lab found at #{@lab_path}. Exiting."
      end

      # https://github.com/aviflombaum/pep-labs/compare/Intro_To_Java/If_Statement?expand=1
      # https://github.com/revature-curriculum/pep-labs/compare/main...aviflombaum:pep-labs:Intro_To_Java/Start?expand=1
      puts "Submitting lab: #{@lab_name}"
      save_and_commit
      puts "#{"Successfully submitted lab: #{@lab_name}".colorize(:white).colorize(:background => :green)}\n\n"
      puts "You can view your progress at https://res.revatu.re/progress\n\n"
      report_submit(@lab_path)

      @logger.info "Running submit command... Done."
    end

    def update_manifest_current_lab(lab_path)
      @logger.info "Updating current lab in manifest..."
      metadata[:previous_lab] = metadata[:current_lab]
      metadata[:current_lab] = lab_path.split("/")[-1]
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
        @logger.debug "metadata updated with current lab."
      end
      @logger.info "Updating current lab in manifest... Done."
    end

    # `revpro save` command.
    def save_command
      @logger.info "Running save_command..."
      configure_revpro_email
      if !Dir.pwd.eql?(File.expand_path(@lab_path))
        puts "#{"You are not in a lab.".colorize(:white).colorize(:background => :red)}\n"
        puts "You will not be able to use revpro test, save or submit unless you open a lab."
        puts "\nUse the following command to start working on a lab:\nrevpro open <Lab Name>\n\nExample:\n#{"revpro open Start"}\n\n"
        @logger.debug "Lab not opened. Exiting."
        exit
      end
      puts "Saving lab: #{@lab_name}"
      save_and_commit
      report_save(@lab_path)
      puts "#{"Saved lab: #{@lab_name}".colorize(:white).colorize(:background => :green)}\n\n"
      @logger.info "Running save_command... Done."
    end

    def save_and_commit
      @logger.info "Running save_and_commit"

      sac_logger = @logger
      sac_cmds = TTY::Command.new(output: sac_logger)

      result = sac_cmds.run("git add -A")
      if result.failure?
        @logger.debug result.out
        @logger.error result.err
        p result.out
        p result.err
        exit
      end

      commit_message = "\"Saved progress on #{@lab_name} #{Time.now}\""
      result = sac_cmds.run("git commit -m #{commit_message} --allow-empty")
      if result.failure?
        sac_logger.debug result.out
        sac_logger.error result.err
        p result.out
        p result.err
        exit
      end

      result = sac_cmds.run("git fetch")
      if result.failure?
        sac_logger.debug result.out
        sac_logger.error result.err
        p result.out
        p result.err
        exit
      end

      result = sac_cmds.run("git merge origin/#{repo.current_branch} 2>&1")
      if result.failure?
        sac_logger.debug result.out
        sac_logger.error result.err
        p result.out
        p result.err
        exit
      end

      result = sac_cmds.run("git push origin #{repo.current_branch} 2>&1")
      if result.failure?
        sac_logger.debug result.out
        sac_logger.error result.err
        p result.out
        p result.err
        exit
      end
      sac_logger.info "save_and_commit successful"
    end

    def info
      # puts @manifest.class
      # puts @manifest[:labs].class
      # puts @manifest[:labs][0].class
      # @manifest[:labs].each do |lab|
      #   puts lab["Week"]
      #   puts lab["Order"]
      #   puts lab["Type"]
      # end
      # lab_names
    end

    # `revpro email` command: allows user to set their revpro email again.
    def self.email(logger)
      logger.info "Configuring email..."
      if ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
        home_dir = "/workspace"
      else
        home_dir = ENV["HOME"]
      end

      config_path = "/#{home_dir}/.revpro/config.yml"

      config_data = YAML.load_file(config_path)

      logger.info "Config file loaded."

      if !config_data[:revpro_email].nil? && !config_data[:revpro_email].empty?
        puts "The Revpro email configured currently is #{config_data[:revpro_email]}. Press Ctrl + C if you want to keep this email."
        logger.info "Email already configured. Proceeding..."
      end

      is_valid_email = false
      while is_valid_email == false
        puts "Please enter your RevaturePro email address to track your progress:"
        config_data[:revpro_email] = STDIN.gets.strip

        logger.debug "Entered email is: #{config_data[:revpro_email]}"

        begin
          con = Faraday.new(REPORT_HOST)
          res = con.post("/check-revpro-email", "revpro_email=#{config_data[:revpro_email]}&project_name=#{config_data[:current_project]}")
          if res.status == 200
            is_valid_email = true
            puts "Email validated and saved successfully!".colorize(:white).colorize(:background => :green)
            logger.info "Email validated and saved successfully!"
          else
            puts "#{"Email address not found! You can find your RevaturePro email address here:".colorize(:white).colorize(:background => :red)}\n#{"https://app.revature.com/profile".colorize(:blue)}\n"
            logger.debug "Incorrect email address. Prompting user again..."
          end
          # binding.pry
        rescue
        end
      end
      File.open(config_path, "w") do |f|
        f.write(config_data.to_yaml)
      end

      logger.debug "Config file updated."
      logger.info "Configuring email... Done."
    end

    def show_progress
    end

    def save_progress(number_of_tests, number_of_failures, test_results)
      @logger.info "Running save_progress..."

      # Overall Progress
      # Individual Lab Progress
      # Based on Number of Tests passed
      # Progress in terms of number of tests vs number of labs

      # Get current lab
      current_lab = metadata[:current_lab]
      @logger.debug "current_lab: #{current_lab}"

      # Update progress_test -> current_lab -> count_tests_passed
      metadata[:progress_test][current_lab][:count_tests_passed] = number_of_tests - number_of_failures
      @logger.debug "Updated no. of tests passed in metadata."

      # Update progress_test -> current_lab -> individual test results
      test_results.each do |result|
        # p "result[0]: #{result[0]}, result[1]: #{result[1]}"
        metadata[:progress_test][current_lab][:tests][result[0]] = result[1]
      end
      @logger.debug "Updated individual test case result in metadata."

      num_tests_passed = 0
      num_labs_passed = 0

      metadata[:progress_test].each do |test_lab_obj|
        if !test_lab_obj[0].eql?(:count_tests_total) && !test_lab_obj[0].eql?(:count_tests_passed)
          # puts "test_lab_obj: #{test_lab_obj}"
          num_tests_passed += test_lab_obj[1][:count_tests_passed]
          num_labs_passed += 1 if test_lab_obj[1][:count_tests_passed] == test_lab_obj[1][:count_tests] && test_lab_obj[1][:count_tests] > 0
          # puts "lab_passed: #{test_lab_obj[1][:count_tests_passed] == test_lab_obj[1][:count_tests] && test_lab_obj[1][:count_tests] > 0}"
        end
      end

      # Update progress_test -> count_tests_passed
      metadata[:progress_test][:count_tests_passed] = num_tests_passed
      @logger.debug "Updated no. of tests passed in test progress in metadata."

      # Update progress -> count_tests_passed
      metadata[:progress][:count_tests_passed] = num_tests_passed
      @logger.debug "Updated no. of tests passed in overall progress in metadata."

      # Update progress -> count_labs_passed
      metadata[:progress][:count_labs_passed] = num_labs_passed
      @logger.debug "Updated no. of labs passed in overall progress in metadata."

      # Save metadata file
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
        @logger.debug "metadata file updated with progress data."
      end

      @logger.info "Running save_progress... Done."
    end

    def checkout_lab_branch(branch_name)
      @logger.info "Running checkout_lab_branch(#{branch_name})"

      @logger.debug "Checking out lab branch #{branch_name}"
      @logger.debug "1. Checking out main from #{repo.current_branch}"
      repo.checkout("main")

      if repo.branches.local.detect { |b| b.name == branch_name }
        @logger.debug "2. Found local branch, checking out #{branch_name} from #{repo.current_branch}"
        repo.checkout(branch_name)

        @logger.debug "3. Pulling from origin/#{branch_name}"
        `git pull -X theirs --ff-only 2>&1`

        @logger.debug "4. Merging from origin/#{branch_name}"
        out, err = `git merge -X theirs origin/#{branch_name} 2>&1`
        @logger.debug out
        @logger.error err

        @logger.debug "5. Pushing to origin/#{branch_name}"
        repo.push("origin", branch_name)
      else
        if repo.branches.remote.detect { |b| b.name == branch_name }
          @logger.debug "2. Found remote branch, checking out #{branch_name} from #{repo.current_branch}"
          repo.branch(branch_name).checkout

          @logger.debug "3. Setting upstream to origin/#{branch_name}"
          `git branch --set-upstream-to=origin/#{branch_name} #{branch_name} 2>&1`

          @logger.debug "4. Pulling from origin/#{branch_name}"
          out, err = `git pull -X theirs --ff-only 2>&1`
          @logger.debug out
          @logger.error err
          @logger.debug "4. Pulling from origin/#{branch_name}"

          @logger.debug "5. Merging from origin/#{branch_name}"
          out, err = `git merge -X theirs origin/#{branch_name} 2>&1`
          @logger.debug out
          @logger.error err
          @logger.debug "5. Merging from origin/#{branch_name}... Done."

          @logger.debug "6. Pushing to origin/#{branch_name}"
          repo.push("origin", branch_name)
          @logger.debug "6. Pushing to origin/#{branch_name}... Done."
        else
          @logger.debug "2. Creating new branch #{branch_name} from #{repo.current_branch}"
          repo.branch(branch_name).checkout

          @logger.debug "3. Pushing new branch to origin/#{branch_name}"
          repo.push("origin", branch_name)

          @logger.debug "4. Setting upstream to origin/#{branch_name}"
          `git branch --set-upstream-to=origin/#{branch_name} #{branch_name} 2>&1`
        end
      end

      @logger.info "Running checkout_lab_branch(#{branch_name})... Done."
    end

    def open_editor(path)
      @logger.info "Opening editor at #{path}... Done."
      shell_command = ENV["SHELL"] || "bash"
      system("#{ENV["EDITOR"]} #{File.expand_path(path)}")
    end

    def cd_into_lab(path)
      @logger.info "cd_into_lab(#{path})... Done."
      shell_command = ENV["SHELL"] || "/usr/bin/bash"
      exec "ruby -e \"Dir.chdir('#{File.expand_path(path)}'); exec '#{shell_command}'\""
    end

    def puts_in_echo(message)
      a = "echo #{message}"
      Open3.popen3(a) do |stdin, stdout, stderr|
        puts stdout.read
      end
    end

    def metadata
      @metadata ||= YAML.load_file(@metadata_path)
    end

    def manifest
      @manifest ||= YAML.load_file(@manifest_path)
    end

    def check_labs_exist?
      return Dir.exist?(@lab_path)
    end

    def lookup_lab?(supplied_lab_name)
      # puts @lab_name
      matched_lab = @manifest[:labs].filter { |lab| lab.keys[0].downcase.eql?(supplied_lab_name.downcase) }
      return matched_lab.length > 0 ? matched_lab[0] : nil
    end

    # def config_file_path
    #   if ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
    #     home_dir = "/workspace"
    #   else
    #     home_dir = ENV["HOME"]
    #   end

    #   @config_file_path = "/#{home_dir}/.revpro/config.yml"
    # end

    # def config
    #   @config ||= YAML.load_file(@config_file_path)
    # end

    def repo(path = @path)
      @repo ||= Git.open(@path)
    end

    def test
      @logger.info "Running test command..."

      configure_revpro_email
      #puts "Testing #{@lab_name} in #{@monorepo_root_path}"
      puts "Starting test for lab: #{@lab_name}"
      @logger.debug "Starting test for lab: #{@lab_name}"

      pom_path = "#{@lab_path}/pom.xml"

      # puts "#{File.exists?(pom_path)}"

      if File.exists?(pom_path)
        @logger.debug "Found pom file at #{pom_path}"

        #want to hide this output
        # puts "chomping: #{@monorepo_root_path.chomp(self.class.global_config_data[:current_project])}"
        test_1 = `mvn test -q -f #{pom_path} > #{File.expand_path(@lab_path)}/test-output.sh`
        test_2 = `bash #{@monorepo_root_path.chomp(self.class.global_config_data[:current_project])}/parse-test-output.sh #{File.expand_path(@lab_path)}/test-output.sh`

        puts test_1
        puts test_2
        @logger.debug test_1
        @logger.debug test_2

        # We are assuming there is only one Test file.
        possible_test_files = Dir.children("#{@lab_path}/target/surefire-reports/").filter { |file_name| file_name.end_with?(".xml") }
        surefire_results_path = "#{@lab_path}/target/surefire-reports/#{possible_test_files[0]}"

        if !File.exists?(surefire_results_path)
          puts "No SureFire results file found at #{surefire_results_path}"
          @logger.fatal "No SureFire results file found at #{surefire_results_path}. Exiting."
          return
        end

        @logger.debug "SureFire results file found at #{surefire_results_path}"

        surefire_results_file = File.open(surefire_results_path)
        parsed_results = Nokogiri::XML(surefire_results_file)
        number_of_tests = parsed_results.xpath("//testsuite")[0]["tests"].to_i
        number_of_failures = parsed_results.xpath("//testsuite")[0]["failures"].to_i
        number_of_errors = parsed_results.xpath("//testsuite")[0]["errors"].to_i
        total_failures = number_of_errors + number_of_failures
        parsed_testcases = parsed_results.xpath("//testcase")
        test_results = Hash.new
        parsed_testcases.each do |test|
          test_results[test["name"]] = test.xpath("child::failure").empty? && test.xpath("child::error").empty? ? 1 : 0
        end

        save_progress(number_of_tests, total_failures, test_results)
        report_test(@lab_path)

        if total_failures > 0
          puts "Total tests: #{number_of_tests}"
          puts "#{"Tests failed: #{total_failures}".colorize(:white).colorize(:background => :red)}"
          puts "#{"Tests passed: #{number_of_tests - total_failures}".colorize(:white).colorize(:background => :green)}"
          puts "Please correct the code and try again.\n\nIf you need to review detailed test results, then you can use the #{"mvn test".colorize(:blue)} command.\n\n"

          @logger.debug "Total tests: #{number_of_tests}"
          @logger.debug "Tests failed: #{total_failures}"
          @logger.debug "Tests passed: #{number_of_tests - total_failures}"
        else
          puts "#{"All tests passed!".colorize(:white).colorize(:background => :green)}\n\n"
          @logger.debug "Total tests: #{number_of_tests}"
          @logger.debug "All tests passed!"
        end
      else
        puts "No lab found at #{@lab_path}"
        @logger.fatal "No lab found at #{@lab_path}. Exiting."

        # puts you are not in a lab in white and red background
        puts "#{"You are not in a lab.".colorize(:white).colorize(:background => :red)}\n"
        puts "You will not be able to use revpro test, save or submit unless you open a lab."
        puts "\nUse the following command to start working on a lab:\nrevpro open <Lab Name>\n\nExample:\n#{"revpro open Start"}\n\n"
      end

      @logger.info "Running test command... Done."
    end

    def report_start(path)
      @logger.info "Reporting start command..."

      origin_remote = @repo.remotes.detect { |r| r.name == "origin" }
      reporter = ::Revpro::CLI::Reporter.
        new(
        event_name: "start",
        event_data: {
          lab_name: origin_remote.url.split("/")[-1].gsub(".git", ""),
          lab_path: File.expand_path(path),
          previous_lab: manifest["start_lab"],
          current_lab: manifest["start_lab"],
          origin_remote: origin_remote.url,
          repo_clone_folder: path,
          github_username: origin_remote.url.split("/")[-2],
          git_name: @repo.config["user.name"],
          git_email: @repo.config["user.email"],
          gitpod: metadata[:gitpod],
          branch_name: @repo.current_branch,
          branch_url: "#{origin_remote.url}/tree/#{@repo.current_branch}",
          progress: metadata[:progress],
          progress_test: metadata[:progress_test],
          version: @version,
        },
        event_object: self,
      )

      @logger.info "Reporting start command... Done."
    end

    def report_open(path)
      @logger.info "Reporting open command..."

      origin_remote = @repo.remotes.detect { |r| r.name == "origin" }
      reporter = ::Revpro::CLI::Reporter.
        new(
        event_name: "open",
        event_data: {
          lab_name: @lab_name,
          lab_path: @lab_path,
          branch_name: @repo.current_branch,
          branch_url: "#{@repo.remote.url}/tree/#{@repo.current_branch}",
          repo_path: @monorepo_root_path,
          origin_remote: origin_remote.url,
          repo_clone_folder: @lab_path,
          gitpod: metadata[:gitpod],
          progress: metadata[:progress],
          progress_test: metadata[:progress_test],
          version: @version,
        },
        event_object: self,
      )

      @logger.info "Reporting open command... Done."
    end

    def report_test(path)
      @logger.info "Reporting test command..."

      origin_remote = @repo.remotes.detect { |r| r.name == "origin" }
      reporter = ::Revpro::CLI::Reporter.
        new(
        event_name: "test",
        event_data: {
          lab_name: @lab_name,
          lab_path: @lab_path,
          branch_name: @repo.current_branch,
          branch_url: "#{@repo.remote.url}/tree/#{@repo.current_branch}",
          repo_path: @monorepo_root_path,
          origin_remote: origin_remote.url,
          repo_clone_folder: @lab_path,
          gitpod: metadata[:gitpod],
          progress: metadata[:progress],
          progress_test: metadata[:progress_test],
          version: @version,
        },
        event_object: self,
      )

      @logger.info "Reporting test command... Done."
    end

    def report_save(path)
      @logger.info "Reporting save command..."

      origin_remote = @repo.remotes.detect { |r| r.name == "origin" }
      reporter = ::Revpro::CLI::Reporter.
        new(
        event_name: "save",
        event_data: {
          lab_name: @lab_name,
          lab_path: @lab_path,
          branch_name: @repo.current_branch,
          branch_url: "#{@repo.remote.url}/tree/#{@repo.current_branch}",
          repo_path: @monorepo_root_path,
          origin_remote: origin_remote.url,
          repo_clone_folder: @lab_path,
          gitpod: metadata[:gitpod],
          progress: metadata[:progress],
          progress_test: metadata[:progress_test],
          version: @version,
        },
        event_object: self,
      )

      @logger.info "Reporting save command... Done."
    end

    def report_submit(path)
      @logger.info "Reporting submit command..."

      origin_remote = @repo.remotes.detect { |r| r.name == "origin" }
      reporter = ::Revpro::CLI::Reporter.
        new(
        event_name: "submit",
        event_data: {
          lab_name: @lab_name,
          lab_path: @lab_path,
          previous_lab: metadata[:previous_lab],
          current_lab: metadata[:current_lab],
          branch_name: repo.current_branch,
          branch_url: "#{repo.remote.url}/tree/#{repo.current_branch}",
          repo_path: @monorepo_root_path,
          origin_remote: origin_remote.url,
          repo_clone_folder: @lab_path,
          gitpod: metadata[:gitpod],
          progress: metadata[:progress],
          progress_test: metadata[:progress_test],
          version: @version,
        }, event_object: self,
      )

      @logger.info "Reporting submit command... Done."
    end

    # def lab_names
    #   @manifest[:labs].each do |lab|
    #     puts lab.keys[0]
    #   end
    # end
  end
end

# "GITPOD_CODE_HOST"=>"https://gitpod.io",
# "GITPOD_GIT_USER_EMAIL"=>"avi@flombaum.com",
# "GITPOD_GIT_USER_NAME"=>"Avi Flombaum",
# "GITPOD_HOST"=>"https://gitpod.io",
# "GITPOD_IDE_ALIAS"=>"code",
# "GITPOD_INSTANCE_ID"=>"cc15342c-630c-4df7-b86b-148e8b16b7bd",
# "GITPOD_INTERVAL"=>"30000",
# "GITPOD_MEMORY"=>"3489",
# "GITPOD_OWNER_ID"=>"3aa1b171-666a-4c21-bca4-55957f3cf382",
# "GITPOD_PREVENT_METADATA_ACCESS"=>"true",
# "GITPOD_REPO_ROOT"=>"/workspace/pep-labs-pep1",
# "GITPOD_REPO_ROOTS"=>"/workspace/pep-labs-pep1",
# "GITPOD_THEIA_PORT"=>"23000",
# "GITPOD_WORKSPACE_CLASS"=>"default",
# "GITPOD_WORKSPACE_CLASS_INFO"=>
#  "{\"id\":\"default\",\"category\":\"GENERAL PURPOSE\",\"displayName\":\"Standard (old)\",\"description\":\"Up to 6 vCPU, 12GB memory, 30GB disk\",\"powerups\":1,\"isDefault\":false,\"deprecated\":true}",
# "GITPOD_WORKSPACE_CLUSTER_HOST"=>"ws-us75.gitpod.io",
# "GITPOD_WORKSPACE_CONTEXT"=>
#  "{\"isFile\":false,\"path\":\"\",\"title\":\"aviflombaum/pep-labs-pep1 - main\",\"ref\":\"main\",\"refType\":\"branch\",\"revision\":\"f7a55cebbbd49c7d0b6972d71098094e89ebc807\",\"repository\":{\"cloneUrl\":\"https://github.com/aviflombaum/pep-labs-pep1.git\",\"host\":\"github.com\",\"name\":\"pep-labs-pep1\",\"owner\":\"aviflombaum\",\"private\":true,\"fork\":{\"parent\":{\"cloneUrl\":\"https://github.com/revature-curriculum/pep-labs-pep1.git\",\"host\":\"github.com\",\"name\":\"pep-labs-pep1\",\"owner\":\"revature-curriculum\",\"private\":true}}},\"normalizedContextURL\":\"https://github.com/aviflombaum/pep-labs-pep1\",\"checkoutLocation\":\"pep-labs-pep1\",\"upstreamRemoteURI\":\"https://github.com/revature-curriculum/pep-labs-pep1.git\"}",
# "GITPOD_WORKSPACE_CONTEXT_URL"=>"https://github.com/aviflombaum/pep-labs-pep1",
# "GITPOD_WORKSPACE_ID"=>"aviflombaum-peplabspep1-8u8lw3h41nn",
# "GITPOD_WORKSPACE_URL"=>"https://aviflombaum-peplabspep1-8u8lw3h41nn.ws-us75.gitpod.io",

# debug data
# git_repo = Git.open(lab_path)
# env_gitpod_workspace_context = {"isFile":false,
#   "path":"",
#   "title":"aviflombaum/pep-labs-pep1 - main",
#   "ref":"main",
#   "refType":"branch",
#   "revision":"f7a55cebbbd49c7d0b6972d71098094e89ebc807",
#   "repository":
#    {"cloneUrl":"https://github.com/aviflombaum/pep-labs-pep1.git",
#     "host":"github.com",
#     "name":"pep-labs-pep1",
#     "owner":"aviflombaum",
#     "private":true,
#     "fork":
#      {"parent":
#        {"cloneUrl":
#          "https://github.com/revature-curriculum/pep-labs-pep1.git",
#         "host":"github.com",
#         "name":"pep-labs-pep1",
#         "owner":"revature-curriculum",
#         "private":true}}},
#   "normalizedContextURL":"https://github.com/aviflombaum/pep-labs-pep1",
#   "checkoutLocation":"pep-labs-pep1",
#   "upstreamRemoteURI":
#    "https://github.com/revature-curriculum/pep-labs-pep1.git"}.to_json

#   #  "GITPOD_WORKSPACE_ID"=>"aviflombaum-peplabspep1-8u8lw3h41nn",
#   #  "GITPOD_WORKSPACE_URL"=>"https://aviflombaum-peplabspep1-8u8lw3h41nn.ws-us75.gitpod.io",
#   #  "GITPOD_REPO_ROOT"=>"/workspace/pep-labs-pep1",
#   #  "GITPOD_GIT_USER_EMAIL"=>"avi@flombaum.com",
#   #  "GITPOD_GIT_USER_NAME"=>"Avi Flombaum",
# previous_lab: Intro_To_Java/Comparisons
# current_lab: Intro_To_Java/Comparisons
# repo_name:
# github_username:
# git_name
# git_email
# gitpod_workspace:
# origin_name:
# progress:
