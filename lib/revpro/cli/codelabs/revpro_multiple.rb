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

      origin_remote = git_repo.remotes.detect{|r| r.name == "origin"}

      gitpod_workspace_context, gitpod_worksace = {}, {}                    
      if  ENV["GITPOD_WORKSPACE_CONTEXT"] # env_gitpod_workspace_context
        gitpod_workspace_context = JSON.parse(ENV["GITPOD_WORKSPACE_CONTEXT"]) # JSON.parse(env_gitpod_workspace_context)
        gitpod_workspace = {workspace_id: ENV["GITPOD_WORKSPACE_ID"], workspace_url: ENV["GITPOD_WORKSPACE_URL"], repo_root: ENV["GITPOD_REPO_ROOT"], git_user_email: ENV["GITPOD_GIT_USER_EMAIL"], git_user_name: ENV["GITPOD_GIT_USER_NAME"]}
        home_dir = "/workspace"                
      else
        home_dir = ENV["HOME"]
      end

      config_path = "/#{home_dir}/.revpro/config.yml"
      FileUtils.mkdir_p("#{home_dir}/.revpro")
      
      if !File.exists?(config_path)
        File.open(config_path, "w") do |f|
          f.write({
            projects: {}    
          }.to_yaml)
        end
      end

      config_data = {      
        github_username: git_owner_username,
        git_name: git_repo.config["user.name"],
        git_email: git_repo.config["user.email"],
        gitpod: {gitpod_workspace_context:, gitpod_workspace:},
        projects: {}
      }.merge(YAML.load_file(config_path))

      config_data[:projects][git_repo_name] = {
        repo_path: File.expand_path(lab_path),
        origin_remote: origin_remote.url,
        repo_clone_folder: lab_path
      }
      config_data[:current_project] = git_repo_name        

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
        gitpod: {gitpod_workspace_context:, gitpod_workspace:},
        progress: {}
      }

      File.open(metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end
      
      File.open(config_path, "w") do |f|
        f.write(config_data.to_yaml)
      end      
    end

    def self.open(lab_path: nil, git_repo: nil)
      new(lab_path: lab_path, git_repo: git_repo).tap do |codelab|
        codelab.open        
      end
    end

    def initialize(lab_path:, manifest_path: nil, git_repo: nil)   
      global_config_data = self.class.global_config_data
      puts "Global config data missing" and exit unless global_config_data

      if Dir.pwd.include?(global_config_data[:current_project]) || lab_path.include?(global_config_data[:current_project])
        @lab_name = lab_path.split("/")[-2..-1].join("/")
        @monorepo_root_path = global_config_data[:projects][global_config_data[:current_project]][:repo_path]        
        @lab_path = "#{@monorepo_root_path}/#{@lab_name}"
        @manifest_path = "#{@monorepo_root_path}/.codelab/manifest.yml"
        @metadata_path = @manifest_path.gsub("manifest.yml", "#{manifest[:template]}")   
        @repo = git_repo || Git.open(@monorepo_root_path)                              
        
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
    
    def open
      puts "Opening #{@lab_name} in #{@monorepo_root_path}"
      save_and_commit 
      checkout_lab_branch(@lab_name)
      update_manifest_current_lab(@lab_path)
      open_editor(@lab_path)
      cd_into_lab(@lab_path)
    end

    def submit
      # https://github.com/aviflombaum/pep-labs/compare/Intro_To_Java/If_Statement?expand=1
      # https://github.com/revature-curriculum/pep-labs/compare/main...aviflombaum:pep-labs:Intro_To_Java/Start?expand=1
    end

    def update_manifest_current_lab(lab_path)
      metadata["previous_lab"] = metadata["current_lab"]
      metadata["current_lab"] = lab_path
      File.open(@metadata_path, "w") do |f|
        f.write(metadata.to_yaml)
      end
    end

    def save_and_commit      
      repo.add(all: true, verify: false)
      repo.commit_all("Saved progress on #{@lab_name} #{Time.now}", allow_empty: true)
      repo.merge("origin/#{repo.current_branch}")
      repo.push("origin", repo.current_branch)
    end    

    def checkout_lab_branch(branch_name)
      puts "Checking out lab branch #{branch_name}"
      puts "1. Checking out main from #{repo.current_branch}"
      repo.checkout("main")

      if repo.branches.local.detect{|b| b.name == branch_name}                    
        puts "2. Found local branch, checking out #{branch_name} from #{repo.current_branch}"
        repo.checkout(branch_name)
      else
        if repo.branches.remote.detect{|b| b.name == branch_name}
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