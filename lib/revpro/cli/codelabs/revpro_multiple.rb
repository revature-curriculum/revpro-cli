module Revpro::CLI::Codelabs
  class RevproMultiple < Revpro::CLI::Codelab
    attr_accessor :path, :manifest_path
    attr_reader :manifest, :metadata, :lab_name, :source

    def self.clone(lab_url, lab_path)
      lab_path = File.basename(lab_url) if lab_path.empty?
      lab_url = "https://github.com/#{lab_url}" unless lab_url =~ URI::regexp || lab_url.start_with?("git@github.com")
      lab_address = Git::URL.parse(lab_url)
      git_owner_username = lab_url.split("/")[-2]
      git_repo_name = lab_url.split("/")[-1].gsub(".git", "")

      lab_url = "https://github.com#{lab_address.path}" if lab_address.scheme != "https"

      if File.exists?(lab_path)
        puts "Lab already exists at #{lab_path}, deleting."
        # self.delete_dir(lab_path)
        # puts "Cloning lab from #{lab_url} to #{lab_path}"
        # git_repo = Git::clone(lab_url, lab_path)
      else
        puts "Cloning lab from #{lab_url} to #{lab_path}"
        git_repo = Git::clone(lab_url, lab_path)
      end

      lab_path = File.expand_path(lab_path.strip)
      git_repo ||= Git.open(lab_path)

      manifest = YAML.load_file("#{lab_path}/.codelab/manifest.yml") if File.exists?("#{lab_path}/.codelab/manifest.yml")

      origin_remote = git_repo.remotes.detect { |r| r.name == "origin" }

      gitpod_workspace_context, gitpod_workspace = {}, {}
      if ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
        gitpod_workspace_context = JSON.parse(ENV["GITPOD_WORKSPACE_CONTEXT"]) # JSON.parse(env_gitpod_workspace_context)
        gitpod_workspace = { workspace_id: ENV["GITPOD_WORKSPACE_ID"], workspace_url: ENV["GITPOD_WORKSPACE_URL"], repo_root: ENV["GITPOD_REPO_ROOT"], git_user_email: ENV["GITPOD_GIT_USER_EMAIL"], git_user_name: ENV["GITPOD_GIT_USER_NAME"] }
        home_dir = "/workspace"
      else
        home_dir = ENV["HOME"]
      end

      config_path = "/#{home_dir}/.revpro/config.yml"
      FileUtils.mkdir_p("#{home_dir}/.revpro")

      if !File.exists?(config_path)
        File.open(config_path, "w") do |f|
          f.write({
            projects: {},
          }.to_yaml)
        end
      end

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
        progress_test[lab] = Hash.new

        out_num_tests_lab, err_num_tests_lab, st_num_tests_lab = Open3.capture3("find " + "#{File.expand_path(lab_path)}/#{lab}" + ' -name "*Test.java" -exec grep -E "@Test$|public @Test" {} \; | wc -l')

        progress_test[lab][:count_tests] = st_num_tests_lab.success? ? out_num_tests_lab.strip.to_i : 0
        progress_test[lab][:count_tests_passed] = 0
        progress_test[lab][:tests] = Hash.new

        out_tests_lab, err_tests_lab, st_tests_lab = Open3.capture3("find " + "#{File.expand_path(lab_path)}/#{lab}" + ' -name "*Test.java" -exec grep -E -A 4 "@Test$|public @Test" {} \; | grep -oP \'(?<=void ).*?(?=\()\'')

        if st_tests_lab.success?
          test_names = out_tests_lab.split("\n")
          test_names.each do |test_name|
            progress_test[lab][:tests][test_name] = 0
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

      File.open(metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end

      File.open(config_path, "w") do |f|
        f.write(config_data.to_yaml)
      end

      # puts "git_repo type: #{git_repo.class}"

      codelab = new(lab_path: lab_path, git_repo: git_repo)

      puts "Run:\n\nrevpro open <Lab Name>\n\nto start working on a lab.\n\nFor example:\n\nrevpro open Intro_To_Java/Start\n\nwill open the Intro_To_Java/Start lab and let you begin working on it."

      codelab.report_start(lab_path)
      codelab.cd_into_lab(lab_path)
    end

    def self.open(lab_path: nil, git_repo: nil)
      new(lab_path: lab_path, git_repo: git_repo).tap do |codelab|
        codelab.open
      end
    end

    def initialize(lab_path:, manifest_path: nil, git_repo: nil)
      # puts "Revpro::CLI::Codelab::initialize called"
      configure_revpro_email

      global_config_data = self.class.global_config_data
      puts "Global config data missing" and exit unless global_config_data

      if Dir.pwd.include?(global_config_data[:current_project]) || lab_path.include?(global_config_data[:current_project])
        @lab_name = lab_path.split("/")[-2..-1].join("/")
        @monorepo_root_path = global_config_data[:projects][global_config_data[:current_project]][:repo_path]
        @lab_path = "#{@monorepo_root_path}/#{@lab_name}"
        @manifest_path = "#{@monorepo_root_path}/.codelab/manifest.yml"
        @metadata_path = @manifest_path.gsub("manifest.yml", "#{manifest[:template]}")
        @repo = git_repo || Git.open(@monorepo_root_path)

        puts "Current Githhub username: #{global_config_data[:github_username]}"
        puts "Current Project: #{global_config_data[:current_project]}"
        puts "Current Project Path #{global_config_data[:projects][global_config_data[:current_project]][:repo_path]}"
        puts "Current Dir: #{Dir.pwd}"
        puts "Lab Name: #{@lab_name}"
        puts "Lab Path: #{@lab_path}"
      end

      if @monorepo_root_path
      else
        puts "You must run `open` command from within a lab directory."
        exit
      end
    end

    def configure_revpro_email
      if !self.class.global_config_data[:revpro_email]
        config_data = self.class.global_config_data
        puts "Please enter your Revpro email address to track your progress:"
        config_data[:revpro_email] = STDIN.gets.strip
        File.open(self.class.global_config_path, "w") do |f|
          f.write(config_data.to_yaml)
        end
      end
    end

    # `revpro open` command.
    def open
      puts "Opening #{@lab_name} in #{@monorepo_root_path}"
      save_and_commit
      checkout_lab_branch(@lab_name)
      update_manifest_current_lab(@lab_path)
      report_open(@lab_path)
      open_editor(@lab_path)
      cd_into_lab(@lab_path)
    end

    # `revpro submit` command.
    def submit
      # https://github.com/aviflombaum/pep-labs/compare/Intro_To_Java/If_Statement?expand=1
      # https://github.com/revature-curriculum/pep-labs/compare/main...aviflombaum:pep-labs:Intro_To_Java/Start?expand=1
      puts "Submitting #{@lab_name} in #{@monorepo_root_path}"

      save_and_commit

      report_submit(@lab_path)
    end

    def update_manifest_current_lab(lab_path)
      metadata[:previous_lab] = metadata[:current_lab]
      metadata[:current_lab] = lab_path.split("/")[-2..-1].join("/")
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end
    end

    # `revpro save` command.
    def save_and_commit
      repo.add(all: true, verify: false)
      repo.commit_all("Saved progress on #{@lab_name} #{Time.now}", allow_empty: true)
      repo.merge("origin/#{repo.current_branch}")
      repo.push("origin", repo.current_branch)
    end

    def show_progress
    end

    def save_progress(number_of_tests, number_of_failures, test_results)
      # Overall Progress
      # Individual Lab Progress
      # Based on Number of Tests passed
      # Progress in terms of number of tests vs number of labs

      # Get current lab
      current_lab = metadata[:current_lab]

      # Update progress_test -> current_lab -> count_tests_passed
      metadata[:progress_test][current_lab][:count_tests_passed] = number_of_tests - number_of_failures

      # Update progress_test -> current_lab -> individual test results
      test_results.each do |result|
        # p "result[0]: #{result[0]}, result[1]: #{result[1]}"
        metadata[:progress_test][current_lab][:tests][result[0]] = result[1]
      end

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

      # Update progress -> count_tests_passed
      metadata[:progress][:count_tests_passed] = num_tests_passed

      # Update progress -> count_labs_passed
      metadata[:progress][:count_labs_passed] = num_labs_passed

      # Save metadata file
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end
    end

    def checkout_lab_branch(branch_name)
      puts "Checking out lab branch #{branch_name}"
      puts "1. Checking out main from #{repo.current_branch}"
      repo.checkout("main")

      if repo.branches.local.detect { |b| b.name == branch_name }
        puts "2. Found local branch, checking out #{branch_name} from #{repo.current_branch}"
        repo.checkout(branch_name)
      else
        if repo.branches.remote.detect { |b| b.name == branch_name }
          puts "2. Found remote branch, checking out #{branch_name} from #{repo.current_branch}"
          repo.branch(branch_name).checkout
          puts "3. Setting upstream to origin/#{branch_name}"
          `git branch --set-upstream-to=origin/#{branch_name} #{branch_name}`
          puts "4. Merging from origin/#{branch_name}"
          repo.merge("origin/#{branch_name}")
          repo.push("origin", branch_name)
        else
          puts "2. Creating new branch #{branch_name} from #{repo.current_branch}"
          repo.branch(branch_name).checkout
          puts "3. Pushing new branch to origin/#{branch_name}"
          repo.push("origin", branch_name)
          puts "4. Setting upstream to origin/#{branch_name}"
          `git branch --set-upstream-to=origin/#{branch_name} #{branch_name}`
        end
      end
    end

    def open_editor(path)
      shell_command = ENV["SHELL"] || "bash"
      system("#{ENV["EDITOR"]} #{File.expand_path(path)}")
    end

    def cd_into_lab(path)
      shell_command = ENV["SHELL"] || "/usr/bin/bash"
      exec "ruby -e \"Dir.chdir('#{File.expand_path(path)}'); exec '#{shell_command}'\""
    end

    def metadata
      @metadata ||= YAML.load_file(@metadata_path)
    end

    def manifest
      @manifest ||= YAML.load_file(@manifest_path)
    end

    def repo(path = @path)
      @repo ||= Git.open(@path)
    end

    def test
      puts "Testing #{@lab_name} in #{@monorepo_root_path}"

      pom_path = "#{@lab_path}/pom.xml"

      puts "#{File.exists?(pom_path)}"

      if File.exists?(pom_path)
        test_run = system("mvn test -f #{pom_path}")
        puts "Hi!"

        # We are assuming there is only one Test file.
        possible_test_files = Dir.children("#{@lab_path}/target/surefire-reports/").filter { |file_name| file_name.end_with?(".xml") }
        surefire_results_path = "#{@lab_path}/target/surefire-reports/#{possible_test_files[0]}"

        if !File.exists?(surefire_results_path)
          puts "No SureFire results file found at #{surefire_results_path}"
          return
        end

        surefire_results_file = File.open(surefire_results_path)
        parsed_results = Nokogiri::XML(surefire_results_file)
        number_of_tests = parsed_results.xpath("//testsuite")[0]["tests"].to_i
        number_of_failures = parsed_results.xpath("//testsuite")[0]["failures"].to_i
        parsed_testcases = parsed_results.xpath("//testcase")
        test_results = Hash.new
        parsed_testcases.each do |test|
          # p test
          # p test.xpath("child::failure")
          test_results[test["name"]] = test.xpath("child::failure").empty? ? 1 : 0
        end

        save_progress(number_of_tests, number_of_failures, test_results)
        report_test(@lab_path)
      else
        puts "No lab found at #{@lab_path}"
      end
    end

    def report_start(path)
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
        },
        event_object: self,
      )
    end

    def report_open(path)
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
        },
        event_object: self,
      )
    end

    def report_test(path)
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
        },
        event_object: self,
      )
    end

    def report_save(path)
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
        },
        event_object: self,
      )
    end

    def report_submit(path)
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
        }, event_object: self,
      )
    end
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
